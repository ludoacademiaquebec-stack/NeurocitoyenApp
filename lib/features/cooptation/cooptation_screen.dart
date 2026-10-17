import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../widgets/app_scaffold.dart';

class _C {
  static const nuit = Color(0xFF0B2B2F);
  static const nuit2 = Color(0xFF0E3A3D);
  static const nuit3 = Color(0xFF071D20);
  static const or = Color(0xFFE0A82E);
  static const orClair = Color(0xFFF0BD4A);
  static const vert = Color(0xFF1D7A52);
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

class CooptationScreen extends StatefulWidget {
  const CooptationScreen({super.key});
  @override
  State<CooptationScreen> createState() => _CooptationScreenState();
}

class _CooptationScreenState extends State<CooptationScreen> {
  String _codeParrain = 'BJ-XXXX-0000';
  String? _userId;
  List<Map<String, dynamic>> _filleuls = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    _codeParrain = prefs.getString('code_parrain') ?? 'BJ-XXXX-0000';
    _userId = prefs.getString('user_id');

    if (_userId != null) {
      try {
        final res = await Supabase.instance.client
            .from('cooptations')
            .select()
            .eq('parrain_id', _userId!)
            .order('created_at', ascending: false);
        _filleuls = List<Map<String, dynamic>>.from(res);
      } catch (_) {}
    }
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Mon Arbre de Cooptation',
      child: _loading
          ? const Center(child: CircularProgressIndicator(color: _C.or))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _codeCard(),
                const SizedBox(height: 20),
                _statsRow(),
                const SizedBox(height: 20),
                _treeTitle(),
                const SizedBox(height: 10),
                if (_filleuls.isEmpty)
                  _emptyState()
                else
                  ..._filleuls.map((f) => _filleulTile(f)),
              ],
            ),
    );
  }

  Widget _codeCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_C.or, Color(0xFF8B6914)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: _C.or.withOpacity(0.3), blurRadius: 20)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'MON CODE DE COOPTATION',
            style: TextStyle(
              color: Colors.black54,
              fontSize: 11,
              letterSpacing: 2,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  _codeParrain,
                  style: _serif(24, color: Colors.black, weight: FontWeight.w900),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.copy, color: Colors.black87),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: _codeParrain));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      backgroundColor: Colors.black87,
                      content: Text('Code copié !',
                          style: TextStyle(color: Colors.white)),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Partage ce code : chaque personne qui s\'inscrit avec devient ton filleul et te rapporte des commissions sur 4 générations.',
            style: TextStyle(color: Colors.black87, fontSize: 11, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _statsRow() {
    return Row(
      children: [
        Expanded(
            child: _statCard(
                'Filleuls directs', _filleuls.length.toString(), Icons.person_add)),
        const SizedBox(width: 10),
        Expanded(
            child: _statCard('Commissions', '0 ND', Icons.attach_money)),
      ],
    );
  }

  Widget _statCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _C.nuit3,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        children: [
          Icon(icon, color: _C.or, size: 20),
          const SizedBox(height: 6),
          Text(value, style: _serif(20)),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(color: Colors.white54, fontSize: 10)),
        ],
      ),
    );
  }

  Widget _treeTitle() {
    return Row(
      children: [
        const Icon(Icons.account_tree, color: _C.or, size: 18),
        const SizedBox(width: 8),
        Text('Mon arbre', style: _serif(18)),
      ],
    );
  }

  Widget _emptyState() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _C.nuit3,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: const Column(
        children: [
          Icon(Icons.account_tree, color: Colors.white38, size: 40),
          SizedBox(height: 10),
          Text('Aucun filleul pour l\'instant',
              style: TextStyle(color: Colors.white54, fontSize: 13)),
          SizedBox(height: 4),
          Text('Partage ton code de cooptation pour commencer',
              style: TextStyle(color: Colors.white38, fontSize: 11),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _filleulTile(Map<String, dynamic> f) {
    final gen = f['generation'] ?? 1;
    final date = f['created_at']?.toString() ?? '';
    final id = f['filleul_id']?.toString() ?? '';
    final shortId = id.length >= 8 ? id.substring(0, 8) : id;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _C.nuit3,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _C.or.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(color: _C.or, shape: BoxShape.circle),
            child: const Icon(Icons.person, color: Colors.black, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Membre $shortId',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text(
                  'Génération $gen${date.length >= 10 ? ' · ${date.substring(0, 10)}' : ''}',
                  style: const TextStyle(color: Colors.white54, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
