import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../widgets/app_scaffold.dart';
import 'module_detail_user_screen.dart';

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

class CursusDetailUserScreen extends StatefulWidget {
  final Map<String, dynamic> cursus;
  const CursusDetailUserScreen({super.key, required this.cursus});

  @override
  State<CursusDetailUserScreen> createState() =>
      _CursusDetailUserScreenState();
}

class _CursusDetailUserScreenState extends State<CursusDetailUserScreen> {
  bool _loading = true;
  late Map<String, dynamic> _cursus;
  List<Map<String, dynamic>> _modules = [];
  Map<String, Map<String, dynamic>> _progress = {}; // moduleId -> progress
  String? _userId;

  SupabaseClient get _db => Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _cursus = Map<String, dynamic>.from(widget.cursus);
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      _userId = prefs.getString('user_id');

      final modules = await _db
          .from('cursus_modules')
          .select()
          .eq('cursus_id', _cursus['id'])
          .eq('actif', true)
          .order('numero');

      // Charger la progression utilisateur
      Map<String, Map<String, dynamic>> progress = {};
      if (_userId != null) {
        try {
          final prog = await _db
              .from('user_cursus_progress')
              .select()
              .eq('user_id', _userId!)
              .eq('cursus_id', _cursus['id']);
          for (final p in prog) {
            final moduleId = p['module_id']?.toString();
            if (moduleId != null) {
              progress[moduleId] = Map<String, dynamic>.from(p);
            }
          }
        } catch (_) {}
      }

