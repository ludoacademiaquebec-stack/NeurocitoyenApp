import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS"
};

async function callLLM(prompt: string): Promise<string> {
  const groqKey = Deno.env.get("GROQ_API_KEY")!;
  const model = Deno.env.get("IA_MODEL") ?? "llama-3.3-70b-versatile";
  const res = await fetch("https://api.groq.com/openai/v1/chat/completions", {
    method: "POST",
    headers: { "Content-Type": "application/json", "Authorization": `Bearer ${groqKey}` },
    body: JSON.stringify({ model, messages: [{ role: "user", content: prompt }], temperature: 0.3, max_tokens: 800 })
  });
  const data = await res.json();
  if(!res.ok) throw new Error(`Groq ${res.status}: ${JSON.stringify(data)}`);
  return data.choices[0].message.content;
}

const SYSTEM_PROMPTS: any = {
  GUIDE: "Tu es le GUIDE de LIGUEAFRICAINE. Aide familiale.",
  PROF: "Tu es PROF.",
  MEDIATEUR: "Tu es MEDIATEUR.",
  JARDINIER: "Tu es JARDINIER.",
  HISTORIEN: "Tu es HISTORIEN."
};

serve(async (req)=>{
  if(req.method === "OPTIONS"){
    return new Response("ok", { headers: corsHeaders });
  }
  try{
    const supabase = createClient(Deno.env.get("SUPABASE_URL")!, Deno.env.get("SUPABASE_ANON_KEY")!, { global: { headers: { Authorization: req.headers.get("Authorization")! } } });
    const { data: { user } } = await supabase.auth.getUser();
    if(!user) return new Response(JSON.stringify({error:"Non authentifie"}), {status:401, headers: {...corsHeaders, "Content-Type":"application/json"}});
    const body = await req.json();
    const prompt = `${SYSTEM_PROMPTS[body.ia_type] ?? SYSTEM_PROMPTS.GUIDE}\nQuestion: ${body.message}`;
    const reponse = await callLLM(prompt);
    return new Response(JSON.stringify({reponse, ia_type: body.ia_type}), {headers:{...corsHeaders, "Content-Type":"application/json"}});
  }catch(e){
    console.error("LLM Error:", e);
    return new Response(JSON.stringify({error:"IA indisponible", details: String(e)}), {status:500, headers:{...corsHeaders, "Content-Type":"application/json"}});
  }
});
