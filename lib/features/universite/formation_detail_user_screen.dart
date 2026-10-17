import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../widgets/app_scaffold.dart';

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

class FormationDetailUserScreen extends StatefulWidget {
  final Map<String, dynamic> formation;
  const FormationDetailUserScreen({super.key, required this.formation});

  @override
  State<FormationDetailUserScreen> createState() =>
      _FormationDetailUserScreenState();
}

class _FormationDetailUserScreenState extends State<FormationDetailUserScreen> {
  bool _loading = true;
  late Map<String, dynamic> _formation;
  List<Map<String, dynamic>> _modules = [];
  List<Map<String, dynamic>> _sessions = [];
  List<Map<String, dynamic>> _conditions = [];
  int _currentTab = 0;

  SupabaseClient get _db => Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _formation = Map<String, dynamic>.from(widget.formation);
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final modules = await _db
          .from('formations_modules')
          .select()
          .eq('formation_id', _formation['id'])
          .eq('actif', true)
          .order('numero');

      final sessions = await _db
          .from('formations_sessions')
          .select()
          .eq('formation_id', _formation['id'])
          .eq('actif', true)
          .order('date_debut');

      final conditions = await _db
          .from('formations_conditions')
          .select()
          .eq('formation_id', _formation['id'])
          .eq('actif', true)
          .order('ordre');

