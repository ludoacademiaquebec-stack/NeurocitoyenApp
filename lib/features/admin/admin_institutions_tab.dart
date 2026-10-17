import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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

class AdminInstitutionsTab extends StatefulWidget {
  const AdminInstitutionsTab({super.key});
  @override
  State<AdminInstitutionsTab> createState() => _AdminInstitutionsTabState();
}

class _AdminInstitutionsTabState extends State<AdminInstitutionsTab>
    with TickerProviderStateMixin {
  late final TabController _subTabCtrl;
  bool _loading = true;

  // Données
  List<Map<String, dynamic>> _sections = [];
  List<Map<String, dynamic>> _niveaux = [];
  List<Map<String, dynamic>> _poles = [];
  List<Map<String, dynamic>> _grades = [];

  SupabaseClient get _db => Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _subTabCtrl = TabController(length: 4, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _subTabCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final sections = await _db
          .from('institutions_sections')
          .select()
          .order('numero_ordre');
      final niveaux = await _db
          .from('institutions_niveaux')
          .select()
          .order('numero');
      final poles = await _db
          .from('institutions_poles_officiels')
          .select()
          .order('numero');
      final grades = await _db
          .from('institutions_grades')
          .select()
          .order('numero');

      setState(() {
        _sections = List<Map<String, dynamic>>.from(sections);
        _niveaux = List<Map<String, dynamic>>.from(niveaux);
        _poles = List<Map<String, dynamic>>.from(poles);
        _grades = List<Map<String, dynamic>>.from(grades);
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      _toast('Erreur de chargement : $e', rouge: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: _C.or));
    }

    return Column(
      children: [
        _header(),
        // Sous-onglets
        Container(
          color: _C.nuit3,
          child: TabBar(
            controller: _subTabCtrl,
            isScrollable: true,
            indicatorColor: _C.violet,
            labelColor: _C.violet,
            unselectedLabelColor: Colors.white54,
            labelStyle: const TextStyle(
                fontSize: 11, fontWeight: FontWeight.bold),
            tabs: const [
              Tab(text: 'Sections', icon: Icon(Icons.article, size: 16)),
              Tab(text: 'Niveaux', icon: Icon(Icons.account_tree, size: 16)),
              Tab(text: 'Pôles', icon: Icon(Icons.grid_view, size: 16)),
              Tab(text: 'Grades', icon: Icon(Icons.military_tech, size: 16)),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _subTabCtrl,
            children: [
              _listeSections(),
              _listeNiveaux(),
              _listePoles(),
              _listeGrades(),
            ],
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // HEADER
  // ===========================================================================
  Widget _header() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: _C.nuit2,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _C.violet.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.account_balance, color: _C.violet, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Document institutionnel', style: _serif(18)),
                Text(
                  '${_sections.length} sections · ${_niveaux.length} niveaux · ${_poles.length} pôles · ${_grades.length} grades',
                  style: const TextStyle(
                      color: Colors.white54, fontSize: 11),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: _C.violet),
            onPressed: _load,
            tooltip: 'Rafraîchir',
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // SOUS-TAB 1 : SECTIONS
  // ===========================================================================
  Widget _listeSections() {
    if (_sections.isEmpty) return _emptyState('Aucune section');

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _sections.length + 1,
      itemBuilder: (c, i) {
        if (i == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _actionBtn(
              Icons.add_circle,
              'Nouvelle section',
              _C.vert,
              () => _editSection(null),
            ),
          );
        }
        final s = _sections[i - 1];
        return _itemCard(
          badge: '${s['numero_ordre'] ?? '-'}',
          title: '${s['titre']}',
          subtitle: '${s['sous_titre'] ?? ''}',
          badgeColor: _C.violet,
          actif: s['actif'] == true,
          onEdit: () => _editSection(s),
          onToggle: () => _toggleActif('institutions_sections', s),
          onDelete: () => _confirmDelete('institutions_sections', s, 'section'),
        );
      },
    );
  }

  // ===========================================================================
  // SOUS-TAB 2 : NIVEAUX
  // ===========================================================================
  Widget _listeNiveaux() {
    if (_niveaux.isEmpty) return _emptyState('Aucun niveau');

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _niveaux.length + 1,
      itemBuilder: (c, i) {
        if (i == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _actionBtn(
              Icons.add_circle,
              'Nouveau niveau',
              _C.vert,
              () => _editNiveau(null),
            ),
          );
        }
        final n = _niveaux[i - 1];
        return _itemCard(
          badge: '${n['numero']}',
          title: '${n['titre']}',
          subtitle: '${n['territoire']} · ${n['instance']} · ${n['forme_descriptive'] ?? ''}',
          badgeColor: _C.teal,
          actif: n['actif'] == true,
          onEdit: () => _editNiveau(n),
          onToggle: () => _toggleActif('institutions_niveaux', n),
          onDelete: () => _confirmDelete('institutions_niveaux', n, 'niveau'),
        );
      },
    );
  }

  // ===========================================================================
  // SOUS-TAB 3 : PÔLES
  // ===========================================================================
  Widget _listePoles() {
    if (_poles.isEmpty) return _emptyState('Aucun pôle');

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _poles.length + 1,
      itemBuilder: (c, i) {
        if (i == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _actionBtn(
              Icons.add_circle,
              'Nouveau pôle',
              _C.vert,
              () => _editPole(null),
            ),
          );
        }
        final p = _poles[i - 1];
        return _itemCard(
          badge: '${p['numero']}',
          title: '${p['nom']}',
          subtitle: '${p['institutions_rattachees'] ?? ''}',
          badgeColor: _C.or,
          actif: p['actif'] == true,
          onEdit: () => _editPole(p),
          onToggle: () => _toggleActif('institutions_poles_officiels', p),
          onDelete: () => _confirmDelete('institutions_poles_officiels', p, 'pôle'),
        );
      },
    );
  }

  // ===========================================================================
  // SOUS-TAB 4 : GRADES
  // ===========================================================================
  Widget _listeGrades() {
    if (_grades.isEmpty) return _emptyState('Aucun grade');

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _grades.length + 1,
      itemBuilder: (c, i) {
        if (i == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _actionBtn(
              Icons.add_circle,
              'Nouveau grade',
              _C.vert,
              () => _editGrade(null),
            ),
          );
        }
        final g = _grades[i - 1];
        return _itemCard(
          badge: '${g['numero']}',
          title: '${g['grade']}',
          subtitle: '${g['etape_parcours'] ?? ''}',
          badgeColor: _C.vert,
          actif: g['actif'] == true,
          onEdit: () => _editGrade(g),
          onToggle: () => _toggleActif('institutions_grades', g),
          onDelete: () => _confirmDelete('institutions_grades', g, 'grade'),
        );
      },
    );
  }

  // ===========================================================================
  // WIDGETS RÉUTILISABLES
  // ===========================================================================
  Widget _itemCard({
    required String badge,
    required String title,
    required String subtitle,
    required Color badgeColor,
    required bool actif,
    required VoidCallback onEdit,
    required VoidCallback onToggle,
    required VoidCallback onDelete,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _C.nuit2,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: actif ? badgeColor.withOpacity(0.3) : Colors.white12,
        ),
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
                  color: badgeColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  badge,
                  style: TextStyle(
                    color: badgeColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (!actif)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: _C.rouge.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'INACTIF',
                    style: TextStyle(
                      color: _C.rouge,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 11,
              height: 1.3,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _actionBtn(Icons.edit, 'Éditer', _C.or, onEdit),
              const SizedBox(width: 8),
              _actionBtn(
                actif ? Icons.visibility_off : Icons.visibility,
                actif ? 'Désactiver' : 'Activer',
                Colors.white70,
                onToggle,
              ),
              const Spacer(),
              _actionBtn(Icons.delete_forever, 'Supprimer', _C.rouge, onDelete),
            ],
          ),
        ],
      ),
    );
  }

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

  Widget _emptyState(String msg) {
    return Center(
      child: Text(msg,
          style: const TextStyle(color: Colors.white54, fontSize: 13)),
    );
  }

  // ===========================================================================
  // FORMULAIRE SECTION
  // ===========================================================================
  void _editSection(Map<String, dynamic>? s) {
    final isNew = s == null;
    final codeCtrl = TextEditingController(text: isNew ? '' : '${s['code']}');
    final titreCtrl = TextEditingController(text: isNew ? '' : '${s['titre']}');
    final sousTitreCtrl = TextEditingController(text: isNew ? '' : '${s['sous_titre'] ?? ''}');
    final contenuCtrl = TextEditingController(text: isNew ? '' : '${s['contenu'] ?? ''}');
    final ordreCtrl = TextEditingController(text: isNew ? '99' : '${s['numero_ordre']}');

    _showFormDialog(
      title: isNew ? 'Nouvelle section' : 'Éditer la section',
      fields: [
        _formField('Code (identifiant unique)', codeCtrl, enabled: isNew),
        _formField('Titre', titreCtrl),
        _formField('Sous-titre', sousTitreCtrl),
        _formField('Numéro d\'ordre', ordreCtrl, keyboardType: TextInputType.number),
        _formField('Contenu', contenuCtrl, maxLines: 6),
      ],
      onSubmit: () async {
        final data = {
          'code': codeCtrl.text.trim(),
          'titre': titreCtrl.text.trim(),
          'sous_titre': sousTitreCtrl.text.trim(),
          'contenu': contenuCtrl.text.trim(),
          'numero_ordre': int.tryParse(ordreCtrl.text) ?? 99,
          'type': 'texte',
          'version': '1.0',
          'modifie_le': DateTime.now().toIso8601String(),
        };
        await _save('institutions_sections', s?['id'], data, isNew, 'section');
      },
    );
  }

  // ===========================================================================
  // FORMULAIRE NIVEAU
  // ===========================================================================
  void _editNiveau(Map<String, dynamic>? n) {
    final isNew = n == null;
    final numCtrl = TextEditingController(text: isNew ? '' : '${n['numero']}');
    final titreCtrl = TextEditingController(text: isNew ? '' : '${n['titre']}');
    final terrCtrl = TextEditingController(text: isNew ? '' : '${n['territoire']}');
    final instCtrl = TextEditingController(text: isNew ? '' : '${n['instance']}');
    final formeCtrl = TextEditingController(text: isNew ? '' : '${n['forme_descriptive'] ?? ''}');
    final couleurCtrl = TextEditingController(text: isNew ? '#C4952B' : '${n['couleur'] ?? '#C4952B'}');

    _showFormDialog(
      title: isNew ? 'Nouveau niveau' : 'Éditer le niveau',
      fields: [
        _formField('Numéro (1-6)', numCtrl, keyboardType: TextInputType.number),
        _formField('Titre du niveau', titreCtrl),
        _formField('Territoire', terrCtrl),
        _formField('Instance', instCtrl),
        _formField('Forme descriptive', formeCtrl),
        _formField('Couleur (hex)', couleurCtrl),
      ],
      onSubmit: () async {
        final data = {
          'numero': int.tryParse(numCtrl.text) ?? 0,
          'titre': titreCtrl.text.trim(),
          'territoire': terrCtrl.text.trim(),
          'instance': instCtrl.text.trim(),
          'forme_descriptive': formeCtrl.text.trim(),
          'couleur': couleurCtrl.text.trim(),
          'version': '1.0',
          'modifie_le': DateTime.now().toIso8601String(),
        };
        await _save('institutions_niveaux', n?['id'], data, isNew, 'niveau');
      },
    );
  }

  // ===========================================================================
  // FORMULAIRE PÔLE
  // ===========================================================================
  void _editPole(Map<String, dynamic>? p) {
    final isNew = p == null;
    final numCtrl = TextEditingController(text: isNew ? '' : '${p['numero']}');
    final nomCtrl = TextEditingController(text: isNew ? '' : '${p['nom']}');
    final instCtrl = TextEditingController(text: isNew ? '' : '${p['institutions_rattachees'] ?? ''}');
    final icoCtrl = TextEditingController(text: isNew ? 'star' : '${p['icone'] ?? 'star'}');

    _showFormDialog(
      title: isNew ? 'Nouveau pôle' : 'Éditer le pôle',
      fields: [
        _formField('Numéro (1-21)', numCtrl, keyboardType: TextInputType.number),
        _formField('Nom du pôle', nomCtrl),
        _formField('Institutions rattachées', instCtrl),
        _formField('Icône (nom Material)', icoCtrl),
      ],
      onSubmit: () async {
        final data = {
          'numero': int.tryParse(numCtrl.text) ?? 0,
          'nom': nomCtrl.text.trim(),
          'institutions_rattachees': instCtrl.text.trim(),
          'icone': icoCtrl.text.trim(),
          'version': '1.0',
          'modifie_le': DateTime.now().toIso8601String(),
        };
        await _save('institutions_poles_officiels', p?['id'], data, isNew, 'pôle');
      },
    );
  }

  // ===========================================================================
  // FORMULAIRE GRADE
  // ===========================================================================
  void _editGrade(Map<String, dynamic>? g) {
    final isNew = g == null;
    final numCtrl = TextEditingController(text: isNew ? '' : '${g['numero']}');
    final gradeCtrl = TextEditingController(text: isNew ? '' : '${g['grade']}');
    final etapeCtrl = TextEditingController(text: isNew ? '' : '${g['etape_parcours'] ?? ''}');
    final foncCtrl = TextEditingController(text: isNew ? '' : '${g['fonctions_accessibles'] ?? ''}');

    _showFormDialog(
      title: isNew ? 'Nouveau grade' : 'Éditer le grade',
      fields: [
        _formField('Numéro (1-7)', numCtrl, keyboardType: TextInputType.number),
        _formField('Nom du grade', gradeCtrl),
        _formField('Étape du parcours', etapeCtrl),
        _formField('Fonctions accessibles', foncCtrl),
      ],
      onSubmit: () async {
        final data = {
          'numero': int.tryParse(numCtrl.text) ?? 0,
          'grade': gradeCtrl.text.trim(),
          'etape_parcours': etapeCtrl.text.trim(),
          'fonctions_accessibles': foncCtrl.text.trim(),
          'version': '1.0',
          'modifie_le': DateTime.now().toIso8601String(),
        };
        await _save('institutions_grades', g?['id'], data, isNew, 'grade');
      },
    );
  }

  // ===========================================================================
  // DIALOG FORMULAIRE GÉNÉRIQUE
  // ===========================================================================
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
          width: 500,
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
    bool enabled = true,
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
            enabled: enabled,
            style: TextStyle(
                color: enabled ? Colors.white : Colors.white38,
                fontSize: 13),
            decoration: InputDecoration(
              filled: true,
              fillColor: enabled ? _C.nuit3 : _C.nuit3.withOpacity(0.5),
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

  // ===========================================================================
  // SAUVEGARDER (CREATE ou UPDATE)
  // ===========================================================================
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

  // ===========================================================================
  // TOGGLE ACTIF
  // ===========================================================================
  Future<void> _toggleActif(String table, Map<String, dynamic> item) async {
    try {
      final newValue = item['actif'] != true;
      await _db.from(table).update({
        'actif': newValue,
        'modifie_le': DateTime.now().toIso8601String(),
      }).eq('id', item['id']);

      await _logEdit(table, item['id'], 'update', item, {'actif': newValue});
      await _load();
      _toast(newValue ? 'Activé' : 'Désactivé');
    } catch (e) {
      _toast('Erreur : $e', rouge: true);
    }
  }

  // ===========================================================================
  // SUPPRESSION (soft delete)
  // ===========================================================================
  void _confirmDelete(String table, Map<String, dynamic> item, String label) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _C.nuit2,
        title: Text('Désactiver ce $label ?',
            style: _serif(16, color: Colors.white)),
        content: Text(
          'L\'élément sera désactivé (soft delete). Tu pourras le réactiver plus tard.',
          style: const TextStyle(color: Colors.white70, fontSize: 13),
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
              await _toggleActif(table, {'id': item['id'], 'actif': true});
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _C.rouge,
              foregroundColor: Colors.white,
            ),
            child: const Text('Désactiver'),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // LOG D'ÉDITION
  // ===========================================================================
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

  // ===========================================================================
  // TOAST
  // ===========================================================================
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
