// lib/core/db.dart
import 'package:supabase_flutter/supabase_flutter.dart';

class Db {
  static SupabaseClient get client => Supabase.instance.client;

  // -------------------------------------------------------------------------
  // USERS (membres inscrits)
  // -------------------------------------------------------------------------
  static Future<void> createUser({
    required String paysCode,       // ex: 'BJ'
    required String regionCode,     // ex: 'W'
    required String email,
    String statut = 'attente',
  }) async {
    await client.from('users').insert({
      'pays': paysCode,
      'region': regionCode,
      'email': email,
      'statut': statut,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  static Future<List<Map<String, dynamic>>> listUsers() async {
    final res = await client.from('users').select().order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(res);
  }

  // -------------------------------------------------------------------------
  // CITÉS (55 pays — lecture seule, seed en SQL)
  // -------------------------------------------------------------------------
  static Future<List<Map<String, dynamic>>> listCites() async {
    final res = await client.from('cites').select().order('nom');
    return List<Map<String, dynamic>>.from(res);
  }

  static Future<List<Map<String, dynamic>>> listCitesByRegion(String region) async {
    final res = await client.from('cites').select().eq('region', region).order('nom');
    return List<Map<String, dynamic>>.from(res);
  }

  // -------------------------------------------------------------------------
  // PROPOSITIONS (dashboard / vote "une voix")
  // -------------------------------------------------------------------------
  static Future<void> createProposition({
    required String citeCode,
    required String auteurEmail,
    required String titre,
    required String contenu,
  }) async {
    await client.from('propositions').insert({
      'cite': citeCode,
      'auteur': auteurEmail,
      'titre': titre,
      'contenu': contenu,
      'votes_pour': 0,
      'votes_contre': 0,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  static Future<List<Map<String, dynamic>>> listPropositions(String citeCode) async {
    final res = await client
        .from('propositions')
        .select()
        .eq('cite', citeCode)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(res);
  }
}