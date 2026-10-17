import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CoopService {
  static SupabaseClient get _db => Supabase.instance.client;

  // ===========================================================================
  // UTILISATEUR CONNECTÉ (Supabase auth OU SharedPreferences)
  // ===========================================================================
  static Future<String?> getCurrentUserId() async {
    final supabaseUser = _db.auth.currentUser;
    if (supabaseUser != null) return supabaseUser.id;

    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_id');
  }

  // ===========================================================================
  // VÉRIFIER SI L'UTILISATEUR EST CERTIFIÉ NEUROCITOYEN (étapes 1, 2, 3)
  // ===========================================================================
  static Future<bool> isNeurocitoyenCertifie(String userId) async {
    try {
      final res = await _db
          .from('user_progress')
          .select('etape_numero, statut')
          .eq('user_id', userId)
          .inFilter('etape_numero', [1, 2, 3]);

      if (res.length < 3) return false;

      const statutsValides = ['termine', 'certifie', 'valide'];
      for (final row in res) {
        final s = row['statut'] as String?;
        if (s == null || !statutsValides.contains(s)) return false;
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  // ===========================================================================
  // VÉRIFIER SI L'UTILISATEUR A VALIDÉ L'EEC (12 modules, note >= 85%)
  // ===========================================================================
  static Future<Map<String, dynamic>> verifierEEC(String userId) async {
    try {
      // 1. Récupérer les 12 modules de la formation EEC
      final modulesEec = await _db
          .from('formation_modules')
          .select('module_id, note_minimum, ordre')
          .eq('formation_id', '11111111-1111-1111-1111-111111111111')
          .order('ordre');

      if (modulesEec.isEmpty) {
        return {'ok': false, 'valides': 0, 'total': 0, 'modules': []};
      }

      final moduleIds = modulesEec.map((m) => m['module_id'] as String).toList();
      final notesMin = <String, int>{};
      for (final m in modulesEec) {
        notesMin[m['module_id'] as String] = (m['note_minimum'] as int?) ?? 85;
      }

      // 2. Récupérer la progression de l'utilisateur
      final prog = await _db
          .from('user_formation_progress')
          .select('module_id, statut, score_obtenu')
          .eq('user_id', userId)
          .inFilter('module_id', moduleIds);

      // 3. Compter les modules valides
      int valides = 0;
      final details = <Map<String, dynamic>>[];
      for (final m in modulesEec) {
        final moduleId = m['module_id'] as String;
        final noteMin = (m['note_minimum'] as int?) ?? 85;
        final p = prog.firstWhere(
          (x) => x['module_id'] == moduleId,
          orElse: () => <String, dynamic>{},
        );
        final statut = p['statut'] as String?;
        final score = p['score_obtenu'] as int?;
        final ok = statut == 'termine' && score != null && score >= noteMin;
        if (ok) valides++;
        details.add({
          'module_id': moduleId,
          'note_minimum': noteMin,
          'score': score,
          'statut': statut,
          'valide': ok,
        });
      }

      return {
        'ok': valides == modulesEec.length,
        'valides': valides,
        'total': modulesEec.length,
        'modules': details,
      };
    } catch (_) {
      return {'ok': false, 'valides': 0, 'total': 0, 'modules': []};
    }
  }

  // ===========================================================================
  // VÉRIFIER SI L'UTILISATEUR EST CERTIFIÉ (Neurocitoyen + EEC)
  // ===========================================================================
  static Future<bool> isCertifie(String userId) async {
    final neuro = await isNeurocitoyenCertifie(userId);
    if (!neuro) return false;
    final eec = await verifierEEC(userId);
    return eec['ok'] == true;
  }

  // ===========================================================================
  // STATUT COMPLET DE CERTIFICATION (pour l'UI)
  // ===========================================================================
  static Future<Map<String, dynamic>> getStatutCertification(String userId) async {
    final neuro = await isNeurocitoyenCertifie(userId);
    final eec = await verifierEEC(userId);
    return {
      'neurocitoyen': neuro,
      'eec': eec['ok'],
      'eec_valides': eec['valides'],
      'eec_total': eec['total'],
      'certifie': neuro && (eec['ok'] == true),
    };
  }

  // ===========================================================================
  // LISTER MES COOPÉRATIVES (où je suis membre)
  // ===========================================================================
  static Future<List<Map<String, dynamic>>> mesCooperatives(String userId) async {
    try {
      final res = await _db
          .from('cooperative_membres')
          .select('*, cooperatives(*)')
          .eq('user_id', userId)
          .eq('statut', 'actif');
      return List<Map<String, dynamic>>.from(res);
    } catch (_) {
      return [];
    }
  }

  // ===========================================================================
  // LISTER LES PROJETS OUVERTS DANS UNE UNITÉ TERRITORIALE
  // ===========================================================================
  static Future<List<Map<String, dynamic>>> projetsOuverts(
      String uniteTerritorialeId) async {
    try {
      final res = await _db
          .from('cooperatives')
          .select()
          .eq('unite_territoriale_id', uniteTerritorialeId)
          .eq('niveau', 1)
          .inFilter('statut', ['projet', 'comite'])
          .eq('actif', true)
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(res);
    } catch (_) {
      return [];
    }
  }

  // ===========================================================================
  // LIRE UNE COOPÉRATIVE + SES MEMBRES
  // ===========================================================================
  static Future<Map<String, dynamic>?> lireCooperative(String coopId) async {
    try {
      return await _db.from('cooperatives').select().eq('id', coopId).maybeSingle();
    } catch (_) {
      return null;
    }
  }

  static Future<List<Map<String, dynamic>>> membresCooperative(
      String coopId) async {
    try {
      final res = await _db
          .from('cooperative_membres')
          .select('*, users(id, pseudo, nom, prenoms)')
          .eq('cooperative_id', coopId)
          .eq('statut', 'actif')
          .order('date_adhesion');
      return List<Map<String, dynamic>>.from(res);
    } catch (_) {
      return [];
    }
  }

  // ===========================================================================
  // CRÉER UN PROJET DE COOPÉRATIVE (fondateur initiateur)
  // ===========================================================================
  static Future<Map<String, dynamic>> creerProjet({
    required String nom,
    required String uniteTerritorialeId,
    required String paysCode,
    String? description,
  }) async {
    final userId = await getCurrentUserId();
    if (userId == null) throw Exception('Non connecté');

    if (!await isCertifie(userId)) {
      throw Exception('Tu dois être certifié Neurocitoyen (étape 7 validée)');
    }

    // Générer un code unique
    final code = 'COOP-${DateTime.now().millisecondsSinceEpoch}';

    // 1. Créer la coopérative en statut "projet"
    final coop = await _db.from('cooperatives').insert({
      'code': code,
      'nom': nom,
      'niveau': 1,
      'unite_territoriale_id': uniteTerritorialeId,
      'pays_code': paysCode,
      'statut': 'projet',
      'date_creation': DateTime.now().toIso8601String().substring(0, 10),
      'nombre_membres': 1,
      'part_sociale_fcfa': 5000,
      'metadata': {
        'description': description ?? '',
        'date_limite_recrutement': DateTime.now()
            .add(const Duration(days: 30))
            .toIso8601String(),
      },
      'actif': true,
    }).select().single();

    final coopId = coop['id'] as String;

    // 2. Ajouter le fondateur initiateur
    await _db.from('cooperative_membres').insert({
      'cooperative_id': coopId,
      'user_id': userId,
      'role': 'fondateur_initiateur',
      'parts_sociales_souscrites': 1,
      'parts_sociales_payees': 0,
      'statut': 'actif',
    });

    // 3. Créer les 7 étapes de création
    final etapes = [
      'Constitution du groupe fondateur (5 membres)',
      'Rédaction des statuts',
      'Assemblée constitutive',
      'Élection du conseil d''administration',
      'Élection du comité de surveillance',
      'Inscription des premiers clients sur AGORA',
      'Démarrage de l''activité commerciale',
    ];
    for (var i = 0; i < etapes.length; i++) {
      await _db.from('coop_etapes_creation').insert({
        'cooperative_id': coopId,
        'etape': i + 1,
        'nom': etapes[i],
        'statut': i == 0 ? 'en_cours' : 'non_commence',
      });
    }

    return coop;
  }

  // ===========================================================================
  // REJOINDRE UN PROJET
  // ===========================================================================
  static Future<void> rejoindreProjet(String coopId) async {
    final userId = await getCurrentUserId();
    if (userId == null) throw Exception('Non connecté');

    if (!await isCertifie(userId)) {
      throw Exception('Tu dois être certifié Neurocitoyen (étape 7 validée)');
    }

    // Vérifier qu'on n'est pas déjà membre
    final existing = await _db
        .from('cooperative_membres')
        .select('id')
        .eq('cooperative_id', coopId)
        .eq('user_id', userId)
        .maybeSingle();

    if (existing != null) throw Exception('Tu es déjà membre de cette coopérative');

    // Ajouter le membre
    await _db.from('cooperative_membres').insert({
      'cooperative_id': coopId,
      'user_id': userId,
      'role': 'fondateur',
      'parts_sociales_souscrites': 1,
      'parts_sociales_payees': 0,
      'statut': 'actif',
    });

    // Recompter les membres
    final count = await _db
        .from('cooperative_membres')
        .select('id')
        .eq('cooperative_id', coopId)
        .eq('statut', 'actif');

    final nbMembres = (count as List).length;

    // Mettre à jour le compteur et le statut
    await _db.from('cooperatives').update({
      'nombre_membres': nbMembres,
      'statut': nbMembres >= 5 ? 'comite' : 'projet',
      'modifie_le': DateTime.now().toIso8601String(),
    }).eq('id', coopId);

    // Marquer l'étape 1 comme terminée si 5 membres
    if (nbMembres >= 5) {
      await _db
          .from('coop_etapes_creation')
          .update({
            'statut': 'termine',
            'date_fin': DateTime.now().toIso8601String().substring(0, 10),
          })
          .eq('cooperative_id', coopId)
          .eq('etape', 1);

      await _db
          .from('coop_etapes_creation')
          .update({'statut': 'en_cours'})
          .eq('cooperative_id', coopId)
          .eq('etape', 2);
    }
  }

  // ===========================================================================
  // QUITTER UN PROJET (avant les 5 membres)
  // ===========================================================================
  static Future<void> quitterProjet(String coopId) async {
    final userId = await getCurrentUserId();
    if (userId == null) throw Exception('Non connecté');

    await _db
        .from('cooperative_membres')
        .delete()
        .eq('cooperative_id', coopId)
        .eq('user_id', userId);

    // Recompter
    final count = await _db
        .from('cooperative_membres')
        .select('id')
        .eq('cooperative_id', coopId)
        .eq('statut', 'actif');

    final nbMembres = (count as List).length;

    if (nbMembres == 0) {
      // Plus personne : on archive
      await _db
          .from('cooperatives')
          .update({'actif': false, 'statut': 'archive'}).eq('id', coopId);
    } else {
      await _db.from('cooperatives').update({
        'nombre_membres': nbMembres,
        'statut': nbMembres >= 5 ? 'comite' : 'projet',
      }).eq('id', coopId);
    }
  }

  // ===========================================================================
  // UNITÉS TERRITORIALES (cascade)
  // ===========================================================================
  static Future<List<Map<String, dynamic>>> unitesParNiveau(int niveau) async {
    try {
      final res = await _db
          .from('unites_territoriales')
          .select()
          .eq('pays_code', 'BJ')
          .eq('niveau', niveau)
          .eq('actif', true)
          .order('nom');
      return List<Map<String, dynamic>>.from(res);
    } catch (_) {
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> unitesEnfants(
      String parentId) async {
    try {
      final res = await _db
          .from('unites_territoriales')
          .select()
          .eq('parent_id', parentId)
          .eq('actif', true)
          .order('nom');
      return List<Map<String, dynamic>>.from(res);
    } catch (_) {
      return [];
    }
  }

  // ===========================================================================
  // CRÉER UN QUARTIER À LA VOLÉE (niveau 1, inactif par défaut)
  // ===========================================================================
  static Future<String> creerQuartierALaVolee({
    required String nom,
    required String arrondissementId,
  }) async {
    final code = 'BJ-Q-${DateTime.now().millisecondsSinceEpoch}';

    final res = await _db.from('unites_territoriales').insert({
      'pays_code': 'BJ',
      'niveau': 1,
      'parent_id': arrondissementId,
      'nom': nom,
      'code': code,
      'actif': false,
    }).select().single();

    return res['id'] as String;
  }
}
