import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  static SupabaseClient get _db => Supabase.instance.client;

  // ===========================================================================
  // AUTH DE BASE
  // ===========================================================================
  static User? get currentUser => _db.auth.currentUser;
  static bool get isLoggedIn => currentUser != null;
  static String? get currentEmail => currentUser?.email;

  // ===========================================================================
  // LOGIN EMAIL + PASSWORD
  // ===========================================================================
  static Future<AuthResponse> loginWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final res = await _db.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );

      // Enregistrer la session
      try {
        await _db.from('admin_sessions').insert({
          'user_id': res.user?.id,
          'email': email.trim(),
          'login_at': DateTime.now().toIso8601String(),
          'statut': 'active',
        });
        await _db.from('admin_profiles').upsert({
          'id': res.user?.id,
          'email': email.trim(),
          'derniere_connexion': DateTime.now().toIso8601String(),
        });
      } catch (_) {}

      return res;
    } on AuthException catch (e) {
      throw Exception('Email ou mot de passe incorrect');
    }
  }

  // ===========================================================================
  // LOGOUT
  // ===========================================================================
  static Future<void> logout() async {
    try {
      final user = currentUser;
      if (user != null) {
        await _db
            .from('admin_sessions')
            .update({
              'logout_at': DateTime.now().toIso8601String(),
              'statut': 'closed',
            })
            .eq('user_id', user.id)
            .eq('statut', 'active');
      }
    } catch (_) {}
    await _db.auth.signOut();
  }

  // ===========================================================================
  // VÉRIFIER SUPERADMIN
  // ===========================================================================
  static Future<bool> isSuperAdmin() async {
    try {
      final user = currentUser;
      if (user == null) return false;

      final res = await _db
          .from('admin_profiles')
          .select('role, actif')
          .eq('id', user.id)
          .maybeSingle();

      if (res == null) return false;
      return res['role'] == 'superadmin' && res['actif'] == true;
    } catch (_) {
      return false;
    }
  }

  // ===========================================================================
  // RÉCUPÉRER PROFIL ADMIN
  // ===========================================================================
  static Future<Map<String, dynamic>?> getAdminProfile() async {
    try {
      final user = currentUser;
      if (user == null) return null;

      return await _db
          .from('admin_profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();
    } catch (_) {
      return null;
    }
  }

  // ===========================================================================
  // STREAM D'AUTH (pour écouter les changements)
  // ===========================================================================
  static Stream<AuthState> get authStateChanges => _db.auth.onAuthStateChange;
}
