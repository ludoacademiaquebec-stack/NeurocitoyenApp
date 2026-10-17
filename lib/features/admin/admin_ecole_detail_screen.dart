import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'admin_cursus_detail_screen.dart';

class _C {
  static const nuit = Color(0xFF0B2B2F);
  static const nuit2 = Color(0xFF0E3A3D);
  static const nuit3 = Color(0xFF071D20);
  static const or = Color(0xFFE0A82E);
  static const orClair = Color(0xFFF0BD4A);
  static const vert = Color(0xFF1D7A52);
  static const rouge = Color(0xFFB4473A);
  static const violet = Color(0xFF7A4E8C);
  static const teal = Color(0xFF2F7D6D);
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

class AdminEcoleDetailScreen extends StatefulWidget {
  final Map<String, dynamic> ecole;
  const AdminEcoleDetailScreen({super.key, required this.ecole});

  @override
  State<AdminEcoleDetailScreen> createState() =>
      _AdminEcoleDetailScreenState();
}

class _AdminEcoleDetailScreenState extends State<AdminEcoleDetailScreen>
    with TickerProviderStateMixin {
  late final TabController _tabCtrl;
  bool _loading = true;

  late Map<String, dynamic> _ecole;
  List<Map<String, dynamic>> _cursus = [];
  List<Map<String, dynamic>> _ressources = [];
  List<Map<String, dynamic>> _conditions = [];

  SupabaseClient get _db => Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _ecole = Map<String, dynamic>.from(widget.ecole);
    _tabCtrl = TabController(length: 4, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final eid = _ecole['id'];
      final code = _ecole['code'];

      final e = await _db
          .from('ecoles')
          .select()
          .eq('id', eid)
          .maybeSingle();
      if (e != null) _ecole = e;

      // Cursus de cette école (via ecole_code)
      final cursus = await _db
          .from('cursus')
          .select()
          .eq('ecole_code', code)
          .order('ordre');
      final ressources = await _db
          .from('ecoles_ressources')
          .select()
          .eq('ecole_id', eid)
          .order('ordre');
      final conditions = await _db
          .from('ecoles_conditions')
          .select()
          .eq('ecole_id', eid)
          .order('ordre');

      setState(() {
        _cursus = List<Map<String, dynamic>>.from(cursus);
        _ressources = List<Map<String, dynamic>>.from(ressources);
        _conditions = List<Map<String, dynamic>>.from(conditions);
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      _toast('Erreur : $e', rouge: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.nuit,
      appBar: AppBar(
        backgroundColor: _C.nuit2,
        title: Text(
          '${_ecole['code'] ?? ''} · ${_ecole['nom'] ?? ''}',
          style: const TextStyle(fontSize: 13),
          overflow: TextOverflow.ellipsis,
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: _C.or),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: _C.or),
            onPressed: _load,
            tooltip: 'Rafraîchir',
          ),
        ],
        bottom: TabBar(
          controller: _tabCtrl,
          isScrollable: true,
          indicatorColor: _C.or,
          labelColor: _C.or,
          unselectedLabelColor: Colors.white54,
          labelStyle: const TextStyle(
              fontSize: 11, fontWeight: FontWeight.bold),
          tabs: [
            Tab(text: 'Infos', icon: const Icon(Icons.info, size: 16)),
            Tab(
                text: 'Cursus (${_cursus.length})',
                icon: const Icon(Icons.book, size: 16)),
            Tab(
                text: 'Ressources (${_ressources.length})',
                icon: const Icon(Icons.attach_file, size: 16)),
            Tab(
                text: 'Conditions (${_conditions.length})',
                icon: const Icon(Icons.checklist, size: 16)),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _C.or))
          : TabBarView(
              controller: _tabCtrl,
              children: [
                _tabInfos(),
                _tabCursus(),
                _tabRessources(),
                _tabConditions(),
              ],
            ),
    );
  }

  // ===========================================================================
  // TAB 1 : INFOS
  // ===========================================================================
  Widget _tabInfos() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _infoCard('Code', '${_ecole['code'] ?? ''}', Icons.qr_code, _C.teal),
        _infoCard('Nom', '${_ecole['nom'] ?? ''}', Icons.school, _C.or),
        _infoCard('Sous-titre', '${_ecole['sous_titre'] ?? ''}',
            Icons.subtitles, _C.or),
        _infoCard('Description', '${_ecole['description'] ?? ''}',
            Icons.description, _C.or),
        _infoCard('Mission', '${_ecole['mission'] ?? ''}', Icons.flag, _C.violet),
        _infoCard('Icône', '${_ecole['icone'] ?? 'school'}', Icons.image, _C.or),
        _infoCard('Couleur', '${_ecole['couleur'] ?? '#C4952B'}',
            Icons.palette, _C.or),
        _infoCard('Nombre de cursus', '${_cursus.length}', Icons.book, _C.teal),
        const SizedBox(height: 20),
        _actionBtn(Icons.edit, 'Éditer les infos de l\'école', _C.or,
            () => _editEcole()),
      ],
    );
  }

  Widget _infoCard(String label, String value, IconData icon, Color color) {
    if (value.isEmpty) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _C.nuit2,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        color: Colors.white54, fontSize: 10)),
                const SizedBox(height: 2),
                Text(value,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // TAB 2 : CURSUS
  // ===========================================================================
  Widget _tabCursus() {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _cursus.length + 1,
      itemBuilder: (c, i) {
        if (i == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _actionBtn(Icons.add_circle, 'Nouveau cursus', _C.vert,
                () => _addCursus()),
          );
        }
        final cu = _cursus[i - 1];

        return InkWell(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => AdminCursusDetailScreen(cursus: cu),
              ),
            ).then((_) => _load());
          },
          borderRadius: BorderRadius.circular(10),
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _C.nuit2,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _C.violet.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _C.violet.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${cu['domaine'] ?? 'Cursus'}',
                        style: const TextStyle(
                            color: _C.violet,
                            fontSize: 10,
                            fontWeight: FontWeight.w900),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${cu['prix_fcfa'] ?? 0} FCFA',
                      style: const TextStyle(
                          color: _C.orClair,
                          fontSize: 11,
                          fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text('${cu['nom']}',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700)),
                if (cu['sous_titre'] != null &&
                    '${cu['sous_titre']}'.isNotEmpty)
                  Text('${cu['sous_titre']}',
                      style: const TextStyle(
                          color: Colors.white54, fontSize: 11)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.schedule,
                        color: Colors.white38, size: 12),
                    const SizedBox(width: 4),
                    Text('${cu['duree_semaines'] ?? 0} sem.',
                        style: const TextStyle(
                            color: Colors.white54, fontSize: 11)),
                    const SizedBox(width: 12),
                    const Icon(Icons.arrow_forward,
                        color: _C.or, size: 12),
                    const SizedBox(width: 4),
                    const Text('Tape pour détails',
                        style: TextStyle(
                            color: _C.or,
                            fontSize: 10,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ===========================================================================
  // TAB 3 : RESSOURCES
  // ===========================================================================
  Widget _tabRessources() {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        _actionBtn(Icons.add_circle, 'Nouvelle ressource', _C.vert,
            () => _editRessource(null)),
        const SizedBox(height: 12),
        if (_ressources.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(40),
              child: Text('Aucune ressource',
                  style: TextStyle(color: Colors.white54, fontSize: 13)),
            ),
          )
        else
          ..._ressources.map(_ressourceTile),
      ],
    );
  }

  Widget _ressourceTile(Map<String, dynamic> r) {
    final type = '${r['type']}';
    IconData icon;
    Color color;
    switch (type) {
      case 'video':
        icon = Icons.play_circle;
        color = _C.rouge;
        break;
      case 'pdf':
        icon = Icons.picture_as_pdf;
        color = _C.or;
        break;
      case 'audio':
        icon = Icons.headphones;
        color = _C.violet;
        break;
      default:
        icon = Icons.link;
        color = _C.vert;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _C.nuit2,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${r['titre']}',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w700)),
                Text('$type',
                    style: const TextStyle(
                        color: Colors.white54, fontSize: 10)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit, color: _C.or, size: 16),
            onPressed: () => _editRessource(r),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 6),
          IconButton(
            icon: const Icon(Icons.delete, color: _C.rouge, size: 16),
            onPressed: () => _deleteRessource(r),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // TAB 4 : CONDITIONS
  // ===========================================================================
  Widget _tabConditions() {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        _actionBtn(Icons.add_circle, 'Nouvelle condition', _C.vert,
            () => _editCondition(null)),
        const SizedBox(height: 12),
        if (_conditions.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(40),
              child: Text('Aucune condition',
                  style: TextStyle(color: Colors.white54, fontSize: 13)),
            ),
          )
        else
          ..._conditions.map(_conditionTile),
      ],
    );
  }

  Widget _conditionTile(Map<String, dynamic> c) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _C.nuit2,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        children: [
          Icon(
            c['obligatoire'] == true ? Icons.check_circle : Icons.info,
            color: c['obligatoire'] == true ? _C.vert : Colors.white54,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${c['titre']}',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w700)),
                if (c['description'] != null)
                  Text('${c['description']}',
                      style: const TextStyle(
                          color: Colors.white54, fontSize: 11)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit, color: _C.or, size: 16),
            onPressed: () => _editCondition(c),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 6),
          IconButton(
            icon: const Icon(Icons.delete, color: _C.rouge, size: 16),
            onPressed: () => _deleteCondition(c),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // HELPERS
  // ===========================================================================
  Widget _actionBtn(
      IconData icon, String label, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color.withOpacity(0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 13),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFormDialog({
    required String title,
    required List<Widget> fields,
    required Future<void> Function() onSubmit,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _C.nuit2,
        titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
        contentPadding: const EdgeInsets.all(20),
        title: Text(title, style: _serif(16, color: Colors.white)),
        content: SizedBox(
          width: 550,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: fields,
            ),
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
              await onSubmit();
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

  Widget _formField(
    String label,
    TextEditingController ctrl, {
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  color: Colors.white54, fontSize: 11)),
          const SizedBox(height: 6),
          TextField(
            controller: ctrl,
            keyboardType: keyboardType,
            maxLines: maxLines,
            style: const TextStyle(color: Colors.white, fontSize: 13),
            decoration: InputDecoration(
              filled: true,
              fillColor: _C.nuit3,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 10),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dropdownFormField(
    String label,
    String? value,
    List<DropdownMenuItem<String>> items,
    Function(String?) onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  color: Colors.white54, fontSize: 11)),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            value: value,
            dropdownColor: _C.nuit3,
            style: const TextStyle(color: Colors.white, fontSize: 13),
            decoration: InputDecoration(
              filled: true,
              fillColor: _C.nuit3,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 10),
            ),
            items: items,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Future<void> _save(
    String table,
    dynamic id,
    Map<String, dynamic> data,
    bool isNew,
    String label,
  ) async {
    try {
      if (isNew) {
        await _db.from(table).insert(data);
        await _logEdit(table, null, 'insert', null, data);
        _toast('$label créé ✅');
      } else {
        await _db.from(table).update(data).eq('id', id);
        await _logEdit(table, id, 'update', null, data);
        _toast('$label mis à jour ✅');
      }
      await _load();
    } catch (e) {
      _toast('Erreur : $e', rouge: true);
    }
  }

  void _confirmDelete(String table, dynamic id, String label) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _C.nuit2,
        title: Text('Supprimer ce $label ?',
            style: _serif(16, color: Colors.white)),
        content: const Text(
          'Cette action est IRRÉVERSIBLE.',
          style: TextStyle(color: Colors.white70, fontSize: 13),
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
              try {
                await _db.from(table).delete().eq('id', id);
                await _logEdit(table, id, 'delete', {'id': id}, null);
                await _load();
                _toast('$label supprimé');
              } catch (e) {
                _toast('Erreur : $e', rouge: true);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _C.rouge,
              foregroundColor: Colors.white,
            ),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  Future<void> _logEdit(
    String table,
    dynamic rowId,
    String action,
    Map<String, dynamic>? oldData,
    Map<String, dynamic>? newData,
  ) async {
    try {
      await _db.from('edit_log').insert({
        'table_name': table,
        'row_id': rowId,
        'user_id': _db.auth.currentUser?.id,
        'action': action,
        'old_data': oldData,
        'new_data': newData,
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

  // ===========================================================================
  // FORMULAIRE ÉCOLE (Infos)
  // ===========================================================================
  void _editEcole() {
    final codeCtrl = TextEditingController(text: '${_ecole['code']}');
    final nomCtrl = TextEditingController(text: '${_ecole['nom']}');
    final sousTitreCtrl =
        TextEditingController(text: '${_ecole['sous_titre'] ?? ''}');
    final descCtrl =
        TextEditingController(text: '${_ecole['description'] ?? ''}');
    final missionCtrl =
        TextEditingController(text: '${_ecole['mission'] ?? ''}');
    final iconeCtrl =
        TextEditingController(text: '${_ecole['icone'] ?? 'school'}');
    final couleurCtrl =
        TextEditingController(text: '${_ecole['couleur'] ?? '#C4952B'}');
    final ordreCtrl =
        TextEditingController(text: '${_ecole['ordre'] ?? 99}');

    _showFormDialog(
      title: 'Éditer l\'école',
      fields: [
        _formField('Code', codeCtrl),
        _formField('Nom', nomCtrl),
        _formField('Sous-titre', sousTitreCtrl),
        _formField('Description', descCtrl, maxLines: 3),
        _formField('Mission', missionCtrl, maxLines: 3),
        _formField('Icône', iconeCtrl),
        _formField('Couleur (hex)', couleurCtrl),
        _formField('Ordre', ordreCtrl, keyboardType: TextInputType.number),
      ],
      onSubmit: () async {
        final data = {
          'code': codeCtrl.text.trim(),
          'nom': nomCtrl.text.trim(),
          'sous_titre': sousTitreCtrl.text.trim(),
          'description': descCtrl.text.trim(),
          'mission': missionCtrl.text.trim(),
          'icone': iconeCtrl.text.trim(),
          'couleur': couleurCtrl.text.trim(),
          'ordre': int.tryParse(ordreCtrl.text) ?? 99,
        };
        await _save('ecoles', _ecole['id'], data, false, 'École');
      },
    );
  }

  // ===========================================================================
  // FORMULAIRE CURSUS (créer un nouveau cursus pour cette école)
  // ===========================================================================
  void _addCursus() {
    final nomCtrl = TextEditingController();
    final sousTitreCtrl = TextEditingController();
    final domaineCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final prixCtrl = TextEditingController(text: '0');
    final dureeCtrl = TextEditingController(text: '16');
    final dureeMoisCtrl = TextEditingController(text: '4');

    _showFormDialog(
      title: 'Nouveau cursus pour ${_ecole['code']}',
      fields: [
        _formField('Nom du cursus', nomCtrl),
        _formField('Sous-titre', sousTitreCtrl),
        _formField('Domaine', domaineCtrl),
        _formField('Description', descCtrl, maxLines: 3),
        _formField('Prix (FCFA)', prixCtrl,
            keyboardType: TextInputType.number),
        _formField('Durée (semaines)', dureeCtrl,
            keyboardType: TextInputType.number),
        _formField('Durée (mois)', dureeMoisCtrl,
            keyboardType: TextInputType.number),
      ],
      onSubmit: () async {
        final data = {
          'ecole_id': _ecole['id'],
          'ecole_code': _ecole['code'],
          'nom': nomCtrl.text.trim(),
          'sous_titre': sousTitreCtrl.text.trim(),
          'domaine': domaineCtrl.text.trim(),
          'description': descCtrl.text.trim(),
          'prix_fcfa': int.tryParse(prixCtrl.text) ?? 0,
          'duree_semaines': int.tryParse(dureeCtrl.text) ?? 16,
          'duree_mois': int.tryParse(dureeMoisCtrl.text) ?? 4,
          'niveau': 'avance',
          'modalite': 'presentiel',
          'nombre_modules': 0,
          'actif': true,
          'ordre': 99,
        };
        await _save('cursus', null, data, true, 'Cursus');
      },
    );
  }

  // ===========================================================================
  // FORMULAIRE RESSOURCE (école)
  // ===========================================================================
  void _editRessource(Map<String, dynamic>? r) {
    final isNew = r == null;
    String type = isNew ? 'pdf' : '${r['type']}';

    final titreCtrl = TextEditingController(text: isNew ? '' : '${r['titre']}');
    final descCtrl =
        TextEditingController(text: isNew ? '' : '${r['description'] ?? ''}');
    final urlCtrl = TextEditingController(text: isNew ? '' : '${r['url'] ?? ''}');

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          backgroundColor: _C.nuit2,
          titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
          contentPadding: const EdgeInsets.all(20),
          title: Text(isNew ? 'Nouvelle ressource' : 'Éditer la ressource',
              style: _serif(16, color: Colors.white)),
          content: SizedBox(
            width: 550,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _dropdownFormField(
                    'Type',
                    type,
                    const [
                      DropdownMenuItem(value: 'pdf', child: Text('📄 PDF')),
                      DropdownMenuItem(value: 'video', child: Text('🎬 Vidéo')),
                      DropdownMenuItem(value: 'image', child: Text('🖼️ Image')),
                      DropdownMenuItem(value: 'lien', child: Text('🔗 Lien')),
                    ],
                    (v) => setS(() => type = v ?? 'pdf'),
                  ),
                  _formField('Titre', titreCtrl),
                  _formField('Description', descCtrl, maxLines: 2),
                  _formField('URL', urlCtrl),
                ],
              ),
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
                final data = {
                  'ecole_id': _ecole['id'],
                  'type': type,
                  'titre': titreCtrl.text.trim(),
                  'description': descCtrl.text.trim(),
                  'url': urlCtrl.text.trim(),
                  'ordre': 99,
                  'actif': true,
                };
                await _save('ecoles_ressources', r?['id'], data, isNew,
                    'Ressource');
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
      ),
    );
  }

  void _deleteRessource(Map<String, dynamic> r) {
    _confirmDelete('ecoles_ressources', r['id'], 'ressource');
  }

  // ===========================================================================
  // FORMULAIRE CONDITION (école)
  // ===========================================================================
  void _editCondition(Map<String, dynamic>? c) {
    final isNew = c == null;
    String type = isNew ? 'prerequis' : '${c['type'] ?? 'prerequis'}';
    bool obligatoire = isNew ? true : (c['obligatoire'] == true);

    final titreCtrl = TextEditingController(text: isNew ? '' : '${c['titre']}');
    final descCtrl =
        TextEditingController(text: isNew ? '' : '${c['description'] ?? ''}');
    final valeurCtrl =
        TextEditingController(text: isNew ? '' : '${c['valeur'] ?? ''}');

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          backgroundColor: _C.nuit2,
          titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
          contentPadding: const EdgeInsets.all(20),
          title: Text(isNew ? 'Nouvelle condition' : 'Éditer la condition',
              style: _serif(16, color: Colors.white)),
          content: SizedBox(
            width: 500,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _dropdownFormField(
                    'Type',
                    type,
                    const [
                      DropdownMenuItem(
                          value: 'prerequis', child: Text('Prérequis')),
                      DropdownMenuItem(
                          value: 'document', child: Text('Document')),
                      DropdownMenuItem(value: 'age', child: Text('Âge')),
                      DropdownMenuItem(
                          value: 'experience', child: Text('Expérience')),
                    ],
                    (v) => setS(() => type = v ?? 'prerequis'),
                  ),
                  _formField('Titre', titreCtrl),
                  _formField('Description', descCtrl, maxLines: 2),
                  _formField('Valeur', valeurCtrl),
                  Row(
                    children: [
                      const Text('Obligatoire',
                          style: TextStyle(
                              color: Colors.white70, fontSize: 13)),
                      const Spacer(),
                      Switch(
                        value: obligatoire,
                        activeColor: _C.or,
                        onChanged: (v) => setS(() => obligatoire = v),
                      ),
                    ],
                  ),
                ],
              ),
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
                final data = {
                  'ecole_id': _ecole['id'],
                  'type': type,
                  'titre': titreCtrl.text.trim(),
                  'description': descCtrl.text.trim(),
                  'valeur': valeurCtrl.text.trim(),
                  'obligatoire': obligatoire,
                  'ordre': 99,
                  'actif': true,
                };
                await _save('ecoles_conditions', c?['id'], data, isNew,
                    'Condition');
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
      ),
    );
  }

  void _deleteCondition(Map<String, dynamic> c) {
    _confirmDelete('ecoles_conditions', c['id'], 'condition');
  }
}
