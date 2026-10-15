// lib/core/db.dart
import 'package:supabase_flutter/supabase_flutter.dart';

class Db {
  static SupabaseClient get client => Supabase.instance.client;

  // ==========================================================================
  // USERS — Inscription
  // ==========================================================================
  static Future<Map<String, dynamic>> createUser({
    required String pseudo,
    required String nom,
    required String prenoms,
    required String email,
    required String paysId,
    required String codeCooptation,
    String? codeParrain,
    String? departement,
    String? commune,
    String? villageQuartier,
    String? profession,
    int? age,
    String? trancheAge,
    String? niveauEtude,
    String? domainePro,
    List<String>? domainesInteret,
  }) async {
    // 1. Retrouver l'ID du parrain si code fourni
    String? parrainId;
    if (codeParrain != null && codeParrain.isNotEmpty) {
      final parrainRes = await client
          .from('users')
          .select('id')
          .eq('mon_code_cooptation', codeParrain)
          .maybeSingle();
      parrainId = parrainRes?['id'] as String?;
    }

    // 2. Insérer le nouvel utilisateur
    final res = await client
        .from('users')
        .insert({
          'pseudo': pseudo,
          'nom': nom,
          'prenoms': prenoms,
          'email': email,
          'pays_id': paysId,
          'mon_code_cooptation': codeCooptation,
          if (codeParrain != null) 'code_parrain': codeParrain,
          if (parrainId != null) 'parrain_id': parrainId,
          if (departement != null) 'departement': departement,
          if (commune != null) 'commune': commune,
          if (villageQuartier != null) 'village_quartier': villageQuartier,
          if (profession != null) 'profession': profession,
          if (age != null) 'age': age,
          if (trancheAge != null) 'tranche_age': trancheAge,
          if (niveauEtude != null) 'niveau_etude': niveauEtude,
          if (domainePro != null) 'domaine_pro': domainePro,
          if (domainesInteret != null) 'domaines_interet': domainesInteret,
        })
        .select()
        .single();

    // 3. Créer la cooptation si parrain trouvé
    if (parrainId != null) {
      await client.from('cooptations').insert({
        'parrain_id': parrainId,
        'filleul_id': res['id'],
        'generation': 1,
        'pays_id': paysId,
      });
    }

    return res;
  }

  // ==========================================================================
  // USERS — Lecture
  // ==========================================================================
  static Future<Map<String, dynamic>?> getUserByCodeParrain(String code) async {
    return await client
        .from('users')
        .select()
        .eq('mon_code_cooptation', code)
        .maybeSingle();
  }

  static Future<List<Map<String, dynamic>>> listUsers() async {
    final res = await client
        .from('users')
        .select()
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(res);
  }

  // ==========================================================================
  // COUNTRIES
  // ==========================================================================
  static Future<List<Map<String, dynamic>>> listCountries() async {
    final res = await client.from('countries').select().order('nom');
    return List<Map<String, dynamic>>.from(res);
  }

  static Future<Map<String, dynamic>?> getCountry(String id) async {
    return await client
        .from('countries')
        .select()
        .eq('id', id)
        .maybeSingle();
  }

  // ==========================================================================
  // REGIONS
  // ==========================================================================
  static Future<List<Map<String, dynamic>>> listRegions() async {
    final res = await client.from('regions_afrique').select().order('code');
    return List<Map<String, dynamic>>.from(res);
  }

  // ==========================================================================
  // PROPOSITIONS
  // ==========================================================================
  static Future<List<Map<String, dynamic>>> listPropositions({
    String? paysCible,
  }) async {
    var query = client.from('propositions').select();
    if (paysCible != null) {
      query = query.eq('pays_cible', paysCible);
    }
    final res = await query.order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(res);
  }
}