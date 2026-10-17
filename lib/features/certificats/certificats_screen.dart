import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../widgets/app_scaffold.dart';

class _C {
  static const nuit = Color(0xFF0B2B2F);
  static const nuit2 = Color(0xFF0E3A3D);
  static const nuit3 = Color(0xFF071D20);
  static const or = Color(0xFFE0A82E);
  static const orClair = Color(0xFFF0BD4A);
}

TextStyle _serif(double size, {Color color = Colors.white, FontWeight weight = FontWeight.w700}) {
  return TextStyle(
    fontFamily: 'Georgia',
    fontFamilyFallback: const ['Times New Roman', 'serif'],
    fontSize: size,
    color: color,
    fontWeight: weight,
  );
}

class CertificatsScreen extends StatefulWidget {
  const CertificatsScreen({super.key});
  @override
  State<CertificatsScreen> createState() => _CertificatsScreenState();
}

class _CertificatsScreenState extends State<CertificatsScreen> {
  List<Map<String, dynamic>> _certificats = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id');
      if (userId == null) {
        setState(() => _loading = false);
        return;
      }
      final res = await Supabase.instance.client
          .from('certificats')
          .select()
          .eq('user_id', userId)
          .order('date_emission', ascending: false);
      _certificats = List<Map<String, dynamic>>.from(res);
    } catch (_) {}
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Mes Certificats',
      child: _loading
          ? const Center(child: CircularProgressIndicator(color: _C.or))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _header(),
                const SizedBox(height: 20),
                if (_certificats.isEmpty)
                  _emptyState()
                else
                  ..._certificats.map(_certificatTile),
              ],
            ),
    );
  }

  Widget _header() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_C.or, Color(0xFF8B6914)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.workspace_premium, color: Colors.black54, size: 32),
          const SizedBox(height: 10),
          Text('Mes Certificats',
              style: _serif(26, color: Colors.black, weight: FontWeight.w900)),
          const SizedBox(height: 4),
          Text(
            '${_certificats.length} certificat(s) obtenu(s)',
            style: const TextStyle(color: Colors.black87, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _emptyState() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: _C.nuit3,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: const Column(
        children: [
          Icon(Icons.workspace_premium, color: Colors.white38, size: 48),
          SizedBox(height: 12),
          Text('Aucun certificat pour l\'instant',
              style: TextStyle(color: Colors.white54, fontSize: 14)),
          SizedBox(height: 6),
          Text(
            'Commence ton parcours à l\'Université Baobab\npour obtenir ton premier certificat',
            style: TextStyle(color: Colors.white38, fontSize: 12, height: 1.5),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _certificatTile(Map<String, dynamic> c) {
    final titre = c['numero_certificat'] ?? 'Certificat';
    final date = c['date_emission']?.toString() ?? '';
    final dateShort = date.length >= 10 ? date.substring(0, 10) : date;
    final valide = c['valide'] ?? true;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _C.nuit3,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: valide ? _C.or.withOpacity(0.5) : Colors.white24,
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _C.or.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  valide ? Icons.verified : Icons.help_outline,
                  color: valide ? _C.or : Colors.white38,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Certificat',
                        style: _serif(16)),
                    const SizedBox(height: 2),
                    Text(titre,
                        style: const TextStyle(
                            color: _C.or,
                            fontSize: 11,
                            fontFamily: 'monospace')),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.calendar_today, color: Colors.white38, size: 14),
              const SizedBox(width: 6),
              Text(dateShort,
                  style: const TextStyle(color: Colors.white54, fontSize: 11)),
              const Spacer(),
              TextButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: _C.nuit3,
                      content: const Text('Téléchargement PDF à venir',
                          style: TextStyle(color: _C.or)),
                    ),
                  );
                },
                child: const Text('Télécharger PDF',
                    style: TextStyle(color: _C.or, fontSize: 11)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
