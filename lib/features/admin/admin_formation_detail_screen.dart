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

class AdminFormationDetailScreen extends StatefulWidget {
  final Map<String, dynamic> formation;
  const AdminFormationDetailScreen({super.key, required this.formation});

  @override
  State<AdminFormationDetailScreen> createState() =>
      _AdminFormationDetailScreenState();
}

class _AdminFormationDetailScreenState
    extends State<AdminFormationDetailScreen>
    with TickerProviderStateMixin {
  late final TabController _tabCtrl;
  bool _loading = true;

  late Map<String, dynamic> _formation;
  List<Map<String, dynamic>> _modules = [];
  List<Map<String, dynamic>> _ressources = [];
  List<Map<String, dynamic>> _evaluations = [];
  List<Map<String, dynamic>> _sessions = [];
  List<Map<String, dynamic>> _conditions = [];

  SupabaseClient get _db => Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _formation = Map<String, dynamic>.from(widget.formation);
    _tabCtrl = TabController(length: 5, vsync: this);
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
      final fid = _formation['id'];

      // Rafraîchir la formation
      final f = await _db
          .from('formations')
          .select()
          .eq('id', fid)
          .maybeSingle();
      if (f != null) _formation = f;

      final modules = await _db
          .from('formations_modules')
          .select()
          .eq('formation_id', fid)
          .order('numero');
      final ressources = await _db
          .from('formations_ressources')
          .select()
          .eq('formation_id', fid)
          .order('ordre');
      final evaluations = await _db
          .from('formations_evaluations')
          .select()
          .eq('formation_id', fid)
          .order('ordre');
      final sessions = await _db
          .from('formations_sessions')
          .select()
          .eq('formation_id', fid)
          .order('date_debut', ascending: false);
      final conditions = await _db
          .from('formations_conditions')
          .select()
          .eq('formation_id', fid)
          .order('ordre');

      setState(() {
        _modules = List<Map<String, dynamic>>.from(modules);
        _ressources = List<Map<String, dynamic>>.from(ressources);
        _evaluations = List<Map<String, dynamic>>.from(evaluations);
        _sessions = List<Map<String, dynamic>>.from(sessions);
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
          '${_formation['code'] ?? ''} · ${_formation['titre'] ?? ''}',
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
                text: 'Modules (${_modules.length})',
                icon: const Icon(Icons.book, size: 16)),
            Tab(
                text: 'Ressources (${_ressources.length})',
                icon: const Icon(Icons.attach_file, size: 16)),
            Tab(
                text: 'Évaluations (${_evaluations.length})',
                icon: const Icon(Icons.quiz, size: 16)),
            Tab(
                text: 'Sessions (${_sessions.length})',
                icon: const Icon(Icons.calendar_today, size: 16)),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _C.or))
          : TabBarView(
              controller: _tabCtrl,
              children: [
                _tabInfos(),
                _tabModules(),
                _tabRessources(),
                _tabEvaluations(),
                _tabSessions(),
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
        _infoCard('Titre', '${_formation['titre'] ?? ''}', Icons.title, _C.or),
        _infoCard('Code', '${_formation['code'] ?? ''}', Icons.qr_code, _C.or),
        _infoCard('Sous-titre', '${_formation['sous_titre'] ?? ''}',
            Icons.subtitles, _C.or),
        _infoCard('Description', '${_formation['description'] ?? ''}',
            Icons.description, _C.or),
        _infoCard(
            'Prix', '${_formation['prix_fcfa'] ?? 5000} FCFA', Icons.money, _C.vert),
        _infoCard(
            'Durée', '${_formation['duree_heures'] ?? 40} h', Icons.schedule, _C.or),
        _infoCard('Niveau', '${_formation['niveau'] ?? 'debutant'}',
            Icons.trending_up, _C.violet),
        _infoCard('Modalité', '${_formation['modalite'] ?? 'en_ligne'}',
            Icons.computer, _C.teal),
        _infoCard('Coach IA', '${_formation['coach_ia_nom'] ?? 'Coach Baobab'}',
            Icons.smart_toy, _C.violet),
        _infoCard('Personnalité IA',
            '${_formation['coach_ia_personnalite'] ?? ''}', Icons.psychology, _C.violet),
        _infoCard('Prérequis étape',
            '${_formation['prerequis_etape'] ?? 1}', Icons.lock, _C.rouge),
        _infoCard('Certification', '${_formation['certification_titre'] ?? ''}',
            Icons.workspace_premium, _C.or),
        _infoCard('Organisme certifiant',
            '${_formation['certification_organisme'] ?? ''}', Icons.verified, _C.vert),
        _infoCard('Validité', '${_formation['certification_validite'] ?? ''}',
            Icons.timer, _C.or),
        const SizedBox(height: 20),
        _sectionTitle('CONDITIONS D\'INSCRIPTION'),
        const SizedBox(height: 10),
        ..._conditions.map(_conditionTile),
        const SizedBox(height: 12),
        _actionBtn(Icons.add_circle, 'Nouvelle condition', _C.vert,
            () => _editCondition(null)),
        const SizedBox(height: 20),
        _actionBtn(Icons.edit, 'Éditer les infos de la formation', _C.or,
            () => _editFormation()),
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

  Widget _conditionTile(Map<String, dynamic> c) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(10),
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
            size: 16,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${c['titre']}',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
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
  // TAB 2 : MODULES
  // ===========================================================================
  Widget _tabModules() {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _modules.length + 1,
      itemBuilder: (c, i) {
        if (i == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _actionBtn(Icons.add_circle, 'Nouveau module', _C.vert,
                () => _editModule(null)),
          );
        }
        final m = _modules[i - 1];
        final ressourcesModule = _ressources
            .where((r) => r['module_id'] == m['id'])
            .length;
        final evalsModule = _evaluations
            .where((e) => e['module_id'] == m['id'])
            .length;

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
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _C.or.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Module ${m['numero']}',
                      style: const TextStyle(
                          color: _C.or,
                          fontSize: 11,
                          fontWeight: FontWeight.w900),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${m['duree_heures'] ?? 0} h',
                    style: const TextStyle(
                        color: _C.orClair,
                        fontSize: 11,
                        fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text('${m['titre']}',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700)),
              if (m['sous_titre'] != null && '${m['sous_titre']}'.isNotEmpty)
                Text('${m['sous_titre']}',
                    style: const TextStyle(
                        color: Colors.white54, fontSize: 11)),
              if (m['description'] != null &&
                  '${m['description']}'.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text('${m['description']}',
                    style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        height: 1.4),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
              ],
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  _chipBadge('$ressourcesModule ressources', _C.teal),
                  _chipBadge('$evalsModule éval.', _C.violet),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  _actionBtn(Icons.edit, 'Éditer', _C.or,
                      () => _editModule(m)),
                  const SizedBox(width: 6),
                  _actionBtn(
                      Icons.delete, 'Suppr.', _C.rouge,
                      () => _deleteModule(m)),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _chipBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(text,
          style: TextStyle(
              color: color, fontSize: 10, fontWeight: FontWeight.w600)),
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
      case 'image':
        icon = Icons.image;
        color = _C.teal;
        break;
      default:
        icon = Icons.link;
        color = _C.vert;
    }

    final module = _modules.firstWhere(
      (m) => m['id'] == r['module_id'],
      orElse: () => {},
    );
    final moduleLabel = module.isNotEmpty
        ? 'Module ${module['numero']}'
        : 'Général';

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
                Text('$type · $moduleLabel',
                    style: const TextStyle(
                        color: Colors.white54, fontSize: 10)),
                if (r['url'] != null && '${r['url']}'.isNotEmpty)
                  Text('${r['url']}',
                      style: const TextStyle(
                          color: _C.orClair, fontSize: 9),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
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
  // TAB 4 : ÉVALUATIONS
  // ===========================================================================
  Widget _tabEvaluations() {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        _actionBtn(Icons.add_circle, 'Nouvelle évaluation', _C.vert,
            () => _editEvaluation(null)),
        const SizedBox(height: 12),
        if (_evaluations.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(40),
              child: Text('Aucune évaluation',
                  style: TextStyle(color: Colors.white54, fontSize: 13)),
            ),
          )
        else
          ..._evaluations.map(_evaluationTile),
      ],
    );
  }

  Widget _evaluationTile(Map<String, dynamic> e) {
    final module = _modules.firstWhere(
      (m) => m['id'] == e['module_id'],
      orElse: () => {},
    );
    final moduleLabel = module.isNotEmpty
        ? 'Module ${module['numero']}'
        : 'Général';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _C.nuit2,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _C.violet.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.quiz, color: _C.violet, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text('${e['titre']}',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w700)),
              ),
              Text('${e['type']}',
                  style: const TextStyle(
                      color: _C.violet,
                      fontSize: 10,
                      fontWeight: FontWeight.w900)),
            ],
          ),
          const SizedBox(height: 6),
          Text('$moduleLabel · ${e['duree_minutes']} min · Seuil ${e['seuil_reussite']}%',
              style: const TextStyle(
                  color: Colors.white54, fontSize: 10)),
          const SizedBox(height: 10),
          Row(
            children: [
              _actionBtn(Icons.edit, 'Éditer', _C.or,
                  () => _editEvaluation(e)),
              const SizedBox(width: 6),
              _actionBtn(Icons.delete, 'Suppr.', _C.rouge,
                  () => _deleteEvaluation(e)),
            ],
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // TAB 5 : SESSIONS
  // ===========================================================================
  Widget _tabSessions() {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        _actionBtn(Icons.add_circle, 'Nouvelle session', _C.vert,
            () => _editSession(null)),
        const SizedBox(height: 12),
        if (_sessions.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(40),
              child: Text('Aucune session',
                  style: TextStyle(color: Colors.white54, fontSize: 13)),
            ),
          )
        else
          ..._sessions.map(_sessionTile),
      ],
    );
  }

  Widget _sessionTile(Map<String, dynamic> s) {
    final statut = '${s['statut']}';
    Color color;
    switch (statut) {
      case 'ouvert':
        color = _C.vert;
        break;
      case 'complet':
        color = _C.rouge;
        break;
      case 'en_cours':
        color = _C.or;
        break;
      case 'termine':
        color = Colors.white54;
        break;
      case 'annule':
        color = _C.rouge;
        break;
      default:
        color = _C.violet;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _C.nuit2,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('${s['nom_cohorte']}',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w700)),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(statut.toUpperCase(),
                    style: TextStyle(
                        color: color,
                        fontSize: 10,
                        fontWeight: FontWeight.w900)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.calendar_today, color: Colors.white38, size: 12),
              const SizedBox(width: 4),
              Text('${s['date_debut']?.toString().substring(0, 10) ?? ''} → ${s['date_fin']?.toString().substring(0, 10) ?? ''}',
                  style: const TextStyle(color: Colors.white54, fontSize: 11)),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.people, color: Colors.white38, size: 12),
              const SizedBox(width: 4),
              Text(
                  '${s['places_restantes'] ?? 0} / ${s['places_max'] ?? 0} places · ${s['rythme'] ?? 'libre'}',
                  style: const TextStyle(color: Colors.white54, fontSize: 11)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _actionBtn(Icons.edit, 'Éditer', _C.or,
                  () => _editSession(s)),
              const SizedBox(width: 6),
              _actionBtn(Icons.delete, 'Suppr.', _C.rouge,
                  () => _deleteSession(s)),
            ],
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // HELPERS
  // ===========================================================================
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

  // ===========================================================================
  // SAUVEGARDER (INSERT ou UPDATE)
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
  // SUPPRESSION (hard delete pour modules/ressources/evals/sessions/conditions)
  // ===========================================================================
  void _confirmDelete(String table, dynamic id, String label) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _C.nuit2,
        title: Text('Supprimer ce $label ?',
            style: _serif(16, color: Colors.white)),
        content: Text(
          'Cette action est IRRÉVERSIBLE. Le $label sera définitivement supprimé.',
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

  // ===========================================================================
  // FORMULAIRE FORMATION (Infos)
  // ===========================================================================
  void _editFormation() {
    final titreCtrl = TextEditingController(text: '${_formation['titre']}');
    final sousTitreCtrl =
        TextEditingController(text: '${_formation['sous_titre'] ?? ''}');
    final descCtrl =
        TextEditingController(text: '${_formation['description'] ?? ''}');
    final prixCtrl =
        TextEditingController(text: '${_formation['prix_fcfa'] ?? 5000}');
    final dureeCtrl =
        TextEditingController(text: '${_formation['duree_heures'] ?? 40}');
    final niveauCtrl =
        TextEditingController(text: '${_formation['niveau'] ?? 'debutant'}');
    final coachNomCtrl = TextEditingController(
        text: '${_formation['coach_ia_nom'] ?? 'Coach Baobab'}');
    final coachPersoCtrl = TextEditingController(
        text: '${_formation['coach_ia_personnalite'] ?? ''}');
    final certTitreCtrl = TextEditingController(
        text: '${_formation['certification_titre'] ?? ''}');
    final certOrgCtrl = TextEditingController(
        text: '${_formation['certification_organisme'] ?? ''}');
    final certValidCtrl = TextEditingController(
        text: '${_formation['certification_validite'] ?? ''}');
    final prereqCtrl =
        TextEditingController(text: '${_formation['prerequis_etape'] ?? 1}');

    _showFormDialog(
      title: 'Éditer la formation',
      fields: [
        _formField('Titre', titreCtrl),
        _formField('Sous-titre', sousTitreCtrl),
        _formField('Description', descCtrl, maxLines: 3),
        _formField('Prix (FCFA)', prixCtrl, keyboardType: TextInputType.number),
        _formField('Durée (heures)', dureeCtrl,
            keyboardType: TextInputType.number),
        _formField('Niveau', niveauCtrl),
        _formField('Coach IA (nom)', coachNomCtrl),
        _formField('Coach IA (personnalité)', coachPersoCtrl, maxLines: 2),
        _formField('Certification (titre)', certTitreCtrl),
        _formField('Certification (organisme)', certOrgCtrl),
        _formField('Certification (validité)', certValidCtrl),
        _formField('Prérequis (étape)', prereqCtrl,
            keyboardType: TextInputType.number),
      ],
      onSubmit: () async {
        final data = {
          'titre': titreCtrl.text.trim(),
          'sous_titre': sousTitreCtrl.text.trim(),
          'description': descCtrl.text.trim(),
          'prix_fcfa': int.tryParse(prixCtrl.text) ?? 5000,
          'duree_heures': int.tryParse(dureeCtrl.text) ?? 40,
          'niveau': niveauCtrl.text.trim(),
          'coach_ia_nom': coachNomCtrl.text.trim(),
          'coach_ia_personnalite': coachPersoCtrl.text.trim(),
          'certification_titre': certTitreCtrl.text.trim(),
          'certification_organisme': certOrgCtrl.text.trim(),
          'certification_validite': certValidCtrl.text.trim(),
          'prerequis_etape': int.tryParse(prereqCtrl.text) ?? 1,
          'modifie_le': DateTime.now().toIso8601String(),
        };
        await _save('formations', _formation['id'], data, false, 'Formation');
      },
    );
  }

  // ===========================================================================
  // FORMULAIRE MODULE
  // ===========================================================================
  void _editModule(Map<String, dynamic>? m) {
    final isNew = m == null;
    final numCtrl = TextEditingController(
        text: isNew ? '${_modules.length + 1}' : '${m['numero']}');
    final titreCtrl = TextEditingController(text: isNew ? '' : '${m['titre']}');
    final sousTitreCtrl =
        TextEditingController(text: isNew ? '' : '${m['sous_titre'] ?? ''}');
    final descCtrl =
        TextEditingController(text: isNew ? '' : '${m['description'] ?? ''}');
    final contenuCtrl =
        TextEditingController(text: isNew ? '' : '${m['contenu_texte'] ?? ''}');
    final dureeCtrl =
        TextEditingController(text: isNew ? '8' : '${m['duree_heures'] ?? 8}');

    _showFormDialog(
      title: isNew ? 'Nouveau module' : 'Éditer le module',
      fields: [
        _formField('Numéro', numCtrl, keyboardType: TextInputType.number),
        _formField('Titre', titreCtrl),
        _formField('Sous-titre', sousTitreCtrl),
        _formField('Description', descCtrl, maxLines: 3),
        _formField('Contenu du cours (texte)', contenuCtrl, maxLines: 8),
        _formField('Durée (heures)', dureeCtrl,
            keyboardType: TextInputType.number),
      ],
      onSubmit: () async {
        final data = {
          'formation_id': _formation['id'],
          'numero': int.tryParse(numCtrl.text) ?? 1,
          'titre': titreCtrl.text.trim(),
          'sous_titre': sousTitreCtrl.text.trim(),
          'description': descCtrl.text.trim(),
          'contenu_texte': contenuCtrl.text.trim(),
          'duree_heures': double.tryParse(dureeCtrl.text) ?? 8,
          'ordre': int.tryParse(numCtrl.text) ?? 1,
          'actif': true,
        };
        await _save('formations_modules', m?['id'], data, isNew, 'Module');
      },
    );
  }

  void _deleteModule(Map<String, dynamic> m) {
    _confirmDelete('formations_modules', m['id'], 'module');
  }

  // ===========================================================================
  // FORMULAIRE RESSOURCE
  // ===========================================================================
  void _editRessource(Map<String, dynamic>? r) {
    final isNew = r == null;
    String type = isNew ? 'video' : '${r['type']}';
    String? moduleId = isNew ? null : r['module_id'] as String?;

    final titreCtrl = TextEditingController(text: isNew ? '' : '${r['titre']}');
    final descCtrl =
        TextEditingController(text: isNew ? '' : '${r['description'] ?? ''}');
    final urlCtrl = TextEditingController(text: isNew ? '' : '${r['url'] ?? ''}');
    final dureeCtrl =
        TextEditingController(text: isNew ? '' : '${r['duree_minutes'] ?? ''}');

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
                      DropdownMenuItem(value: 'video', child: Text('🎬 Vidéo')),
                      DropdownMenuItem(value: 'pdf', child: Text('📄 PDF')),
                      DropdownMenuItem(value: 'audio', child: Text('🎧 Audio')),
                      DropdownMenuItem(value: 'image', child: Text('🖼️ Image')),
                      DropdownMenuItem(value: 'lien', child: Text('🔗 Lien externe')),
                    ],
                    (v) => setS(() => type = v ?? 'video'),
                  ),
                  _dropdownFormField(
                    'Module (facultatif)',
                    moduleId,
                    [
                      const DropdownMenuItem(
                          value: null, child: Text('Général')),
                      ..._modules.map((m) => DropdownMenuItem(
                            value: m['id'] as String,
                            child: Text('Module ${m['numero']} · ${m['titre']}'),
                          )),
                    ],
                    (v) => setS(() => moduleId = v),
                  ),
                  _formField('Titre', titreCtrl),
                  _formField('Description', descCtrl, maxLines: 2),
                  _formField('URL (YouTube, Vimeo, Storage...)', urlCtrl),
                  _formField('Durée (minutes, facultatif)', dureeCtrl,
                      keyboardType: TextInputType.number),
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
                  'formation_id': _formation['id'],
                  'module_id': moduleId,
                  'type': type,
                  'titre': titreCtrl.text.trim(),
                  'description': descCtrl.text.trim(),
                  'url': urlCtrl.text.trim(),
                  'duree_minutes': int.tryParse(dureeCtrl.text),
                  'ordre': 99,
                  'actif': true,
                };
                await _save('formations_ressources', r?['id'], data, isNew,
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
    _confirmDelete('formations_ressources', r['id'], 'ressource');
  }

  // ===========================================================================
  // FORMULAIRE ÉVALUATION
  // ===========================================================================
  void _editEvaluation(Map<String, dynamic>? e) {
    final isNew = e == null;
    String type = isNew ? 'quiz' : '${e['type']}';
    String? moduleId = isNew ? null : e['module_id'] as String?;

    final titreCtrl = TextEditingController(text: isNew ? '' : '${e['titre']}');
    final descCtrl =
        TextEditingController(text: isNew ? '' : '${e['description'] ?? ''}');
    final dureeCtrl =
        TextEditingController(text: isNew ? '30' : '${e['duree_minutes'] ?? 30}');
    final seuilCtrl =
        TextEditingController(text: isNew ? '70' : '${e['seuil_reussite'] ?? 70}');
    final tentCtrl =
        TextEditingController(text: isNew ? '3' : '${e['tentative_max'] ?? 3}');

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          backgroundColor: _C.nuit2,
          titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
          contentPadding: const EdgeInsets.all(20),
          title: Text(
              isNew ? 'Nouvelle évaluation' : 'Éditer l\'évaluation',
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
                      DropdownMenuItem(value: 'quiz', child: Text('📝 Quiz')),
                      DropdownMenuItem(
                          value: 'examen', child: Text('📋 Examen')),
                      DropdownMenuItem(
                          value: 'projet', child: Text('📁 Projet')),
                      DropdownMenuItem(value: 'oral', child: Text('🎤 Oral')),
                    ],
                    (v) => setS(() => type = v ?? 'quiz'),
                  ),
                  _dropdownFormField(
                    'Module (facultatif)',
                    moduleId,
                    [
                      const DropdownMenuItem(
                          value: null, child: Text('Général')),
                      ..._modules.map((m) => DropdownMenuItem(
                            value: m['id'] as String,
                            child: Text('Module ${m['numero']} · ${m['titre']}'),
                          )),
                    ],
                    (v) => setS(() => moduleId = v),
                  ),
                  _formField('Titre', titreCtrl),
                  _formField('Description', descCtrl, maxLines: 2),
                  _formField('Durée (minutes)', dureeCtrl,
                      keyboardType: TextInputType.number),
                  _formField('Seuil de réussite (%)', seuilCtrl,
                      keyboardType: TextInputType.number),
                  _formField('Tentatives max', tentCtrl,
                      keyboardType: TextInputType.number),
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
                  'formation_id': _formation['id'],
                  'module_id': moduleId,
                  'titre': titreCtrl.text.trim(),
                  'type': type,
                  'description': descCtrl.text.trim(),
                  'duree_minutes': int.tryParse(dureeCtrl.text) ?? 30,
                  'seuil_reussite': int.tryParse(seuilCtrl.text) ?? 70,
                  'tentative_max': int.tryParse(tentCtrl.text) ?? 3,
                  'ordre': 99,
                  'actif': true,
                };
                await _save('formations_evaluations', e?['id'], data, isNew,
                    'Évaluation');
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

  void _deleteEvaluation(Map<String, dynamic> e) {
    _confirmDelete('formations_evaluations', e['id'], 'évaluation');
  }

  // ===========================================================================
  // FORMULAIRE SESSION
  // ===========================================================================
  void _editSession(Map<String, dynamic>? s) {
    final isNew = s == null;
    String rythme = isNew ? 'soir' : '${s['rythme'] ?? 'soir'}';
    String statut = isNew ? 'planifie' : '${s['statut'] ?? 'planifie'}';

    final nomCtrl =
        TextEditingController(text: isNew ? '' : '${s['nom_cohorte']}');
    final dateDebutCtrl = TextEditingController(
        text: isNew ? DateTime.now().toIso8601String() : '${s['date_debut'] ?? ''}');
    final dateFinCtrl =
        TextEditingController(text: isNew ? '' : '${s['date_fin'] ?? ''}');
    final placesCtrl = TextEditingController(
        text: isNew ? '30' : '${s['places_max'] ?? 30}');
    final placesRestCtrl = TextEditingController(
        text: isNew ? '30' : '${s['places_restantes'] ?? 30}');
    final formateurCtrl =
        TextEditingController(text: isNew ? '' : '${s['formateur_principal'] ?? ''}');

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          backgroundColor: _C.nuit2,
          titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
          contentPadding: const EdgeInsets.all(20),
          title: Text(isNew ? 'Nouvelle session' : 'Éditer la session',
              style: _serif(16, color: Colors.white)),
          content: SizedBox(
            width: 550,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _formField('Nom de la cohorte', nomCtrl),
                  _formField('Date début (ISO 8601)', dateDebutCtrl),
                  _formField('Date fin (ISO 8601)', dateFinCtrl),
                  _dropdownFormField(
                    'Rythme',
                    rythme,
                    const [
                      DropdownMenuItem(value: 'soir', child: Text('🌙 Soir')),
                      DropdownMenuItem(
                          value: 'weekend', child: Text('📅 Week-end')),
                      DropdownMenuItem(
                          value: 'intensif', child: Text('⚡ Intensif')),
                      DropdownMenuItem(
                          value: 'libre', child: Text('🕐 Libre (à la demande)')),
                    ],
                    (v) => setS(() => rythme = v ?? 'soir'),
                  ),
                  _formField('Places max', placesCtrl,
                      keyboardType: TextInputType.number),
                  _formField('Places restantes', placesRestCtrl,
                      keyboardType: TextInputType.number),
                  _formField('Formateur principal', formateurCtrl),
                  _dropdownFormField(
                    'Statut',
                    statut,
                    const [
                      DropdownMenuItem(
                          value: 'planifie', child: Text('Planifié')),
                      DropdownMenuItem(value: 'ouvert', child: Text('Ouvert')),
                      DropdownMenuItem(value: 'complet', child: Text('Complet')),
                      DropdownMenuItem(
                          value: 'en_cours', child: Text('En cours')),
                      DropdownMenuItem(
                          value: 'termine', child: Text('Terminé')),
                      DropdownMenuItem(value: 'annule', child: Text('Annulé')),
                    ],
                    (v) => setS(() => statut = v ?? 'planifie'),
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
                  'formation_id': _formation['id'],
                  'nom_cohorte': nomCtrl.text.trim(),
                  'date_debut': dateDebutCtrl.text.trim(),
                  'date_fin':
                      dateFinCtrl.text.trim().isEmpty ? null : dateFinCtrl.text.trim(),
                  'rythme': rythme,
                  'places_max': int.tryParse(placesCtrl.text) ?? 30,
                  'places_restantes': int.tryParse(placesRestCtrl.text) ?? 30,
                  'formateur_principal': formateurCtrl.text.trim(),
                  'statut': statut,
                  'actif': true,
                };
                await _save('formations_sessions', s?['id'], data, isNew,
                    'Session');
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

  void _deleteSession(Map<String, dynamic> s) {
    _confirmDelete('formations_sessions', s['id'], 'session');
  }

  // ===========================================================================
  // FORMULAIRE CONDITION
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
                  _formField('Valeur (ex: 18, etape_1)', valeurCtrl),
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
                  'formation_id': _formation['id'],
                  'type': type,
                  'titre': titreCtrl.text.trim(),
                  'description': descCtrl.text.trim(),
                  'valeur': valeurCtrl.text.trim(),
                  'obligatoire': obligatoire,
                  'ordre': 99,
                  'actif': true,
                };
                await _save('formations_conditions', c?['id'], data, isNew,
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
    _confirmDelete('formations_conditions', c['id'], 'condition');
  }
}
