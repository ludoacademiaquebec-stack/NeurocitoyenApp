// deno-lint-ignore-file no-explicit-any
// supabase/functions/ia-chat/index.ts  (v2, alignée sur le schéma réel)
// Une seule fonction pour les 3 IA : GUIDE, ECOLE (cursus_modules), FORMATION (formations_modules)
//
// Déploiement : voir les commandes dans la réponse (CLI) ou colle ce fichier dans
// Dashboard > Edge Functions > ia-chat.
// Secrets : ANTHROPIC_API_KEY (obligatoire), IA_MODEL (optionnel)

import { createClient, SupabaseClient } from "npm:@supabase/supabase-js@2";

// ---------- Configuration ----------
const MODEL = Deno.env.get("IA_MODEL") ?? "claude-sonnet-5-5";
const MAX_OUTPUT_TOKENS = 2000;
const MAX_MESSAGE_CHARS = 4000;
const HISTORY_LIMIT = 30;
const BASE_DOC_MAX_CHARS = 60000;
const BASE_DOC_TTL_MS = 5 * 60 * 1000;
const LLM_TIMEOUT_MS = 90_000;
const SEUIL_DEFAUT = 70;
const UUID_RE = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

const CORS = {
  "Access-Control-Allow-Origin": "*", // restreins à ton domaine en production
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

type IaType = "GUIDE" | "ECOLE" | "FORMATION";
type Msg = { role: "user" | "assistant"; content: string };
type SystemBlock = { type: "text"; text: string; cache_control?: { type: "ephemeral" } };

const TAGS = ["RESULTAT", "DEMANDE_NON_TROUVEE", "NOTE_ADMIN"] as const;

const json = (body: unknown, status = 200) =>
  new Response(JSON.stringify(body), {
    status,
    headers: { ...CORS, "Content-Type": "application/json" },
  });

// ---------- Utilitaires ----------
function normalizeIaType(v: unknown): IaType | null {
  const t = String(v ?? "").toUpperCase();
  if (t === "GUIDE") return "GUIDE";
  if (["ECOLE", "ECOLES"].includes(t)) return "ECOLE";
  if (["FORMATION", "FORMATIONS", "FORMATIONS_LIBRES", "LIBRE"].includes(t)) return "FORMATION";
  return null;
}

const toText = (v: unknown): string =>
  v == null ? "" : typeof v === "string" ? v : JSON.stringify(v, null, 2);

function safeJson(raw: string): Record<string, unknown> | null {
  try {
    const j = JSON.parse(raw);
    return j && typeof j === "object" ? j : null;
  } catch {
    return null;
  }
}

function extractBlocks(text: string, tag: string): string[] {
  const re = new RegExp("\\[" + tag + "\\]([\\s\\S]*?)\\[\\/" + tag + "\\]", "g");
  return [...text.matchAll(re)].map((m) => m[1].trim());
}

// Retire toutes les balises techniques, même mal fermées
function stripTechnical(text: string): string {
  let out = text;
  for (const tag of TAGS) {
    out = out.replace(new RegExp("\\[" + tag + "\\][\\s\\S]*?\\[\\/" + tag + "\\]", "g"), "");
    out = out.replace(new RegExp("\\[" + tag + "\\][\\s\\S]*$"), ""); // balise jamais fermée
    out = out.replace(new RegExp("\\[\\/" + tag + "\\]", "g"), "");
  }
  return out.replace(/\n{3,}/g, "\n\n").trim();
}

function parseResultat(blocks: string[]) {
  for (const raw of [...blocks].reverse()) {
    const j = safeJson(raw);
    if (!j) continue;
    const score = Number(j.score);
    const total = Number(j.total);
    if (!Number.isInteger(score) || !Number.isInteger(total)) continue;
    if (total < 1 || total > 20 || score < 0 || score > total) continue;
    return {
      score,
      total,
      pourcentage: Math.round((score / total) * 100),
      langue: typeof j.langue === "string" ? j.langue.slice(0, 20) : "",
      a_revoir: Array.isArray(j.a_revoir) ? j.a_revoir.map(String).slice(0, 10) : [],
    };
  }
  return null;
}

// ---------- Chargement des données ----------
let baseDocCache: { value: string; at: number } | null = null;

async function loadBaseDoc(supabase: SupabaseClient): Promise<string> {
  if (baseDocCache && Date.now() - baseDocCache.at < BASE_DOC_TTL_MS) return baseDocCache.value;
  const { data, error } = await supabase.from("v_base_connaissance_ia").select("*");
  if (error || !data) {
    console.error("v_base_connaissance_ia:", error?.message);
    return baseDocCache?.value ?? "";
  }
  let txt = data.map((r) => (typeof r === "string" ? r : JSON.stringify(r))).join("\n");
  if (txt.length > BASE_DOC_MAX_CHARS) {
    console.warn(`Base documentaire tronquée (${txt.length} > ${BASE_DOC_MAX_CHARS} caractères)`);
    txt = txt.slice(0, BASE_DOC_MAX_CHARS);
  }
  baseDocCache = { value: txt, at: Date.now() };
  return txt;
}

async function loadProgression(supabase: SupabaseClient, userId: string): Promise<string> {
  try {
    const [c, f] = await Promise.all([
      supabase.from("user_cursus_progress")
        .select("cursus_id, module_id, statut, progression, score_obtenu")
        .eq("user_id", userId).limit(50),
      supabase.from("user_formation_progress")
        .select("formation_id, module_id, statut, progression, score_obtenu")
        .eq("user_id", userId).limit(50),
    ]);
    const cursus = c.data ?? [];
    const formations = f.data ?? [];
    if (!cursus.length && !formations.length) return "";
    return JSON.stringify({ cursus, formations });
  } catch (e) {
    console.warn("progression:", e);
    return "";
  }
}

async function loadProfil(supabase: SupabaseClient, userId: string) {
  const { data } = await supabase
    .from("users").select("pseudo, pays_id, grade, langue_app").eq("id", userId).maybeSingle();
  return data as { pseudo?: string; pays_id?: string; grade?: string; langue_app?: string } | null;
}

// Ressources et évaluations (banque de QCM) du module
async function loadModuleExtras(supabase: SupabaseClient, iaType: IaType, moduleId: string) {
  const ecole = iaType === "ECOLE";
  const [res, ev] = await Promise.all([
    supabase.from(ecole ? "cursus_ressources" : "formations_ressources")
      .select("type, titre, description, url").eq("module_id", moduleId).eq("actif", true).order("ordre"),
    supabase.from(ecole ? "cursus_evaluations" : "formations_evaluations")
      .select("titre, questions, seuil_reussite").eq("module_id", moduleId).eq("actif", true).order("ordre"),
  ]);
  if (res.error) console.warn("ressources:", res.error.message);
  if (ev.error) console.warn("evaluations:", ev.error.message);
  return { ressources: (res.data ?? []) as any[], evaluations: (ev.data ?? []) as any[] };
}

function buildContenuModule(row: any, ressources: any[]): string {
  const parts: string[] = [];
  parts.push(`TITRE : ${row.titre}`);
  if (row.sous_titre) parts.push(`SOUS-TITRE : ${row.sous_titre}`);
  if (row.description) parts.push(`DESCRIPTION : ${row.description}`);
  if (row.duree_heures) parts.push(`DURÉE : ${row.duree_heures} h`);
  const objectifs = row.ia_objectifs ?? row.objectifs;
  if (objectifs) parts.push("OBJECTIFS :\n" + toText(objectifs));
  const contenu = row.ia_contenu_reference || row.contenu_texte;
  if (contenu) parts.push("CONTENU DE RÉFÉRENCE :\n" + toText(contenu));
  if (ressources.length) {
    parts.push(
      "RESSOURCES DU MODULE :\n" +
        ressources.map((r) =>
          `- [${r.type}] ${r.titre}${r.description ? " : " + r.description : ""}${r.url ? " (" + r.url + ")" : ""}`
        ).join("\n"),
    );
  }
  return parts.join("\n\n");
}

// Module suivant dans la même formation / le même cursus (par « ordre »)
async function loadModuleSuivant(supabase: SupabaseClient, table: string, row: any): Promise<string> {
  try {
    const parentKey = table === "cursus_modules" ? "cursus_id" : "formation_id";
    if (!row[parentKey] || typeof row.ordre !== "number") return "";
    const { data } = await supabase.from(table).select("titre")
      .eq(parentKey, row[parentKey]).eq("actif", true).gt("ordre", row.ordre)
      .order("ordre", { ascending: true }).limit(1);
    return data?.[0]?.titre ? String(data[0].titre) : "";
  } catch {
    return "";
  }
}

async function loadHistory(supabase: SupabaseClient, userId: string, moduleId: string | null, iaType: IaType) {
  let q = supabase.from("ia_conversations").select("role, contenu")
    .eq("user_id", userId).eq("module_type", iaType.toLowerCase());
  q = moduleId ? q.eq("module_id", moduleId) : q.is("module_id", null);
  const { data, error } = await q.order("created_at", { ascending: false }).limit(HISTORY_LIMIT);
  if (error) {
    console.error("historique:", error.message);
    return [];
  }
  return (data ?? []).reverse();
}

// ---------- Appel au modèle ----------
async function callLLM(system: SystemBlock[], messages: Msg[], temperature?: number): Promise<string> {
  const ctrl = new AbortController();
  const timer = setTimeout(() => ctrl.abort(), LLM_TIMEOUT_MS);
  try {
    const res = await fetch("https://api.anthropic.com/v1/messages", {
      method: "POST",
      headers: {
        "content-type": "application/json",
        "x-api-key": Deno.env.get("ANTHROPIC_API_KEY")!,
        "anthropic-version": "2023-06-01",
      },
      body: JSON.stringify({
        model: MODEL,
        max_tokens: MAX_OUTPUT_TOKENS,
        system,
        messages,
        ...(temperature !== undefined ? { temperature } : {}),
      }),
      signal: ctrl.signal,
    });
    if (!res.ok) throw new Error(`LLM ${res.status}: ${await res.text()}`);
    const data = await res.json();
    return (data.content ?? [])
      .filter((b: { type: string }) => b.type === "text")
      .map((b: { text: string }) => b.text)
      .join("")
      .trim();
  } finally {
    clearTimeout(timer);
  }
}

// ---------- Handler ----------
Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: CORS });
  if (req.method !== "POST") return json({ error: "Méthode non autorisée" }, 405);

  try {
    if (!Deno.env.get("ANTHROPIC_API_KEY")) {
      console.error("ANTHROPIC_API_KEY manquante");
      return json({ error: "Service mal configuré" }, 500);
    }

    const supabase = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
      { auth: { persistSession: false } },
    );

    // 1. Authentification : l'identité vient du JWT, jamais du corps de la requête
    const jwt = (req.headers.get("Authorization") ?? "").replace(/^Bearer\s+/i, "");
    const { data: auth, error: authErr } = await supabase.auth.getUser(jwt);
    if (authErr || !auth?.user) return json({ error: "Non authentifié" }, 401);
    const userId = auth.user.id;

    // 2. Validation de l'entrée
    let body: Record<string, unknown>;
    try {
      body = await req.json();
    } catch {
      return json({ error: "Corps JSON invalide" }, 400);
    }
    const iaType = normalizeIaType(body.ia_type);
    if (!iaType) return json({ error: "ia_type invalide (GUIDE, ECOLE ou FORMATION)" }, 400);

    const message = String(body.message ?? "").trim();
    if (!message) return json({ error: "Message vide" }, 400);
    if (message.length > MAX_MESSAGE_CHARS) {
      return json({ error: `Message trop long (max ${MAX_MESSAGE_CHARS} caractères)` }, 400);
    }

    const moduleId = iaType === "GUIDE" ? null : String(body.module_id ?? "");
    if (iaType !== "GUIDE" && (!moduleId || !UUID_RE.test(moduleId))) {
      return json({ error: "module_id (uuid) requis" }, 400);
    }

    // 3. Prompt système + contenu du module
    let template = "";
    let contenuModule = "";
    let banqueQcm = "";
    let moduleSuivant = "";
    let moduleRow: any = null;
    let ressources: any[] = [];
    let evaluations: any[] = [];

    if (iaType === "GUIDE") {
      const { data } = await supabase
        .from("config_ligue").select("valeur").eq("cle", "IA_GUIDE_PROMPT").maybeSingle();
      template = toText(data?.valeur);
    } else {
      const table = iaType === "ECOLE" ? "cursus_modules" : "formations_modules";
      const { data: row } = await supabase
        .from(table).select("*").eq("id", moduleId!).eq("actif", true).maybeSingle();
      if (!row) return json({ error: "Module introuvable ou inactif" }, 404);
      moduleRow = row;
      template = toText(row.ia_prompt_systeme);
      const extras = await loadModuleExtras(supabase, iaType, moduleId!);
      ressources = extras.ressources;
      evaluations = extras.evaluations;
      contenuModule = buildContenuModule(row, ressources);
      banqueQcm = evaluations
        .filter((e) => e.questions)
        .map((e) => `${e.titre ?? ""}\n${toText(e.questions)}`.trim())
        .join("\n\n");
      moduleSuivant = await loadModuleSuivant(supabase, table, row);
    }
    if (!template) {
      console.error(`Prompt système vide (${iaType}, module ${moduleId})`);
      return json({ error: "Prompt de l'IA introuvable" }, 500);
    }

    // Paramètres du module
    const seuil: number = Number(
      evaluations.find((e) => e.seuil_reussite != null)?.seuil_reussite ?? moduleRow?.ia_seuil ?? SEUIL_DEFAUT,
    );
    const nbQuestions = moduleRow?.ia_nb_questions ?? null;
    const t = Number(moduleRow?.ia_temperature);
    const temperature = Number.isFinite(t) && t >= 0 && t <= 1 ? t : undefined;

    // 4. Contexte : base documentaire, progression, historique, profil (en parallèle)
    const [baseDoc, progression, history, profil] = await Promise.all([
      loadBaseDoc(supabase),
      loadProgression(supabase, userId),
      loadHistory(supabase, userId, moduleId, iaType),
      loadProfil(supabase, userId),
    ]);

    // Langue : demandée par le frontend > profil de l'apprenant > langue du module
    const langue = String(body.langue ?? "").trim().slice(0, 20) ||
      profil?.langue_app || moduleRow?.ia_langue || "";

    // 5. Construction du prompt système
    // Bloc stable (mis en cache chez le fournisseur) : prompt + contenus volumineux
    const stable = [
      template,
      "=== CONTENU_MODULE ===\n" + (contenuModule || "(absent)"),
      "=== BANQUE_QCM ===\n" + (banqueQcm || "(absent)"),
      "=== BASE_DOCUMENTAIRE ===\n" + (baseDoc || "(absent)"),
    ].join("\n\n");

    // Bloc variable : valeurs des variables + profil
    const variables = [
      "# VALEURS DES VARIABLES (fournies par l'application)",
      `{{LANGUE}} = ${langue || "(absente)"}`,
      `{{ID_MODULE}} = ${moduleId ?? "guide"}`,
      `{{MODULE_SUIVANT}} = ${moduleSuivant || "(absent)"}`,
      `{{NB_QUESTIONS}} = ${nbQuestions ?? "(absent)"}`,
      `{{SEUIL_REUSSITE}} = ${iaType === "GUIDE" ? "(absent)" : seuil}`,
      `{{PROGRESSION_APPRENANT}} = ${progression || "(absente)"}`,
      "{{CONTENU_MODULE}}, {{BANQUE_QCM}}, {{BASE_DOCUMENTAIRE}} : voir les blocs du même nom plus haut.",
      "",
      "# PROFIL DE L'APPRENANT (indicatif)",
      `Pseudo : ${profil?.pseudo ?? "(inconnu)"} | Pays : ${profil?.pays_id ?? "(inconnu)"} | Grade : ${profil?.grade ?? "(inconnu)"}`,
    ].join("\n");

    const system: SystemBlock[] = [
      { type: "text", text: stable, cache_control: { type: "ephemeral" } },
      { type: "text", text: variables },
    ];

    // 6. Messages (historique + nouveau message)
    const messages: Msg[] = history
      .filter((h) => h.contenu)
      .map((h) => ({
        role: h.role === "assistant" ? "assistant" : "user",
        content: String(h.contenu),
      })) as Msg[];
    while (messages.length && messages[0].role !== "user") messages.shift();
    messages.push({ role: "user", content: message });

    // 7. Appel du modèle
    let texteBrut: string;
    try {
      texteBrut = await callLLM(system, messages, temperature);
    } catch (e) {
      console.error("Erreur LLM:", e);
      return json({ error: "L'assistant est momentanément indisponible. Réessaie dans un instant." }, 502);
    }
    if (!texteBrut) return json({ error: "Réponse vide de l'assistant" }, 502);

    // 8. Filtre : extraction des blocs techniques puis nettoyage
    const resultat = parseResultat(extractBlocks(texteBrut, "RESULTAT"));
    const demandes = extractBlocks(texteBrut, "DEMANDE_NON_TROUVEE");
    const notesAdmin = extractBlocks(texteBrut, "NOTE_ADMIN");
    const textePropre = stripTechnical(texteBrut) ||
      "Désolé, je n'ai pas pu formuler ma réponse. Peux-tu reformuler ?";

    // Anti-triche : un QCM de N questions suppose au moins N tours de l'IA dans la conversation
    const assistantTurns = history.filter((h) => h.role === "assistant").length + 1;
    const resultatValide =
      resultat && iaType !== "GUIDE" && assistantTurns >= resultat.total ? resultat : null;
    const valide = resultatValide ? resultatValide.pourcentage >= seuil : false;
    const moduleType = iaType.toLowerCase();

    // 9. Écritures en base (en arrière-plan : ne ralentit pas la réponse, n'échoue jamais)
    const sideEffects = async () => {
      const log = (label: string, error: { message: string } | null) => {
        if (error) console.error(`${label}:`, error.message);
      };

      // Conversation : message de l'apprenant puis réponse (deux insertions pour garder l'ordre)
      log("conv user", (await supabase.from("ia_conversations").insert({
        user_id: userId, module_id: moduleId, module_type: moduleType, role: "user", contenu: message,
      })).error);
      log("conv assistant", (await supabase.from("ia_conversations").insert({
        user_id: userId, module_id: moduleId, module_type: moduleType, role: "assistant", contenu: textePropre,
      })).error);

      if (resultatValide) {
        // score = pourcentage (0-100), comparable à « seuil » ; le détail brut est dans « questions »
        log("quiz", (await supabase.from("ia_quiz_tentatives").insert({
          user_id: userId,
          module_id: moduleId,
          module_type: moduleType,
          questions: { ...resultatValide, langue: resultatValide.langue || langue },
          score: resultatValide.pourcentage,
          seuil,
          valide,
          feedback_ia: textePropre.slice(0, 4000),
        })).error);
      }

      for (const raw of demandes) {
        const d = safeJson(raw);
        if (!d) continue;
        log("demande", (await supabase.from("ia_demandes_non_trouvees").insert({
          user_id: userId,
          question_originale: String(d.question ?? "").slice(0, 1000),
          ia_type: iaType,
          module_id: moduleId,
          contexte: d,
          reponse_ia: textePropre.slice(0, 4000),
        })).error);
      }

      for (const note of notesAdmin) {
        console.warn("[NOTE_ADMIN]", moduleId, note);
        log("note admin", (await supabase.from("ia_notes_admin").insert({
          user_id: userId, module_id: moduleId, ia_type: iaType, note: note.slice(0, 2000),
        })).error);
      }
    };

    const runtime = (globalThis as { EdgeRuntime?: { waitUntil(p: Promise<unknown>): void } }).EdgeRuntime;
    if (runtime?.waitUntil) runtime.waitUntil(sideEffects().catch((e) => console.error("sideEffects:", e)));
    else await sideEffects().catch((e) => console.error("sideEffects:", e));

    // 10. Réponse au frontend (aucune balise technique)
    return json({
      reponse: textePropre,
      resultat: resultatValide
        ? {
          score: resultatValide.score,
          total: resultatValide.total,
          pourcentage: resultatValide.pourcentage,
          seuil,
          valide,
        }
        : null,
    });
  } catch (e) {
    console.error("ia-chat erreur inattendue:", e);
    return json({ error: "Erreur interne" }, 500);
  }
});
