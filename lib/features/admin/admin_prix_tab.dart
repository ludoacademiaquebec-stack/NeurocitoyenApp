import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _C {
  static const nuit = Color(0xFF060A1F);
  static const nuit2 = Color(0xFF121845);
  static const nuit3 = Color(0xFF0B102E);
  static const or = Color(0xFFC4952B);
  static const orClair = Color(0xFFF0D9A0);
  static const vert = Color(0xFF0F7A3D);
  static const rouge = Color(0xFFE53935);
  static const violet = Color(0xFF7A4E8C);
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

class AdminPrixTab extends StatefulWidget {
  const AdminPrixTab({super.key});
  @override
  State<AdminPrixTab> createState() => _AdminPrixTabState();
}

class _AdminPrixTabState extends State<AdminPrixTab> {
  bool _loading = true;
  List<Map<String, dynamic>> _config = [];
  List<Map<String, dynamic>> _modesPaiement = [];

  SupabaseClient get _db => Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final config = await _db.from('config_ligue').select().order('cle');
      final modes = await _db.from('modes_paiement').select().order('ordre');

      setState(() {
        _config = List<Map<String, dynamic>>.from(config);
        _modesPaiement = List<Map<String, dynamic>>.from(modes);
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      _toast('Erreur : $e', rouge: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: _C.or));
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _header(),
        const SizedBox(height: 20),
        _sectionTitle('PRIX & PARAMÈTRES'),
        const SizedBox(height: 10),
        ..._config.map(_configTile),
        const SizedBox(height: 20),
        _sectionTitle('MODES DE PAIEMENT'),
        const SizedBox(height: 10),
        ..._modesPaiement.map(_modePaiementTile),
      ],
    );
  }

  Widget _header() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_C.orClair, _C.or],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.tune, color: Colors.black54, size: 32),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'CONFIGURATION',
                      style: TextStyle(
                        color: Colors.black54,
                        fontSize: 11,
                        letterSpacing: 2,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text('Prix & Paramètres',
                        style: _serif(24, color: Colors.black, weight: FontWeight.w900)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'Modifie les prix et paramètres de la Ligue. Ces valeurs sont utilisées partout dans l\'application.',
            style: TextStyle(color: Colors.black87, fontSize: 12, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: _C.or,
        fontSize: 11,
        letterSpacing: 2,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _configTile(Map<String, dynamic> c) {
    final cle = c['cle'] ?? '';
    final valeur = c['valeur'] ?? '';
    final type = c['type'] ?? 'texte';
    final description = c['description'] ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _C.nuit2,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _C.or.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _C.or.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  type.toString().toUpperCase(),
                  style: const TextStyle(
                    color: _C.or,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  cle,
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 11,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit, color: _C.or, size: 18),
                onPressed: () => _editConfig(c),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            _formatValeur(valeur, type),
            style: _serif(22, color: Colors.white, weight: FontWeight.w900),
          ),
          if (description.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              description,
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 11,
                height: 1.3,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatValeur(String valeur, String type) {
    if (type == 'prix_fcfa') {
      final n = int.tryParse(valeur) ?? 0;
      if (n == 0) return 'Gratuit';
      final str = n.toString();
      final buf = StringBuffer();
      for (int i = 0; i < str.length; i++) {
        if (i > 0 && (str.length - i) % 3 == 0) buf.write(' ');
        buf.write(str[i]);
      }
      return '${buf.toString()} FCFA';
    }
    return valeur;
  }

  Widget _modePaiementTile(Map<String, dynamic> m) {
    final nom = m['nom'] ?? '';
    final description = m['description'] ?? '';
    final actif = m['actif'] == true;

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
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _C.vert.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.payment, color: _C.vert, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(nom,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w700)),
                if (description.isNotEmpty)
                  Text(description,
                      style: const TextStyle(
                          color: Colors.white54, fontSize: 11)),
              ],
            ),
          ),
          Switch(
            value: actif,
            activeColor: _C.or,
            onChanged: (v) => _toggleModePaiement(m, v),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // ÉDITER CONFIG
  // ===========================================================================
  void _editConfig(Map<String, dynamic> c) {
    final ctrl = TextEditingController(text: '${c['valeur']}');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _C.nuit2,
        title: Text('Modifier : ${c['cle']}',
            style: _serif(16, color: Colors.white)),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (c['description'] != null && '${c['description']}'.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text('${c['description']}',
                      style: const TextStyle(
                          color: Colors.white54, fontSize: 12)),
                ),
              TextField(
                controller: ctrl,
                style: const TextStyle(color: Colors.white, fontSize: 16),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: _C.nuit3,
                  hintText: 'Valeur',
                  hintStyle: const TextStyle(color: Colors.white38),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.all(14),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler',
                style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _saveConfig(c['cle'], ctrl.text.trim());
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _C.or,
              foregroundColor: Colors.black,
            ),
            child: const Text('Enregistrer',
                style: TextStyle(fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }

  Future<void> _saveConfig(String cle, String valeur) async {
    try {
      await _db.from('config_ligue').update({
        'valeur': valeur,
        'modifie_le': DateTime.now().toIso8601String(),
      }).eq('cle', cle);

      await _logEdit('config_ligue', cle, 'update', {'valeur': valeur});

      await _load();
      _toast('Config mise à jour ✅');
    } catch (e) {
      _toast('Erreur : $e', rouge: true);
    }
  }

  Future<void> _toggleModePaiement(Map<String, dynamic> m, bool actif) async {
    try {
      await _db.from('modes_paiement').update({
        'actif': actif,
      }).eq('id', m['id']);
      await _load();
      _toast(actif ? 'Mode activé' : 'Mode désactivé');
    } catch (e) {
      _toast('Erreur : $e', rouge: true);
    }
  }

  Future<void> _logEdit(String table, dynamic rowId, String action, Map<String, dynamic> data) async {
    try {
      await _db.from('edit_log').insert({
        'table_name': table,
        'row_id': null,
        'user_id': _db.auth.currentUser?.id,
        'action': action,
        'new_data': data,
        'user_email': _db.auth.currentUser?.email,
      });
    } catch (_) {}
  }

  void _toast(String msg, {bool rouge = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      backgroundColor: rouge ? _C.rouge : _C.nuit2,
      content: Text(msg,
          style: TextStyle(
              color: rouge ? Colors.white : _C.or, fontSize: 12)),
      duration: const Duration(seconds: 2),
    ));
  }
}