      setState(() {
        _modules = List<Map<String, dynamic>>.from(modules);
        _progress = progress;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  /// Retourne le statut d'un module :
  /// -1 = verrouillé, 0 = à commencer, 1 = en cours, 2 = validé
  int _statutModule(int index) {
    if (index == 0) return _statutDepuisProgress(index);
    // Vérifier que le précédent est validé
    final prevId = _modules[index - 1]['id']?.toString();
    if (prevId == null) return 0;
    final prevProgress = _progress[prevId];
    if (prevProgress == null) return -1;
    if (prevProgress['statut'] != 'termine' &&
        prevProgress['statut'] != 'certifie') {
      return -1;
    }
    return _statutDepuisProgress(index);
  }

  int _statutDepuisProgress(int index) {
    final moduleId = _modules[index]['id']?.toString();
    if (moduleId == null) return 0;
    final p = _progress[moduleId];
    if (p == null) return 0;
    switch (p['statut']) {
      case 'termine':
      case 'certifie':
        return 2;
      case 'en_cours':
        return 1;
      default:
        return 0;
    }
  }

  int get _modulesValides => _modules
      .where((m) {
        final p = _progress[m['id']?.toString()];
        return p != null &&
            (p['statut'] == 'termine' || p['statut'] == 'certifie');
      })
      .length;

  double get _progressionCursus =>
      _modules.isEmpty ? 0 : _modulesValides / _modules.length;

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: '${_cursus['nom'] ?? 'Cursus'}',
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
                  _progressionCard(),
                  const SizedBox(height: 20),
                  _sectionTitle('📚 MODULES DU CURSUS'),
                  const SizedBox(height: 10),
                  ..._modules.asMap().entries.map((entry) {
                    final index = entry.key;
                    final module = entry.value;
                    return _moduleCard(module, index);
                  }),
                  const SizedBox(height: 24),
                  if (_modulesValides == _modules.length && _modules.isNotEmpty)
                    _certificationBanner(),
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
          colors: [_C.violet, Color(0xFF4A2E5C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.book, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_cursus['ecole_code'] ?? 'CURSUS'}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 10,
                        letterSpacing: 2,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${_cursus['nom'] ?? ''}',
                      style: _serif(22,
                          color: Colors.white, weight: FontWeight.w900),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_cursus['description'] != null)
            Text(
              '${_cursus['description']}',
              style: const TextStyle(
                  color: Colors.white70, fontSize: 12, height: 1.5),
            ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _badge(Icons.schedule, '${_cursus['duree_semaines'] ?? 4} sem.',
                  Colors.white),
              _badge(Icons.book, '${_modules.length} modules', Colors.white),
              if (_cursus['prix_fcfa'] == 0)
                _badge(Icons.money_off, 'GRATUIT', _C.vert)
              else
                _badge(Icons.money, '${_cursus['prix_fcfa']} FCFA',
                    _C.orClair),
            ],
          ),
        ],
      ),
    );
  }

  Widget _badge(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 13),
          const SizedBox(width: 5),
          Text(label,
              style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.w600)),
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
  // PROGRESSION
  // ===========================================================================
  Widget _progressionCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _C.nuit3,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _C.or.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.trending_up, color: _C.or, size: 20),
              const SizedBox(width: 8),
              Text('Ma progression', style: _serif(15)),
              const Spacer(),
              Text('$_modulesValides / ${_modules.length}',
                  style: _serif(18, color: _C.or)),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: _progressionCursus,
              minHeight: 10,
              backgroundColor: Colors.white10,
              valueColor: const AlwaysStoppedAnimation(_C.or),
            ),
          ),
          const SizedBox(height: 8),
          Text('${(_progressionCursus * 100).round()}% complété',
              style:
                  const TextStyle(color: Colors.white54, fontSize: 11)),
        ],
      ),
    );
  }

  // ===========================================================================
  // CARTE MODULE
  // ===========================================================================
  Widget _moduleCard(Map<String, dynamic> m, int index) {
    final numero = m['numero'] ?? index + 1;
    final titre = m['titre'] ?? 'Module $numero';
    final sousTitre = m['sous_titre'] ?? '';
    final duree = m['duree_heures'] ?? 0;
    final statut = _statutModule(index);

    final estVerrouille = statut == -1;
    final estEnCours = statut == 1;
    final estValide = statut >= 2;

    final moduleId = m['id']?.toString();
    final prog = moduleId != null ? _progress[moduleId] : null;
    final score = prog?['score_obtenu'];

    Color borderColor;
    if (estValide) {
      borderColor = _C.vert;
    } else if (estEnCours) {
      borderColor = _C.or;
    } else if (estVerrouille) {
      borderColor = Colors.white24;
    } else {
      borderColor = _C.violet;
    }

    return InkWell(
      onTap: estVerrouille
          ? () => _showLockedDialog(index)
          : () => _openModule(m),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _C.nuit2,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor, width: 2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: estVerrouille
                        ? Colors.white10
                        : (estValide ? _C.vert : borderColor),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: estVerrouille
                        ? const Icon(Icons.lock,
                            color: Colors.white54, size: 18)
                        : estValide
                            ? const Icon(Icons.check,
                                color: Colors.white, size: 22)
                            : Text('$numero',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 16)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Module $numero',
                        style: TextStyle(
                            color: estVerrouille ? Colors.white38 : _C.or,
                            fontSize: 10,
                            letterSpacing: 2,
                            fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        titre,
                        style: TextStyle(
                            color: estVerrouille
                                ? Colors.white54
                                : Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w700),
                      ),
                      if (sousTitre.isNotEmpty)
                        Text(sousTitre,
                            style: const TextStyle(
                                color: Colors.white54, fontSize: 11)),
                    ],
                  ),
                ),
                if (estValide)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: _C.vert.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      score != null ? '$score%' : 'VALIDÉ',
                      style: const TextStyle(
                          color: _C.vert,
                          fontSize: 10,
                          fontWeight: FontWeight.w900),
                    ),
                  )
                else if (estEnCours)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: _C.or.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text('EN COURS',
                        style: TextStyle(
                            color: _C.or,
                            fontSize: 10,
                            fontWeight: FontWeight.w900)),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.schedule, color: Colors.white38, size: 12),
                const SizedBox(width: 4),
                Text('$duree h',
                    style: const TextStyle(
                        color: Colors.white54, fontSize: 11)),
                const Spacer(),
                if (!estVerrouille)
                  Row(
                    children: [
                      Text(
                        estValide
                            ? 'REVOIR'
                            : (estEnCours ? 'CONTINUER' : 'COMMENCER'),
                        style: TextStyle(
                            color: borderColor,
                            fontSize: 10,
                            fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(width: 4),
                      Icon(Icons.arrow_forward,
                          color: borderColor, size: 14),
                    ],
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // BANNIÈRE CERTIFICATION
  // ===========================================================================
  Widget _certificationBanner() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_C.vert, Color(0xFF0A5A2D)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Icon(Icons.workspace_premium, color: Colors.white, size: 48),
          const SizedBox(height: 10),
          Text('Félicitations !',
              style: _serif(22, color: Colors.white,
                  weight: FontWeight.w900)),
          const SizedBox(height: 6),
          Text(
            'Tu as validé tous les modules du ${_cursus['nom']}.',
            textAlign: TextAlign.center,
            style: const TextStyle(
                color: Colors.white70, fontSize: 13, height: 1.5),
          ),
          const SizedBox(height: 12),
          if (_cursus['certification_titre'] != null)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${_cursus['certification_titre']}',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
    );
  }

  // ===========================================================================
  // DIALOG VERROUILLÉ
  // ===========================================================================
  void _showLockedDialog(int index) {
    final prevTitre = index > 0 ? _modules[index - 1]['titre'] : '';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _C.nuit2,
        title: Row(
          children: [
            const Icon(Icons.lock, color: _C.or, size: 22),
            const SizedBox(width: 10),
            Text('Module verrouillé',
                style: _serif(16, color: Colors.white)),
          ],
        ),
        content: Text(
          'Tu dois d\'abord valider le module précédent : "$prevTitre".\n\nLe seuil de validation est de 85%.',
          style: const TextStyle(
              color: Colors.white70, fontSize: 13, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK',
                style: TextStyle(color: _C.or)),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // NAVIGATION
  // ===========================================================================
  void _openModule(Map<String, dynamic> m) {
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (_) => ModuleDetailUserScreen(
              module: m,
              cursusId: _cursus['id'],
            ),
          ),
        )
        .then((_) => _load());
  }
}
