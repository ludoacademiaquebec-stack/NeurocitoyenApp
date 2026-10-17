import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../widgets/app_scaffold.dart';
import 'cursus_detail_user_screen.dart';
import 'formation_detail_user_screen.dart';

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

class UniversiteScreen extends StatefulWidget {
  const UniversiteScreen({super.key});
  @override
  State<UniversiteScreen> createState() => _UniversiteScreenState();
}

class _UniversiteScreenState extends State<UniversiteScreen> {
  bool _loading = true;
  List<Map<String, dynamic>> _ecoles = [];
  List<Map<String, dynamic>> _cursus = [];
  List<Map<String, dynamic>> _formations = [];
  List<Map<String, dynamic>> _webinaires = [];
  bool _etape1Validee = false;
  String? _userId;

  SupabaseClient get _db => Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      _userId = prefs.getString('user_id');

      final ecoles = await _db.from('ecoles').select().order('ordre');
      final cursus = await _db.from('cursus').select().order('ordre');
      final formations =
          await _db.from('formations').select().order('ordre');
      final webinaires = await _db
          .from('webinaires')
          .select()
          .eq('statut', 'planifie')
          .order('date_debut')
          .limit(10);

      // Vérifier si étape 1 validée
      bool etape1 = false;
      if (_userId != null) {
        try {
          final progress = await _db
              .from('user_progress')
              .select()
              .eq('user_id', _userId!)
              .eq('etape_numero', 1)
              .maybeSingle();
          if (progress != null &&
              (progress['statut'] == 'certifie' ||
                  progress['statut'] == 'termine')) {
            etape1 = true;
          }
        } catch (_) {}
      }

      setState(() {
        _ecoles = List<Map<String, dynamic>>.from(ecoles);
        _cursus = List<Map<String, dynamic>>.from(cursus);
        _formations = List<Map<String, dynamic>>.from(formations);
        _webinaires = List<Map<String, dynamic>>.from(webinaires);
        _etape1Validee = etape1;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Université Baobab',
      child: _loading
          ? const Center(child: CircularProgressIndicator(color: _C.or))
          : RefreshIndicator(
              onRefresh: _load,
              color: _C.or,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _header(),
                  const SizedBox(height: 20),
                  _sectionTitle('🏛️ LES 3 ÉCOLES PERMANENTES'),
                  const SizedBox(height: 10),
                  ..._ecoles.map(_ecoleCard),
                  const SizedBox(height: 24),
                  _sectionTitle('🎓 FORMATIONS INDÉPENDANTES'),
                  const SizedBox(height: 10),
                  if (!_etape1Validee)
                    _lockedBanner(
                        'Valide d\'abord Le Mur Invisible pour accéder aux formations certifiantes'),
                  ..._formations.map(_formationCard),
                  const SizedBox(height: 24),
                  _sectionTitle('📹 PROCHAINS WEBINAIRES'),
                  const SizedBox(height: 10),
                  if (_webinaires.isEmpty)
                    _emptyCard('Aucun webinaire planifié',
                        Icons.video_call)
                  else
                    ..._webinaires.map(_webinaireCard),
                  const SizedBox(height: 30),
                ],
              ),
            ),
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
          colors: [_C.or, Color(0xFF8B6914)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'UNIVERSITÉ BAOBAB',
            style: TextStyle(
              color: Colors.black54,
              fontSize: 11,
              letterSpacing: 2,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Text('Apprends toute ta vie',
              style: _serif(26, color: Colors.black, weight: FontWeight.w900)),
          const SizedBox(height: 6),
          const Text(
            '3 écoles permanentes · Formations certifiantes · Webinaires live',
            style: TextStyle(color: Colors.black87, fontSize: 12, height: 1.4),
          ),
          const SizedBox(height: 12),
          if (!_etape1Validee)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.lock, color: Colors.black, size: 14),
                  SizedBox(width: 6),
                  Text(
                    'Commence par Le Mur Invisible',
                    style: TextStyle(
                        color: Colors.black,
                        fontSize: 11,
                        fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle, color: Colors.black, size: 14),
                  SizedBox(width: 6),
                  Text(
                    'Neurocitoyen certifié',
                    style: TextStyle(
                        color: Colors.black,
                        fontSize: 11,
                        fontWeight: FontWeight.bold),
                  ),
                ],
              ),
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

