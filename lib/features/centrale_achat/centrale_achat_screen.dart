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

class CentraleAchatScreen extends StatefulWidget {
  const CentraleAchatScreen({super.key});
  @override
  State<CentraleAchatScreen> createState() => _CentraleAchatScreenState();
}

class _CentraleAchatScreenState extends State<CentraleAchatScreen> {
  List<Map<String, dynamic>> _produits = [];
  List<Map<String, dynamic>> _commandes = [];
  bool _loading = true;
  String _filtre = 'tous';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final res = await Supabase.instance.client
          .from('produits_centrale')
          .select()
          .eq('actif', true)
          .order('nom');
      _produits = List<Map<String, dynamic>>.from(res);
    } catch (_) {}

    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id');
      if (userId != null) {
        final res2 = await Supabase.instance.client
            .from('commandes_centrale')
            .select()
            .eq('user_id', userId)
            .order('created_at', ascending: false)
            .limit(20);
        _commandes = List<Map<String, dynamic>>.from(res2);
      }
    } catch (_) {}

    setState(() => _loading = false);
  }

  List<String> get _categories {
    final cats = <String>{'tous'};
    for (final p in _produits) {
      final c = p['categorie']?.toString();
      if (c != null && c.isNotEmpty) cats.add(c);
    }
    return cats.toList();
  }

  List<Map<String, dynamic>> get _produitsFiltres {
    if (_filtre == 'tous') return _produits;
    return _produits.where((p) => p['categorie'] == _filtre).toList();
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Centrale d\'achat',
      child: _loading
          ? const Center(child: CircularProgressIndicator(color: _C.or))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _header(),
                const SizedBox(height: 16),
                if (_produits.isNotEmpty) _filtres(),
                const SizedBox(height: 12),
                if (_produitsFiltres.isEmpty)
                  _emptyProduits()
                else
                  ..._produitsFiltres.map(_produitTile),
                if (_commandes.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  _commandesTitle(),
                  const SizedBox(height: 10),
                  ..._commandes.map(_commandeTile),
                ],
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
          const Icon(Icons.shopping_cart, color: Colors.black54, size: 32),
          const SizedBox(height: 10),
          Text('Centrale d\'achat',
              style: _serif(26, color: Colors.black, weight: FontWeight.w900)),
          const SizedBox(height: 4),
          const Text(
            'Achète en groupe, paie moins cher. Les ristournes sont redistribuées en fin d\'année.',
            style: TextStyle(color: Colors.black87, fontSize: 12, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _filtres() {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (c, i) {
          final cat = _categories[i];
          final sel = _filtre == cat;
          return ChoiceChip(
            label: Text(
              cat == 'tous' ? 'Tous' : cat,
              style: TextStyle(
                color: sel ? Colors.black : Colors.white70,
                fontSize: 11,
              ),
            ),
            selected: sel,
            selectedColor: _C.or,
            backgroundColor: Colors.white10,
            side: BorderSide(color: _C.or.withOpacity(0.3)),
            onSelected: (_) => setState(() => _filtre = cat),
            showCheckmark: false,
          );
        },
      ),
    );
  }

  Widget _emptyProduits() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: _C.nuit3,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: const Column(
        children: [
          Icon(Icons.inventory_2, color: Colors.white38, size: 48),
          SizedBox(height: 12),
          Text('Aucun produit disponible',
              style: TextStyle(color: Colors.white54, fontSize: 14)),
          SizedBox(height: 6),
          Text(
            'Le catalogue sera bientôt rempli.\nReviens plus tard !',
            style: TextStyle(color: Colors.white38, fontSize: 12, height: 1.5),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _commandesTitle() {
    return Row(
      children: [
        const Icon(Icons.receipt_long, color: _C.or, size: 18),
        const SizedBox(width: 8),
        Text('Mes commandes', style: _serif(18)),
      ],
    );
  }

  Widget _produitTile(Map<String, dynamic> p) {
    final prix = (p['prix_unitaire'] as num?)?.toInt() ?? 0;
    final qteMin = (p['quantite_min'] as num?)?.toInt() ?? 1;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _C.nuit3,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _C.or.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.inventory_2, color: _C.or, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(p['nom'] ?? 'Produit',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                if (p['description'] != null)
                  Text(p['description'],
                      style: const TextStyle(
                          color: Colors.white54, fontSize: 11),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Text('Prix : $prix ND · Min. $qteMin',
                    style: const TextStyle(color: _C.or, fontSize: 11)),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () => _commander(p),
            style: ElevatedButton.styleFrom(
              backgroundColor: _C.or,
              foregroundColor: Colors.black,
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape:
                  RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
            child: const Text('Commander',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Widget _commandeTile(Map<String, dynamic> c) {
    final qte = c['quantite'] ?? 0;
    final total = c['prix_total'] ?? 0;
    final statut = c['statut'] ?? 'en_attente';
    final date = c['created_at']?.toString() ?? '';
    final dateShort = date.length >= 10 ? date.substring(0, 10) : date;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _C.nuit3,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline, color: _C.or, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Commande × $qte',
                    style: const TextStyle(color: Colors.white, fontSize: 13)),
                Text('$dateShort · $statut',
                    style: const TextStyle(color: Colors.white54, fontSize: 10)),
              ],
            ),
          ),
          Text('$total ND',
              style: const TextStyle(
                  color: _C.or, fontSize: 13, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Future<void> _commander(Map<String, dynamic> p) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id');
      if (userId == null) {
        _toast('Connecte-toi pour commander');
        return;
      }
      final qteMin = (p['quantite_min'] as num?)?.toInt() ?? 1;
      final prixU = (p['prix_unitaire'] as num?)?.toInt() ?? 0;
      await Supabase.instance.client.from('commandes_centrale').insert({
        'user_id': userId,
        'produit_id': p['id'],
        'quantite': qteMin,
        'prix_total': qteMin * prixU,
        'statut': 'en_attente',
      });
      _toast('Commande envoyée !');
      await _load();
    } catch (e) {
      _toast('Erreur commande : ${e.toString().substring(0, 60)}');
    }
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      backgroundColor: _C.nuit2,
      content: Text(msg, style: const TextStyle(color: _C.or, fontSize: 12)),
    ));
  }
}
