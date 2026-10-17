import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/app_theme_service.dart';

class _C {
  static const nuit = Color(0xFF060A1F);
  static const nuit2 = Color(0xFF121845);
  static const nuit3 = Color(0xFF0B102E);
  static const or = Color(0xFFC4952B);
  static const orClair = Color(0xFFF0D9A0);
  static const vert = Color(0xFF0F7A3D);
  static const rouge = Color(0xFFB4473A);
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

class AdminThemeTab extends StatefulWidget {
  const AdminThemeTab({super.key});
  @override
  State<AdminThemeTab> createState() => _AdminThemeTabState();
}

class _AdminThemeTabState extends State<AdminThemeTab> {
  bool _loading = true;
  List<Map<String, dynamic>> _themes = [];
  SupabaseClient get _db => Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await _db.from('app_theme').select().order('categorie').order('nom');
      setState(() {
        _themes = List<Map<String, dynamic>>.from(res);
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      _toast('Erreur : $e', rouge: true);
    }
  }

  Future<void> _updateColor(String nom, String nouvelleValeur) async {
    try {
      await _db.from('app_theme').update({
        'valeur': nouvelleValeur,
        'modifie_le': DateTime.now().toIso8601String(),
      }).eq('nom', nom);

      final c = _hexToColor(nouvelleValeur);
      if (c != null) {
        AppThemeService.instance.setLocal(nom, c);
      }
      _toast('Couleur "$nom" mise à jour → $nouvelleValeur');
      await AppThemeService.instance.reload();
      await _load();
    } catch (e) {
      _toast('Erreur : $e', rouge: true);
    }
  }

  Color? _hexToColor(String hex) {
    var h = hex.trim();
    if (h.startsWith('#')) h = h.substring(1);
    if (h.length == 6) h = 'FF$h';
    if (h.length != 8) return null;
    final v = int.tryParse(h, radix: 16);
    if (v == null) return null;
    return Color(v);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator(color: _C.or));

    final byCategorie = <String, List<Map<String, dynamic>>>{};
    for (final t in _themes) {
      final cat = (t['categorie'] as String?) ?? 'autre';
      byCategorie.putIfAbsent(cat, () => []).add(t);
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [_C.or, _C.orClair],
              begin: Alignment.topLeft, end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              const Icon(Icons.palette, color: Colors.black54, size: 36),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Apparence de l\'application', style: _serif(20, color: Colors.black)),
                    const SizedBox(height: 4),
                    const Text('Modifie les couleurs BIIC en direct', style: TextStyle(color: Colors.black87, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        _section('Fond (nuit)', byCategorie['fond'] ?? [], 'Couleurs de fond : pages sombres, cartes, footer'),
        _section('Accent', byCategorie['accent'] ?? [], 'Couleurs d\'accent : or, vert, teal, violet, rouge'),
        _section('Texte', byCategorie['texte'] ?? [], 'Couleurs de texte sur fond clair'),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _C.nuit3,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.white12),
          ),
          child: const Row(
            children: [
              Icon(Icons.info_outline, color: _C.or, size: 20),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Les changements sont appliqués à tous les utilisateurs au prochain chargement de l\'app. Aucun redéploiement nécessaire.',
                  style: TextStyle(color: Colors.white70, fontSize: 11, height: 1.5),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _section(String titre, List<Map<String, dynamic>> items, String desc) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 16, bottom: 4),
          child: Text(titre, style: _serif(16, color: _C.orClair)),
        ),
        Text(desc, style: const TextStyle(color: Colors.white54, fontSize: 11)),
        const SizedBox(height: 10),
        ...items.map(_colorTile),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _colorTile(Map<String, dynamic> t) {
    final nom = t['nom'] as String;
    final valeur = t['valeur'] as String;
    final c = _hexToColor(valeur) ?? Colors.grey;
    final hexCtrl = TextEditingController(text: valeur);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _C.nuit2,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: c,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white24, width: 2),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(nom, style: _serif(14, color: _C.orClair)),
                if (t['description'] != null)
                  Text('${t['description']}',
                      style: const TextStyle(color: Colors.white54, fontSize: 10)),
              ],
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 110,
            child: TextField(
              controller: hexCtrl,
              style: const TextStyle(color: Colors.white, fontSize: 12, fontFamily: 'monospace'),
              decoration: InputDecoration(
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                filled: true,
                fillColor: _C.nuit3,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: const BorderSide(color: Colors.white12),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: const BorderSide(color: Colors.white12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: const BorderSide(color: _C.or),
                ),
              ),
              onSubmitted: (v) {
                if (v.length >= 6) _updateColor(nom, v);
              },
            ),
          ),
          const SizedBox(width: 6),
          IconButton(
            icon: const Icon(Icons.check_circle, color: _C.vert),
            tooltip: 'Appliquer',
            onPressed: () {
              if (hexCtrl.text.length >= 6) _updateColor(nom, hexCtrl.text);
            },
          ),
        ],
      ),
    );
  }

  void _toast(String msg, {bool rouge = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      backgroundColor: rouge ? _C.rouge : _C.vert,
      content: Text(msg, style: const TextStyle(color: Colors.white)),
      duration: const Duration(seconds: 2),
    ));
  }
}
