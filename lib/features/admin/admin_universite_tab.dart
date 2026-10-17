import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'admin_ecole_detail_screen.dart';
import 'admin_cursus_detail_screen.dart';
import 'admin_formation_detail_screen.dart';
import 'admin_etape_detail_screen.dart';

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

class AdminUniversiteTab extends StatefulWidget {
  const AdminUniversiteTab({super.key});
  @override
  State<AdminUniversiteTab> createState() => _AdminUniversiteTabState();
}

class _AdminUniversiteTabState extends State<AdminUniversiteTab> {
  bool _loading = true;
  List<Map<String, dynamic>> _ecoles = [];
  List<Map<String, dynamic>> _cursus = [];
  List<Map<String, dynamic>> _formations = [];
  List<Map<String, dynamic>> _etapes = [];
  List<Map<String, dynamic>> _webinaires = [];

  SupabaseClient get _db => Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final ecoles = await _db.from('ecoles').select().order('ordre');
      final cursus = await _db.from('cursus').select().order('ordre');
      final formations = await _db.from('formations').select().order('ordre');
      final etapes = await _db.from('etapes_parcours').select().order('numero');
      final webinaires = await _db
          .from('webinaires')
          .select()
          .order('date_debut', ascending: false)
          .limit(50);

      setState(() {
        _ecoles = List<Map<String, dynamic>>.from(ecoles);
        _cursus = List<Map<String, dynamic>>.from(cursus);
        _formations = List<Map<String, dynamic>>.from(formations);
        _etapes = List<Map<String, dynamic>>.from(etapes);
        _webinaires = List<Map<String, dynamic>>.from(webinaires);
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
        const SizedBox(height: 16),
        _statsRow(),
        const SizedBox(height: 24),
        _sectionTitle('🏛️ ÉCOLES PERMANENTES'),
        const SizedBox(height: 10),
        ..._ecoles.map(_ecoleCard),
        const SizedBox(height: 24),
        _sectionTitle('🎓 FORMATIONS INDÉPENDANTES'),
        const SizedBox(height: 10),
        ..._formations.map(_formationCard),
        const SizedBox(height: 24),
        _sectionTitle('🎯 PARCOURS NEUROCITOYEN (${_etapes.length} étapes)'),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: _actionBtn(
            Icons.add_circle,
            'Nouvelle étape',
            _C.vert,
            () => _openEtape(null),
          ),
        ),
        ..._etapes.map(_etapeCard),
        const SizedBox(height: 24),
        _sectionTitle('📹 WEBINAIRES'),
        const SizedBox(height: 10),
        if (_webinaires.isEmpty)
          _emptyCard('Aucun webinaire planifié', Icons.video_call)
        else
          ..._webinaires.map(_webinaireCard),
        const SizedBox(height: 30),
      ],
    );
  }

  // ===========================================================================
  // HEADER
  // ===========================================================================
  Widget _header() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_C.teal, Color(0xFF1A5A4A)],
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
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.school, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'UNIVERSITÉ BAOBAB',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 10,
                        letterSpacing: 2,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text('Gestion complète',
                        style: _serif(22,
                            color: Colors.white, weight: FontWeight.w900)),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.refresh, color: Colors.white),
                onPressed: _load,
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'Écoles → Cursus → Modules · Formations indépendantes · Parcours 7 étapes · Webinaires',
            style:
                TextStyle(color: Colors.white70, fontSize: 11, height: 1.4),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // STATS
  // ===========================================================================
  Widget _statsRow() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _statChip('${_ecoles.length}', 'Écoles', _C.teal),
        _statChip('${_cursus.length}', 'Cursus', _C.violet),
        _statChip('${_formations.length}', 'Formations', _C.or),
        _statChip('${_etapes.length}', 'Étapes', _C.vert),
        _statChip('${_webinaires.length}', 'Webinaires', _C.rouge),
      ],
    );
  }

  Widget _statChip(String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(value,
              style: TextStyle(
                  color: color, fontSize: 16, fontWeight: FontWeight.w900)),
          const SizedBox(width: 6),
          Text(label,
              style: const TextStyle(color: Colors.white70, fontSize: 11)),
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
  // CARTE ÉCOLE
  // ===========================================================================
  Widget _ecoleCard(Map<String, dynamic> e) {
    final code = '${e['code']}';
    final cursusEcole =
        _cursus.where((c) => c['ecole_code'] == code).toList();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: _C.nuit2,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _C.teal.withOpacity(0.4), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => _openEcole(e),
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: _C.teal,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.school,
                        color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: _C.teal.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                code,
                                style: const TextStyle(
                                    color: _C.teal,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w900),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '${cursusEcole.length} cursus',
                              style: const TextStyle(
                                  color: Colors.white54, fontSize: 10),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text('${e['nom']}',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w900)),
                        if (e['sous_titre'] != null)
                          Text('${e['sous_titre']}',
                              style: const TextStyle(
                                  color: Colors.white54, fontSize: 11)),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward, color: _C.teal, size: 20),
                ],
              ),
            ),
          ),
          if (cursusEcole.isNotEmpty)
            Container(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Column(
                children:
                    cursusEcole.map((cu) => _cursusInline(cu)).toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _cursusInline(Map<String, dynamic> cu) {
    return InkWell(
      onTap: () => _openCursus(cu),
      borderRadius: BorderRadius.circular(6),
      child: Container(
        margin: const EdgeInsets.only(top: 6),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: _C.nuit3,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: _C.violet.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.book, color: _C.violet, size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${cu['nom']}',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700)),
                  if (cu['sous_titre'] != null)
                    Text('${cu['sous_titre']}',
                        style: const TextStyle(
                            color: Colors.white54, fontSize: 10)),
                ],
              ),
            ),
            Text('${cu['prix_fcfa'] ?? 0} F',
                style: const TextStyle(
                    color: _C.orClair,
                    fontSize: 10,
                    fontWeight: FontWeight.bold)),
            const SizedBox(width: 6),
            const Icon(Icons.chevron_right, color: _C.violet, size: 16),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // CARTE FORMATION
  // ===========================================================================
  Widget _formationCard(Map<String, dynamic> f) {
    return InkWell(
      onTap: () => _openFormation(f),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _C.nuit2,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _C.or.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _C.or.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.school, color: _C.or, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: _C.or.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text('${f['code'] ?? ''}',
                        style: const TextStyle(
                            color: _C.or,
                            fontSize: 9,
                            fontWeight: FontWeight.w900)),
                  ),
                  const SizedBox(height: 4),
                  Text('${f['titre']}',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w700)),
                  if (f['sous_titre'] != null)
                    Text('${f['sous_titre']}',
                        style: const TextStyle(
                            color: Colors.white54, fontSize: 11)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('${f['prix_fcfa'] ?? 5000} F',
                    style: const TextStyle(
                        color: _C.orClair,
                        fontSize: 11,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                const Icon(Icons.chevron_right, color: _C.or, size: 18),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // CARTE ÉTAPE
  // ===========================================================================
  Widget _etapeCard(Map<String, dynamic> e) {
    final numero = e['numero'];
    final gratuit = e['gratuit'] == true;
    final obligatoire = e['obligatoire'] == true;

    return InkWell(
      onTap: () => _openEtape(e),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _C.nuit2,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: _C.vert.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration:
                  const BoxDecoration(color: _C.vert, shape: BoxShape.circle),
              child: Center(
                child: Text('$numero',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w900)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${e['titre']}',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w700)),
                  if (e['sous_titre'] != null && '${e['sous_titre']}'.isNotEmpty)
                    Text('${e['sous_titre']}',
                        style: const TextStyle(
                            color: Colors.white54, fontSize: 11)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      _chipBadge(
                        gratuit ? 'GRATUIT' : 'PAYANT',
                        gratuit ? _C.vert : _C.or,
                      ),
                      const SizedBox(width: 6),
                      if (obligatoire) _chipBadge('OBLIGATOIRE', _C.violet),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: _C.or, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _chipBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(text,
          style: TextStyle(
              color: color, fontSize: 9, fontWeight: FontWeight.w900)),
    );
  }

  // ===========================================================================
  // WIDGETS UTILITAIRES
  // ===========================================================================
  Widget _actionBtn(
      IconData icon, String label, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color.withValues(alpha: 0.4)),
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

  Widget _emptyCard(String text, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _C.nuit2,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white38, size: 24),
          const SizedBox(width: 12),
          Text(text,
              style: const TextStyle(color: Colors.white54, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _webinaireCard(Map<String, dynamic> w) {
    final dateStr = w['date_debut']?.toString() ?? '';
    final date = dateStr.length >= 10 ? dateStr.substring(0, 10) : dateStr;
    final heure = dateStr.length >= 16 ? dateStr.substring(11, 16) : '';

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _C.nuit2,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _C.rouge.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _C.rouge.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.video_call, color: _C.rouge, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${w['titre']}',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w700)),
                Text('$date · $heure · ${w['formateur'] ?? '—'}',
                    style: const TextStyle(
                        color: Colors.white54, fontSize: 10)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // NAVIGATION
  // ===========================================================================
  void _openEcole(Map<String, dynamic> e) {
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (_) => AdminEcoleDetailScreen(ecole: e),
          ),
        )
        .then((_) => _load());
  }

  void _openCursus(Map<String, dynamic> c) {
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (_) => AdminCursusDetailScreen(cursus: c),
          ),
        )
        .then((_) => _load());
  }

  void _openFormation(Map<String, dynamic> f) {
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (_) => AdminFormationDetailScreen(formation: f),
          ),
        )
        .then((_) => _load());
  }

  void _openEtape(Map<String, dynamic>? e) {
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (_) => AdminEtapeDetailScreen(etape: e),
          ),
        )
        .then((_) => _load());
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