  Widget _lockedBanner(String msg) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _C.rouge.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _C.rouge.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.lock, color: _C.rouge, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              msg,
              style: const TextStyle(
                  color: _C.rouge, fontSize: 12, height: 1.4),
            ),
          ),
        ],
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

    // Logique de verrouillage
    final isInstitut = code == 'IN';
    final estVerrouille = !isInstitut && !_etape1Validee;

    Color borderColor;
    if (isInstitut) {
      borderColor = _C.or;
    } else if (estVerrouille) {
      borderColor = Colors.white24;
    } else {
      borderColor = _C.teal;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: _C.nuit2,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header école
          InkWell(
            onTap: estVerrouille
                ? () => _showLockedDialog()
                : () => _openEcole(e),
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(14)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: isInstitut
                          ? _C.or
                          : (estVerrouille ? Colors.white10 : _C.teal),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: estVerrouille
                          ? const Icon(Icons.lock,
                              color: Colors.white54, size: 22)
                          : Icon(
                              isInstitut
                                  ? Icons.self_improvement
                                  : Icons.school,
                              color: isInstitut ? Colors.black : Colors.white,
                              size: 24,
                            ),
                    ),
                  ),
                  const SizedBox(width: 14),
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
                                color: isInstitut
                                    ? _C.or.withOpacity(0.2)
                                    : (estVerrouille
                                        ? Colors.white10
                                        : _C.teal.withOpacity(0.2)),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                code,
                                style: TextStyle(
                                    color: isInstitut
                                        ? _C.or
                                        : (estVerrouille
                                            ? Colors.white38
                                            : _C.teal),
                                    fontSize: 10,
                                    fontWeight: FontWeight.w900),
                              ),
                            ),
                            const SizedBox(width: 6),
                            if (isInstitut)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: _C.vert.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'OBLIGATOIRE',
                                  style: TextStyle(
                                      color: _C.vert,
                                      fontSize: 8,
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
                        Text(
                          '${e['nom']}',
                          style: TextStyle(
                              color: estVerrouille
                                  ? Colors.white54
                                  : Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w900),
                        ),
                        if (e['sous_titre'] != null)
                          Text(
                            '${e['sous_titre']}',
                            style: TextStyle(
                                color: estVerrouille
                                    ? Colors.white38
                                    : Colors.white54,
                                fontSize: 11),
                          ),
                      ],
                    ),
                  ),
                  Icon(
                    estVerrouille ? Icons.lock : Icons.arrow_forward,
                    color: estVerrouille ? Colors.white38 : borderColor,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),

          // Cursus en dessous (seulement si accessible)
          if (!estVerrouille && cursusEcole.isNotEmpty)
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
      borderRadius: BorderRadius.circular(8),
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
            Text(
                cu['prix_fcfa'] == 0
                    ? 'GRATUIT'
                    : '${cu['prix_fcfa']} F',
                style: TextStyle(
                    color: cu['prix_fcfa'] == 0 ? _C.vert : _C.orClair,
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
    final estVerrouille = !_etape1Validee;

    return InkWell(
      onTap: estVerrouille
          ? () => _showLockedDialog()
          : () => _openFormation(f),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _C.nuit2,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: estVerrouille
                ? Colors.white24
                : _C.or.withOpacity(0.4),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: estVerrouille
                    ? Colors.white10
                    : _C.or.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: estVerrouille
                  ? const Icon(Icons.lock, color: Colors.white54, size: 20)
                  : const Icon(Icons.school, color: _C.or, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${f['titre']}',
                    style: TextStyle(
                        color: estVerrouille
                            ? Colors.white54
                            : Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w700),
                  ),
                  if (f['sous_titre'] != null)
                    Text(
                      '${f['sous_titre']}',
                      style: const TextStyle(
                          color: Colors.white54, fontSize: 11),
                    ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('${f['prix_fcfa'] ?? 5000} F',
                    style: TextStyle(
                        color: estVerrouille
                            ? Colors.white38
                            : _C.orClair,
                        fontSize: 11,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Icon(
                  estVerrouille ? Icons.lock : Icons.chevron_right,
                  color: estVerrouille ? Colors.white38 : _C.or,
                  size: 18,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // CARTE WEBINAIRE
  // ===========================================================================
  Widget _webinaireCard(Map<String, dynamic> w) {
    final dateStr = w['date_debut']?.toString() ?? '';
    final date = dateStr.length >= 10 ? dateStr.substring(0, 10) : dateStr;
    final heure =
        dateStr.length >= 16 ? dateStr.substring(11, 16) : '';

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _C.nuit2,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _C.rouge.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _C.rouge.withOpacity(0.15),
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
              style:
                  const TextStyle(color: Colors.white54, fontSize: 13)),
        ],
      ),
    );
  }

  // ===========================================================================
  // DIALOG VERROUILLÉ
  // ===========================================================================
  void _showLockedDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _C.nuit2,
        title: Row(
          children: [
            const Icon(Icons.lock, color: _C.or, size: 24),
            const SizedBox(width: 10),
            Text('Accès verrouillé',
                style: _serif(16, color: Colors.white)),
          ],
        ),
        content: const Text(
          'Tu dois d\'abord valider les 5 modules du Mur Invisible dans l\'Institut de la Neurocitoyenneté.',
          style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Plus tard',
                style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              // Ouvrir l'Institut
              final institut = _ecoles.firstWhere(
                (e) => e['code'] == 'IN',
                orElse: () => <String, dynamic>{},
              );
              if (institut.isNotEmpty) _openEcole(institut);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _C.or,
              foregroundColor: Colors.black,
            ),
            child: const Text('Aller à l\'Institut',
                style: TextStyle(fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // NAVIGATION
  // ===========================================================================
  void _openEcole(Map<String, dynamic> e) {
    final code = '${e['code']}';
    // Pour l'Institut, ouvrir directement le cursus "Le Mur Invisible"
    if (code == 'IN') {
      final murInvisible = _cursus.firstWhere(
        (c) => c['ecole_code'] == 'IN',
        orElse: () => <String, dynamic>{},
      );
      if (murInvisible.isNotEmpty) {
        _openCursus(murInvisible);
        return;
      }
    }
    // Pour les autres écoles, rien pour l'instant (à étendre)
  }

  void _openCursus(Map<String, dynamic> c) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CursusDetailUserScreen(cursus: c),
      ),
    ).then((_) => _load());
  }

  void _openFormation(Map<String, dynamic> f) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => FormationDetailUserScreen(formation: f),
      ),
    ).then((_) => _load());
  }
}
