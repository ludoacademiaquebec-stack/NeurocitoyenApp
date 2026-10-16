import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _C {
  static const nuit = Color(0xFF060A1F);
  static const nuit2 = Color(0xFF121845);
  static const nuit3 = Color(0xFF0B102E);
  static const or = Color(0xFFC4952B);
  static const orClair = Color(0xFFF0D9A0);
  static const rouge = Color(0xFFE53935);
}

class LoginUserScreen extends StatefulWidget {
  const LoginUserScreen({super.key});
  @override
  State<LoginUserScreen> createState() => _LoginUserScreenState();
}

class _LoginUserScreenState extends State<LoginUserScreen> {
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

    // Pour l'instant, on simule une connexion
    // TODO: brancher sur Supabase Auth
    await Future.delayed(const Duration(milliseconds: 800));

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_email', email);
    await prefs.setString('code_parrain', 'temp_${DateTime.now().millisecondsSinceEpoch}');

    if (!mounted) return;
    context.go('/dashboard');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.nuit,
      appBar: AppBar(
        backgroundColor: _C.nuit,
        title: const Text('Connexion',
            style: TextStyle(color: Colors.white, fontSize: 14)),
        iconTheme: const IconThemeData(color: _C.or),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: _C.or.withOpacity(0.15),
                    shape: BoxShape.circle,
                    border: Border.all(color: _C.or, width: 2),
                  ),
                  child: const Icon(Icons.person, color: _C.or, size: 40),
                ),
                const SizedBox(height: 20),
                const Text('Bienvenue Neurocitoyen',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontFamily: 'Georgia',
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                const Text('Connecte-toi pour accéder à ton espace',
                    style: TextStyle(color: Colors.white54, fontSize: 12)),
                const SizedBox(height: 32),

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
                          child: Text(_error!,
                              style: const TextStyle(
                                  color: _C.rouge, fontSize: 12)),
                        ),
                      ],
                    ),
                  ),

                TextField(
                  controller: _emailCtrl,
                  enabled: !_loading,
                  keyboardType: TextInputType.emailAddress,
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

                TextField(
                  controller: _pwdCtrl,
                  enabled: !_loading,
                  obscureText: _obscure,
                  onSubmitted: (_) => _login(),
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Mot de passe',
                    labelStyle: const TextStyle(color: Colors.white54),
                    prefixIcon: const Icon(Icons.lock_outline,
                        color: _C.or, size: 20),
                    suffixIcon: IconButton(
                      icon: Icon(
                          _obscure ? Icons.visibility_off : Icons.visibility,
                          color: Colors.white54,
                          size: 20),
                      onPressed: () =>
                          setState(() => _obscure = !_obscure),
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
                TextButton(
                  onPressed: () => context.go('/inscription?pays=BJ'),
                  child: const Text(
                    'Pas encore membre ? S\'inscrire →',
                    style: TextStyle(color: _C.orClair, fontSize: 12),
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => context.go('/'),
                  child: const Text(
                    '← Retour à l\'accueil',
                    style: TextStyle(color: Colors.white54, fontSize: 12),
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