      setState(() {
        _modules = List<Map<String, dynamic>>.from(modules);
        _sessions = List<Map<String, dynamic>>.from(sessions);
        _conditions = List<Map<String, dynamic>>.from(conditions);
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: '${_formation['titre'] ?? 'Formation'}',
      child: _loading
          ? const Center(child: CircularProgressIndicator(color: _C.or))
          : Column(
              children: [
                _tabBar(),
                Expanded(
                  child: IndexedStack(
                    index: _currentTab,
                    children: [
                      _tabInfos(),
                      _tabProgramme(),
                      _tabSessions(),
                      _tabConditions(),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  // ===========================================================================
  // TAB BAR
  // ===========================================================================
  Widget _tabBar() {
    return Container(
      color: _C.nuit2,
      child: Row(
        children: [
          _tabBtn(0, Icons.info, 'Infos'),
          _tabBtn(1, Icons.book, 'Programme (${_modules.length})'),
          _tabBtn(2, Icons.calendar_today, 'Sessions (${_sessions.length})'),
          _tabBtn(3, Icons.checklist, 'Conditions'),
        ],
      ),
    );
  }

  Widget _tabBtn(int index, IconData icon, String label) {
    final sel = _currentTab == index;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _currentTab = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: sel ? _C.nuit3 : Colors.transparent,
            border: Border(
              bottom: BorderSide(
                color: sel ? _C.or : Colors.transparent,
                width: 3,
              ),
            ),
          ),
          child: Column(
            children: [
              Icon(icon, color: sel ? _C.or : Colors.white54, size: 18),
              const SizedBox(height: 2),
              Text(label,
                  style: TextStyle(
                      color: sel ? _C.or : Colors.white54,
                      fontSize: 9,
                      fontWeight: FontWeight.w700),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1),
            ],
          ),
        ),
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
        _header(),
        const SizedBox(height: 20),

        // Description
        if (_formation['description'] != null &&
            '${_formation['description']}'.isNotEmpty) ...[
          _sectionTitle('📋 DESCRIPTION'),
          const SizedBox(height: 10),
          _textCard('${_formation['description']}'),
          const SizedBox(height: 20),
        ],

        // Certification
        if (_formation['certification_titre'] != null) ...[
          _sectionTitle('🏆 CERTIFICATION'),
          const SizedBox(height: 10),
          _certifCard(),
          const SizedBox(height: 20),
        ],

        // Coach IA
        if (_formation['coach_ia_nom'] != null) ...[
          _sectionTitle('🤖 COACH IA'),
          const SizedBox(height: 10),
          _coachCard(),
        ],
      ],
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
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.2),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '${_formation['code'] ?? ''}',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w900),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '${_formation['titre']}',
            style: _serif(22, color: Colors.black, weight: FontWeight.w900),
          ),
          if (_formation['sous_titre'] != null) ...[
            const SizedBox(height: 4),
            Text(
              '${_formation['sous_titre']}',
              style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 13,
                  fontStyle: FontStyle.italic),
            ),
          ],
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _badge(Icons.schedule, '${_formation['duree_heures'] ?? 0} h'),
              _badge(Icons.money, '${_formation['prix_fcfa'] ?? 5000} FCFA'),
              _badge(Icons.trending_up, '${_formation['niveau'] ?? 'Débutant'}'),
              _badge(Icons.computer,
                  '${_formation['modalite'] == 'en_ligne' ? 'En ligne' : 'Présentiel'}'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _badge(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.black87, size: 12),
          const SizedBox(width: 4),
          Text(label,
              style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 11,
                  fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _textCard(String text) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _C.nuit2,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: Text(text,
          style: const TextStyle(
              color: Colors.white70, fontSize: 13, height: 1.6)),
    );
  }

  Widget _certifCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_C.or.withOpacity(0.15), _C.or.withOpacity(0.05)],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _C.or.withOpacity(0.5), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(
                    color: _C.or, shape: BoxShape.circle),
                child: const Icon(Icons.workspace_premium,
                    color: Colors.black, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '${_formation['certification_titre']}',
                  style: _serif(16, color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (_formation['certification_organisme'] != null)
            _infoLine('Organisme', '${_formation['certification_organisme']}'),
          if (_formation['certification_validite'] != null)
            _infoLine('Validité', '${_formation['certification_validite']}'),
        ],
      ),
    );
  }

  Widget _coachCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _C.nuit2,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _C.violet.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _C.violet.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.smart_toy,
                    color: _C.violet, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_formation['coach_ia_nom']}',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w700),
                    ),
                    if (_formation['coach_ia_personnalite'] != null)
                      Text(
                        '${_formation['coach_ia_personnalite']}',
                        style: const TextStyle(
                            color: Colors.white54, fontSize: 11),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Ton coach IA t\'accompagne à chaque étape du parcours : explications, exercices, corrections et évaluations adaptées à ton rythme.',
            style: TextStyle(
                color: Colors.white70, fontSize: 12, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _infoLine(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          SizedBox(
            width: 90,
            child: Text('$label :',
                style: const TextStyle(
                    color: Colors.white54, fontSize: 11)),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(
                    color: Colors.white70, fontSize: 11)),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // TAB 2 : PROGRAMME
  // ===========================================================================
  Widget _tabProgramme() {
    if (_modules.isEmpty) {
      return const Center(
        child: Text('Programme à venir',
            style: TextStyle(color: Colors.white54, fontSize: 13)),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _sectionTitle('📚 PROGRAMME · ${_modules.length} MODULES'),
        const SizedBox(height: 10),
        ..._modules.map(_moduleCard),
      ],
    );
  }

  Widget _moduleCard(Map<String, dynamic> m) {
    final numero = m['numero'] ?? 0;
    final titre = m['titre'] ?? 'Module $numero';
    final sousTitre = m['sous_titre'] ?? '';
    final description = m['description'] ?? '';
    final duree = m['duree_heures'] ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _C.nuit2,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _C.or.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                    color: _C.or, shape: BoxShape.circle),
                child: Center(
                  child: Text('$numero',
                      style: const TextStyle(
                          color: Colors.black,
                          fontSize: 15,
                          fontWeight: FontWeight.w900)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Module $numero',
                        style: const TextStyle(
                            color: _C.or,
                            fontSize: 10,
                            letterSpacing: 1.5,
                            fontWeight: FontWeight.w900)),
                    Text(titre,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w700)),
                    if (sousTitre.isNotEmpty)
                      Text(sousTitre,
                          style: const TextStyle(
                              color: Colors.white54, fontSize: 11)),
                  ],
                ),
              ),
              Text('$duree h',
                  style: const TextStyle(
                      color: _C.orClair,
                      fontSize: 12,
                      fontWeight: FontWeight.bold)),
            ],
          ),
          if (description.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(description,
                style: const TextStyle(
                    color: Colors.white70, fontSize: 12, height: 1.5),
                maxLines: 3,
                overflow: TextOverflow.ellipsis),
          ],
        ],
      ),
    );
  }

  // ===========================================================================
  // TAB 3 : SESSIONS
  // ===========================================================================
  Widget _tabSessions() {
    if (_sessions.isEmpty) {
      return const Center(
        child: Text('Aucune session planifiée',
            style: TextStyle(color: Colors.white54, fontSize: 13)),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _sectionTitle('📅 SESSIONS PLANIFIÉES'),
        const SizedBox(height: 10),
        ..._sessions.map(_sessionCard),
      ],
    );
  }

  Widget _sessionCard(Map<String, dynamic> s) {
    final statut = '${s['statut']}';
    Color statutColor;
    switch (statut) {
      case 'ouvert':
        statutColor = _C.vert;
        break;
      case 'complet':
        statutColor = _C.rouge;
        break;
      case 'en_cours':
        statutColor = _C.or;
        break;
      default:
        statutColor = _C.violet;
    }

    final dateDebut = s['date_debut']?.toString().substring(0, 10) ?? '';
    final dateFin = s['date_fin']?.toString().substring(0, 10) ?? '';
    final placesRest = s['places_restantes'] ?? 0;
    final placesMax = s['places_max'] ?? 0;
    final rythme = s['rythme'] ?? 'libre';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _C.nuit2,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statutColor.withOpacity(0.4), width: 2),
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
                        fontSize: 15,
                        fontWeight: FontWeight.w700)),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statutColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(statut.toUpperCase(),
                    style: TextStyle(
                        color: statutColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w900)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.calendar_today,
                  color: Colors.white38, size: 12),
              const SizedBox(width: 4),
              Text('$dateDebut → $dateFin',
                  style: const TextStyle(
                      color: Colors.white54, fontSize: 11)),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.people, color: Colors.white38, size: 12),
              const SizedBox(width: 4),
              Text('$placesRest / $placesMax places · $rythme',
                  style: const TextStyle(
                      color: Colors.white54, fontSize: 11)),
            ],
          ),
          if (statut == 'ouvert') ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _inscrireSession(s),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _C.vert,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('S\'INSCRIRE À CETTE SESSION',
                    style: TextStyle(
                        fontWeight: FontWeight.w900, fontSize: 12)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ===========================================================================
  // TAB 4 : CONDITIONS
  // ===========================================================================
  Widget _tabConditions() {
    if (_conditions.isEmpty) {
      return const Center(
        child: Text('Aucune condition particulière',
            style: TextStyle(color: Colors.white54, fontSize: 13)),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _sectionTitle('✅ CONDITIONS D\'INSCRIPTION'),
        const SizedBox(height: 10),
        ..._conditions.map(_conditionTile),
      ],
    );
  }

  Widget _conditionTile(Map<String, dynamic> c) {
    final obligatoire = c['obligatoire'] == true;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _C.nuit2,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: obligatoire
              ? _C.vert.withOpacity(0.3)
              : Colors.white12,
        ),
      ),
      child: Row(
        children: [
          Icon(
            obligatoire ? Icons.check_circle : Icons.info_outline,
            color: obligatoire ? _C.vert : Colors.white54,
            size: 20,
          ),
          const SizedBox(width: 12),
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
          if (obligatoire)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: _C.vert.withOpacity(0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text('REQUIS',
                  style: TextStyle(
                      color: _C.vert,
                      fontSize: 9,
                      fontWeight: FontWeight.w900)),
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
        fontSize: 12,
        letterSpacing: 2,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  // ===========================================================================
  // INSCRIPTION SESSION
  // ===========================================================================
  void _inscrireSession(Map<String, dynamic> s) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _C.nuit2,
        title: Text('S\'inscrire à ${s['nom_cohorte']}',
            style: _serif(16, color: Colors.white)),
        content: const Text(
          'Pour confirmer ton inscription, tu seras redirigé vers le paiement. Le tarif solidaire est disponible pour les personnes à faibles revenus.',
          style: TextStyle(
              color: Colors.white70, fontSize: 13, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler',
                style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _toast('Inscription bientôt disponible');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _C.or,
              foregroundColor: Colors.black,
            ),
            child: const Text('Continuer',
                style: TextStyle(fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
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
