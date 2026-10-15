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

class AdminEcoTab extends StatefulWidget {
  const AdminEcoTab({super.key});
  @override
  State<AdminEcoTab> createState() => _AdminEcoTabState();
}

class _AdminEcoTabState extends State<AdminEcoTab>
    with TickerProviderStateMixin {
  late final TabController _subTabCtrl;
  bool _loading = true;

  List<Map<String, dynamic>> _sections = [];
  List<Map<String, dynamic>> _sources = [];
  List<Map<String, dynamic>> _flux = [];
  List<Map<String, dynamic>> _previsions = [];

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
          .from('modele_eco_sections')
          .select()
          .order('numero_ordre');
      final sources = await _db
          .from('modele_eco_sources_revenus')
          .select()
          .order('numero');
      final flux = await _db
          .from('modele_eco_flux_federaux')
          .select()
          .order('ordre');
      final previsions = await _db
          .from('modele_eco_previsions')
          .select()
          .order('ordre');

      setState(() {
        _sections = List<Map<String, dynamic>>.from(sections);
        _sources = List<Map<String, dynamic>>.from(sources);
        _flux = List<Map<String, dynamic>>.from(flux);
        _previsions = List<Map<String, dynamic>>.from(previsions);
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

    return Column(
      children: [
        _header(),
        Container(
          color: _C.nuit3,
          child: TabBar(
            controller: _subTabCtrl,
            isScrollable: true,
            indicatorColor: _C.vert,
            labelColor: _C.vert,
            unselectedLabelColor: Colors.white54,
            labelStyle: const TextStyle(
                fontSize: 11, fontWeight: FontWeight.bold),
            tabs: const [
              Tab(text: 'Sections', icon: Icon(Icons.article, size: 16)),
              Tab(text: 'Revenus', icon: Icon(Icons.attach_money, size: 16)),
              Tab(text: 'Flux', icon: Icon(Icons.account_balance, size: 16)),
              Tab(text: 'Prévisions', icon: Icon(Icons.trending_up, size: 16)),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _subTabCtrl,
            children: [
              _listeSections(),
              _listeSources(),
              _listeFlux(),
              _listePrevisions(),
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
              color: _C.vert.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.diamond, color: _C.vert, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Modèle économique', style: _serif(18)),
                Text(
                  '${_sections.length} sections · ${_sources.length} sources · ${_flux.length} flux · ${_previsions.length} prévisions',
                  style: const TextStyle(
                      color: Colors.white54, fontSize: 11),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: _C.vert),
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
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _sections.length + 1,
      itemBuilder: (c, i) {
        if (i == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _actionBtn(Icons.add_circle, 'Nouvelle section', _C.vert,
                () => _editSection(null)),
          );
        }
        final s = _sections[i - 1];
        return _itemCard(
          badge: '${s['numero_ordre'] ?? '-'}',
          title: '${s['titre']}',
          subtitle: '${s['sous_titre'] ?? ''}',
          badgeColor: _C.vert,
          actif: s['actif'] == true,
          onEdit: () => _editSection(s),
          onToggle: () => _toggleActif('modele_eco_sections', s),
          onDelete: () => _confirmDelete('modele_eco_sections', s, 'section'),
        );
      },
    );
  }

  // ===========================================================================
  // SOUS-TAB 2 : SOURCES DE REVENUS
  // ===========================================================================
  Widget _listeSources() {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _sources.length + 1,
      itemBuilder: (c, i) {
        if (i == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _actionBtn(Icons.add_circle, 'Nouvelle source', _C.vert,
                () => _editSource(null)),
          );
        }
        final s = _sources[i - 1];
        return _itemCard(
          badge: '${s['numero']}',
          title: '${s['produit']}',
          subtitle: '${s['qui_paie'] ?? ''} · ${s['prix_reference'] ?? ''}',
          badgeColor: _C.or,
          actif: s['actif'] == true,
          onEdit: () => _editSource(s),
          onToggle: () => _toggleActif('modele_eco_sources_revenus', s),
          onDelete: () =>
              _confirmDelete('modele_eco_sources_revenus', s, 'source'),
        );
      },
    );
  }

  // ===========================================================================
  // SOUS-TAB 3 : FLUX FÉDÉRAUX
  // ===========================================================================
  Widget _listeFlux() {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _flux.length + 1,
      itemBuilder: (c, i) {
        if (i == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _actionBtn(Icons.add_circle, 'Nouveau flux', _C.vert,
                () => _editFlux(null)),
          );
        }
        final f = _flux[i - 1];
        return _itemCard(
          badge: '${f['pourcentage']}%',
          title: '${f['nom']}',
          subtitle: '${f['usage'] ?? ''}',
          badgeColor: _C.violet,
          actif: f['actif'] == true,
          onEdit: () => _editFlux(f),
          onToggle: () => _toggleActif('modele_eco_flux_federaux', f),
          onDelete: () => _confirmDelete('modele_eco_flux_federaux', f, 'flux'),
        );
      },
    );
  }

  // ===========================================================================
  // SOUS-TAB 4 : PRÉVISIONS
  // ===========================================================================
  Widget _listePrevisions() {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _previsions.length + 1,
      itemBuilder: (c, i) {
        if (i == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _actionBtn(Icons.add_circle, 'Nouvelle prévision', _C.vert,
                () => _editPrevision(null)),
          );
        }
        final p = _previsions[i - 1];
        return _itemCard(
          badge: '${p['annee_1'] ?? '-'}',
          title: '${p['poste']}',
          subtitle:
              'An 1: ${p['annee_1']} · An 2: ${p['annee_2']} · An 3: ${p['annee_3']}',
          badgeColor: _C.teal,
          actif: p['actif'] == true,
          onEdit: () => _editPrevision(p),
          onToggle: () => _toggleActif('modele_eco_previsions', p),
          onDelete: () => _confirmDelete('modele_eco_previsions', p, 'prévision'),
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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
              _actionBtn(
                  Icons.delete_forever, 'Supprimer', _C.rouge, onDelete),
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

  // ===========================================================================
  // FORMULAIRE SECTION
  // ===========================================================================
  void _editSection(Map<String, dynamic>? s) {
    final isNew = s == null;
    final codeCtrl = TextEditingController(text: isNew ? '' : '${s['code']}');
    final titreCtrl = TextEditingController(text: isNew ? '' : '${s['titre']}');
    final sousTitreCtrl =
        TextEditingController(text: isNew ? '' : '${s['sous_titre'] ?? ''}');
    final contenuCtrl =
        TextEditingController(text: isNew ? '' : '${s['contenu'] ?? ''}');
    final ordreCtrl =
        TextEditingController(text: isNew ? '99' : '${s['numero_ordre']}');

    _showFormDialog(
      title: isNew ? 'Nouvelle section' : 'Éditer la section',
      fields: [
        _formField('Code unique', codeCtrl, enabled: isNew),
        _formField('Titre', titreCtrl),
        _formField('Sous-titre', sousTitreCtrl),
        _formField('Ordre', ordreCtrl, keyboardType: TextInputType.number),
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
        await _save('modele_eco_sections', s?['id'], data, isNew, 'section');
      },
    );
  }

  // ===========================================================================
  // FORMULAIRE SOURCE DE REVENUS
  // ===========================================================================
  void _editSource(Map<String, dynamic>? s) {
    final isNew = s == null;
    final numCtrl = TextEditingController(text: isNew ? '' : '${s['numero']}');
    final produitCtrl = TextEditingController(text: isNew ? '' : '${s['produit']}');
    final quiCtrl = TextEditingController(text: isNew ? '' : '${s['qui_paie']}');
    final prixCtrl =
        TextEditingController(text: isNew ? '' : '${s['prix_reference'] ?? ''}');
    final livreCtrl =
        TextEditingController(text: isNew ? '' : '${s['ce_qui_est_livre'] ?? ''}');

    _showFormDialog(
      title: isNew ? 'Nouvelle source de revenus' : 'Éditer la source',
      fields: [
        _formField('Numéro', numCtrl, keyboardType: TextInputType.number),
        _formField('Produit', produitCtrl),
        _formField('Qui paie', quiCtrl),
        _formField('Prix de référence', prixCtrl),
        _formField('Ce qui est livré', livreCtrl),
      ],
      onSubmit: () async {
        final data = {
          'numero': int.tryParse(numCtrl.text) ?? 0,
          'produit': produitCtrl.text.trim(),
          'qui_paie': quiCtrl.text.trim(),
          'prix_reference': prixCtrl.text.trim(),
          'ce_qui_est_livre': livreCtrl.text.trim(),
          'version': '1.0',
          'modifie_le': DateTime.now().toIso8601String(),
        };
        await _save('modele_eco_sources_revenus', s?['id'], data, isNew, 'source');
      },
    );
  }

  // ===========================================================================
  // FORMULAIRE FLUX FÉDÉRAL
  // ===========================================================================
  void _editFlux(Map<String, dynamic>? f) {
    final isNew = f == null;
    final codeCtrl = TextEditingController(text: isNew ? '' : '${f['code']}');
    final nomCtrl = TextEditingController(text: isNew ? '' : '${f['nom']}');
    final pctCtrl = TextEditingController(text: isNew ? '' : '${f['pourcentage']}');
    final usageCtrl = TextEditingController(text: isNew ? '' : '${f['usage'] ?? ''}');
    final couleurCtrl =
        TextEditingController(text: isNew ? '#0F7A3D' : '${f['couleur'] ?? '#0F7A3D'}');

    _showFormDialog(
      title: isNew ? 'Nouveau flux' : 'Éditer le flux',
      fields: [
        _formField('Code unique', codeCtrl, enabled: isNew),
        _formField('Nom', nomCtrl),
        _formField('Pourcentage', pctCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true)),
        _formField('Usage', usageCtrl, maxLines: 3),
        _formField('Couleur (hex)', couleurCtrl),
      ],
      onSubmit: () async {
        final data = {
          'code': codeCtrl.text.trim(),
          'nom': nomCtrl.text.trim(),
          'pourcentage': double.tryParse(pctCtrl.text) ?? 0,
          'usage': usageCtrl.text.trim(),
          'couleur': couleurCtrl.text.trim(),
          'version': '1.0',
          'modifie_le': DateTime.now().toIso8601String(),
        };
        await _save('modele_eco_flux_federaux', f?['id'], data, isNew, 'flux');
      },
    );
  }

  // ===========================================================================
  // FORMULAIRE PRÉVISION
  // ===========================================================================
  void _editPrevision(Map<String, dynamic>? p) {
    final isNew = p == null;
    final posteCtrl = TextEditingController(text: isNew ? '' : '${p['poste']}');
    final an1Ctrl = TextEditingController(text: isNew ? '0' : '${p['annee_1'] ?? 0}');
    final an2Ctrl = TextEditingController(text: isNew ? '0' : '${p['annee_2'] ?? 0}');
    final an3Ctrl = TextEditingController(text: isNew ? '0' : '${p['annee_3'] ?? 0}');
    final typeCtrl = TextEditingController(text: isNew ? 'recette' : '${p['type'] ?? 'recette'}');
    final ordreCtrl = TextEditingController(text: isNew ? '99' : '${p['ordre'] ?? 99}');

    _showFormDialog(
      title: isNew ? 'Nouvelle prévision' : 'Éditer la prévision',
      fields: [
        _formField('Poste', posteCtrl),
        _formField('Année 1', an1Ctrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true)),
        _formField('Année 2', an2Ctrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true)),
        _formField('Année 3', an3Ctrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true)),
        _formField('Type (recette/charge/total/ratio)', typeCtrl),
        _formField('Ordre', ordreCtrl, keyboardType: TextInputType.number),
      ],
      onSubmit: () async {
        final data = {
          'poste': posteCtrl.text.trim(),
          'annee_1': double.tryParse(an1Ctrl.text) ?? 0,
          'annee_2': double.tryParse(an2Ctrl.text) ?? 0,
          'annee_3': double.tryParse(an3Ctrl.text) ?? 0,
          'type': typeCtrl.text.trim(),
          'ordre': int.tryParse(ordreCtrl.text) ?? 99,
          'version': '1.0',
          'modifie_le': DateTime.now().toIso8601String(),
        };
        await _save('modele_eco_previsions', p?['id'], data, isNew, 'prévision');
      },
    );
  }

  // ===========================================================================
  // DIALOG FORMULAIRE
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
  // SAUVEGARDER
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
  // LOG
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
