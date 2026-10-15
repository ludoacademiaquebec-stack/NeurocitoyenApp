import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth_service.dart';
import '../../widgets/app_scaffold.dart';

class _C {
  static const nuit = Color(0xFF060A1F);
  static const nuit2 = Color(0xFF121845);
  static const nuit3 = Color(0xFF0B102E);
  static const or = Color(0xFFC4952B);
  static const orClair = Color(0xFFF0D9A0);
  static const rouge = Color(0xFFE53935);
}

TextStyle _serif(double size,
    {Color color = Colors.white, FontWeight weight = FontWeight.w700}) {
  return TextStyle(
    fontFamily: 'Georgia',
    fontFamilyFallback: const ['Times New Roman', 'serif'],
    fontSize: size,
    color: color,
    fontWeight: weight,
  );
}

class LoginAdminScreen extends StatefulWidget {
  const LoginAdminScreen({super.key});
  @override
  State<LoginAdminScreen> createState() => _LoginAdminScreenState();
}

class _LoginAdminScreenState extends State<LoginAdminScreen> {
  final _emailCtrl = TextEditingController();
  final _pwdCtrl = TextEditingController();
  bool _loading = false;
  bool _obscure = true;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _pwdCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    setState(() {
      _error = null;
      _loading = true;
    });

    final email = _emailCtrl.text.trim();
    final pwd = _pwdCtrl.text;

    if (email.isEmpty || pwd.isEmpty) {
      setState(() {
        _error = 'Email et mot de passe requis';
        _loading = false;
      });
      return;
    }

    try {
      await AuthService.loginWithEmail(email: email, password: pwd);
      final isAdmin = await AuthService.isSuperAdmin();

      if (!mounted) return;

      if (isAdmin) {
        context.go('/admin-super');
      } else {
        await AuthService.logout();
        setState(() {
          _error = 'Ton compte n\'a pas les droits superadmin';
          _loading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Connexion Administration',
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              children: [
                // Icône
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: _C.or.withOpacity(0.15),
                    shape: BoxShape.circle,
                    border: Border.all(color: _C.or, width: 2),
                  ),
                  child: const Icon(Icons.admin_panel_settings,
                      color: _C.or, size: 40),
                ),
                const SizedBox(height: 20),

                // Titre
                Text('Administration',
                    style: _serif(26, color: Colors.white)),
                const SizedBox(height: 6),
                const Text(
                  'Accès réservé aux Super Admins de la Ligue',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white54, fontSize: 12),
                ),

                const SizedBox(height: 32),

                // Erreur
                if (_error != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: _C.rouge.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: _C.rouge.withOpacity(0.6)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline,
                            color: _C.rouge, size: 18),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _error!,
                            style: const TextStyle(
                                color: _C.rouge, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Email
                TextField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  enabled: !_loading,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Email',
                    labelStyle: const TextStyle(color: Colors.white54),
                    prefixIcon: const Icon(Icons.email_outlined,
                        color: _C.or, size: 20),
                    filled: true,
                    fillColor: _C.nuit3,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.white12),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.white12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: _C.or, width: 1.5),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Mot de passe
                TextField(
                  controller: _pwdCtrl,
                  obscureText: _obscure,
                  enabled: !_loading,
                  onSubmitted: (_) => _login(),
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Mot de passe',
                    labelStyle: const TextStyle(color: Colors.white54),
                    prefixIcon: const Icon(Icons.lock_outline,
                        color: _C.or, size: 20),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscure
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: Colors.white54,
                        size: 20,
                      ),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                    filled: true,
                    fillColor: _C.nuit3,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.white12),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.white12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: _C.or, width: 1.5),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Bouton
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _C.or,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30)),
                    ),
                    child: _loading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.black),
                          )
                        : const Text('SE CONNECTER',
                            style: TextStyle(
                                fontWeight: FontWeight.w900, fontSize: 13)),
                  ),
                ),

                const SizedBox(height: 16),

                // Retour accueil
                TextButton(
                  onPressed: () => context.go('/'),
                  child: const Text(
                    '← Retour à l\'accueil',
                    style: TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                ),

                const SizedBox(height: 24),

                // Note sécurité
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _C.nuit2,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.security,
                          color: _C.orClair, size: 16),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Connexion sécurisée par Supabase Auth. Toutes les actions sont enregistrées.',
                          style: TextStyle(
                              color: Colors.white54,
                              fontSize: 10,
                              height: 1.4),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
