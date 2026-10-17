import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/ai_service.dart';
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

class ModuleDetailUserScreen extends StatefulWidget {
  final Map<String, dynamic> module;
  final dynamic cursusId;
  const ModuleDetailUserScreen({
    super.key,
    required this.module,
    required this.cursusId,
  });

  @override
  State<ModuleDetailUserScreen> createState() =>
      _ModuleDetailUserScreenState();
}

class _ModuleDetailUserScreenState extends State<ModuleDetailUserScreen> {
  bool _loading = true;
  late Map<String, dynamic> _module;
  List<Map<String, dynamic>> _ressources = [];
  Map<String, dynamic>? _apprenant;
  Map<String, dynamic>? _progress;
  String? _userId;
  int _currentTab = 0;

  String? _contenuIA;
  bool _chargementContenu = false;

  // Chat
  final TextEditingController _messageCtrl = TextEditingController();
  final ScrollController _chatScroll = ScrollController();
  bool _envoiEnCours = false;
  List<Map<String, dynamic>> _historique = [];

  Map<String, dynamic>? _quizActuel;
  bool _chargementQuiz = false;
  int _questionIndex = 0;
  Map<String, String> _reponses = {};
  Map<String, dynamic>? _resultatQuiz;
  bool _quizEnCours = false;

  SupabaseClient get _db => Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _module = Map<String, dynamic>.from(widget.module);
    _load();
  }

  @override
  void dispose() {
    _messageCtrl.dispose();
    _chatScroll.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      _userId = prefs.getString('user_id');

      final ressources = await _db
          .from('cursus_ressources')
          .select()
          .eq('module_id', _module['id'])
          .eq('actif', true)
          .order('ordre');

      if (_userId != null) {
        try {
          _apprenant = await _db
              .from('users')
              .select('prenoms, pseudo, pays_id, nom')
              .eq('id', _userId!)
              .maybeSingle();

          _progress = await _db
              .from('user_cursus_progress')
              .select()
              .eq('user_id', _userId!)
              .eq('module_id', _module['id'])
              .maybeSingle();
        } catch (_) {}
      }

      setState(() {
        _ressources = List<Map<String, dynamic>>.from(ressources);
        _loading = false;
      });

      // Charger l'historique de conversation
      await _chargerHistorique();
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Future<void> _genererContenu() async {
    setState(() {
      _chargementContenu = true;
      _contenuIA = null;
    });

    try {
      final contenu = await AiService.genererContenuModule(
        module: _module,
        apprenant: _apprenant,
      );

      setState(() {
        _contenuIA = contenu;
        _chargementContenu = false;
      });

      if (_userId != null) {
        await AiService.sauvegarderConversation(
          userId: _userId!,
          moduleId: '${_module['id']}',
          moduleType: 'cursus',
          role: 'assistant',
          contenu: contenu,
        );
      }
    } catch (e) {
      setState(() => _chargementContenu = false);
      _toast('Erreur IA : $e', rouge: true);
    }
  }

  Future<void> _demarrerQuiz() async {
    setState(() {
      _chargementQuiz = true;
      _quizActuel = null;
      _resultatQuiz = null;
      _reponses = {};
      _questionIndex = 0;
    });

    try {
      final quiz = await AiService.genererQuiz(
        module: _module,
        apprenant: _apprenant,
      );

      setState(() {
        _quizActuel = quiz;
        _chargementQuiz = false;
        _quizEnCours = true;
      });
    } catch (e) {
      setState(() => _chargementQuiz = false);
      _toast('Erreur IA : $e', rouge: true);
    }
  }

  void _repondreQuestion(String questionId, String optionId) {
    setState(() => _reponses[questionId] = optionId);

    final questions = _quizActuel!['questions'] as List;
    if (_questionIndex < questions.length - 1) {
      setState(() => _questionIndex++);
    } else {
      _terminerQuiz();
    }
  }

  Future<void> _terminerQuiz() async {
    setState(() => _chargementQuiz = true);

    try {
      final resultat = await AiService.evaluerQuiz(
        module: _module,
        quiz: _quizActuel!,
        reponses: _reponses,
        apprenant: _apprenant,
      );

      setState(() {
        _resultatQuiz = resultat;
        _chargementQuiz = false;
        _quizEnCours = false;
      });

      if (_userId != null) {
        await AiService.sauvegarderTentativeQuiz(
          userId: _userId!,
          moduleId: '${_module['id']}',
          moduleType: 'cursus',
          quiz: _quizActuel!,
          reponses: _reponses,
          resultat: resultat,
        );

        if (resultat['valide'] == true) {
          await _enregistrerValidation(resultat['score'] as int);
        }
      }
    } catch (e) {
      setState(() => _chargementQuiz = false);
      _toast('Erreur évaluation : $e', rouge: true);
    }
  }

  Future<void> _enregistrerValidation(int score) async {
    if (_userId == null) return;
    try {
      final existing = await _db
          .from('user_cursus_progress')
          .select()
          .eq('user_id', _userId!)
          .eq('module_id', _module['id'])
          .maybeSingle();

      if (existing == null) {
        await _db.from('user_cursus_progress').insert({
          'user_id': _userId!,
          'cursus_id': widget.cursusId,
          'module_id': _module['id'],
          'statut': 'termine',
          'progression': 100,
          'score_obtenu': score,
          'date_debut': DateTime.now().toIso8601String(),
          'date_fin': DateTime.now().toIso8601String(),
        });
      } else {
        await _db
            .from('user_cursus_progress')
            .update({
              'statut': 'termine',
              'progression': 100,
              'score_obtenu': score,
              'date_fin': DateTime.now().toIso8601String(),
            })
            .eq('id', existing['id']);
      }

      await _checkCursusCompletion();
    } catch (_) {}
  }

  Future<void> _checkCursusCompletion() async {
    try {
      final modulesRes = await _db
          .from('cursus_modules')
          .select('id')
          .eq('cursus_id', widget.cursusId)
          .eq('actif', true);
      final totalModules = modulesRes.length;

      final progressRes = await _db
          .from('user_cursus_progress')
          .select('module_id, statut')
          .eq('user_id', _userId!)
          .eq('cursus_id', widget.cursusId);
      final modulesValides = progressRes
          .where((p) => p['statut'] == 'termine' || p['statut'] == 'certifie')
          .length;

      if (totalModules > 0 && modulesValides >= totalModules) {
        final cursusRes = await _db
            .from('cursus')
            .select('ecole_code')
            .eq('id', widget.cursusId)
            .maybeSingle();

        if (cursusRes != null && cursusRes['ecole_code'] == 'IN') {
          final existing = await _db
              .from('user_progress')
              .select()
              .eq('user_id', _userId!)
              .eq('etape_numero', 1)
              .maybeSingle();

          if (existing == null) {
            await _db.from('user_progress').insert({
              'user_id': _userId!,
              'etape_numero': 1,
              'statut': 'certifie',
              'progression': 100,
              'date_debut': DateTime.now().toIso8601String(),
              'date_fin': DateTime.now().toIso8601String(),
            });
          } else {
            await _db
                .from('user_progress')
                .update({
                  'statut': 'certifie',
                  'progression': 100,
                  'date_fin': DateTime.now().toIso8601String(),
                })
                .eq('id', existing['id']);
          }
        }
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Module ${_module['numero'] ?? ''} · ${_module['titre'] ?? ''}',
      child: _loading
          ? const Center(child: CircularProgressIndicator(color: _C.or))
          : Column(
              children: [
                _tabBar(),
                Expanded(
                  child: IndexedStack(
                    index: _currentTab,
                    children: [
                      _tabContenuIA(),
                      _tabRessources(),
                      _tabQuizIA(),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _tabBar() {
    return Container(
      color: _C.nuit2,
      child: Row(
        children: [
          _tabBtn(0, Icons.smart_toy, 'Coach IA'),
          _tabBtn(1, Icons.attach_file, 'Ressources (${_ressources.length})'),
          _tabBtn(2, Icons.quiz, 'Quiz IA'),
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
          padding: const EdgeInsets.symmetric(vertical: 12),
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
              Icon(icon, color: sel ? _C.or : Colors.white54, size: 20),
              const SizedBox(height: 4),
              Text(label,
                  style: TextStyle(
                      color: sel ? _C.or : Colors.white54,
                      fontSize: 10,
                      fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tabContenuIA() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _header(),
        const SizedBox(height: 20),
        _sectionTitle('🤖 COACH BAOBAB'),
        const SizedBox(height: 10),
        if (_chargementContenu)
          _loadingCard('Coach Baobab prépare ton cours personnalisé...')
        else if (_contenuIA == null)
          _promptCard()
        else
          _contenuCard(),
      ],
    );
  }

  Widget _header() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_C.violet, Color(0xFF4A2E5C)],
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
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    '${_module['numero'] ?? '1'}',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w900),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('MODULE',
                        style: TextStyle(
                            color: Colors.white70,
                            fontSize: 10,
                            letterSpacing: 2,
                            fontWeight: FontWeight.bold)),
                    Text('${_module['titre']}',
                        style: _serif(20,
                            color: Colors.white, weight: FontWeight.w900)),
                  ],
                ),
              ),
            ],
          ),
          if (_module['sous_titre'] != null) ...[
            const SizedBox(height: 10),
            Text('${_module['sous_titre']}',
                style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    fontStyle: FontStyle.italic)),
          ],
          const SizedBox(height: 14),
          Row(
            children: [
              const Icon(Icons.schedule, color: Colors.white70, size: 14),
              const SizedBox(width: 4),
              Text('${_module['duree_heures'] ?? 0} h',
                  style: const TextStyle(
                      color: Colors.white70, fontSize: 12)),
              const SizedBox(width: 16),
              const Icon(Icons.psychology,
                  color: Colors.white70, size: 14),
              const SizedBox(width: 4),
              const Text('Coach IA personnel',
                  style: TextStyle(
                      color: Colors.white70, fontSize: 12)),
            ],
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

  Widget _loadingCard(String message) {
    return Container(
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: _C.nuit2,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _C.violet.withOpacity(0.4)),
      ),
      child: Column(
        children: [
          const CircularProgressIndicator(color: _C.violet),
          const SizedBox(height: 20),
          Text(message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: Colors.white70, fontSize: 13)),
          const SizedBox(height: 8),
          const Text('Cela peut prendre 10-20 secondes',
              style: TextStyle(color: Colors.white38, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _promptCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _C.nuit2,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _C.violet.withOpacity(0.5), width: 2),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _C.violet.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.smart_toy,
                color: _C.violet, size: 40),
          ),
          const SizedBox(height: 16),
          Text('Coach Baobab t\'attend',
              style: _serif(18, color: Colors.white)),
          const SizedBox(height: 8),
          const Text(
            'Ton coach IA va te présenter ce module de manière personnalisée.',
            textAlign: TextAlign.center,
            style: TextStyle(
                color: Colors.white70, fontSize: 13, height: 1.5),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _genererContenuAvecSauvegarde,
              icon: const Icon(Icons.auto_awesome, size: 18),
              label: const Text('COMMENCER LE MODULE AVEC COACH BAOBAB',
                  style: TextStyle(
                      fontWeight: FontWeight.w900, fontSize: 12)),
              style: ElevatedButton.styleFrom(
                backgroundColor: _C.violet,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _contenuCard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _chatEntete(),
        const SizedBox(height: 12),
        _listeMessages(),
        const SizedBox(height: 12),
        _zoneSaisie(),
        const SizedBox(height: 16),
        _actionSuivant(),
      ],
    );
  }

  // ===========================================================================
  // ENTÊTE DU CHAT
  // ===========================================================================
  Widget _chatEntete() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _C.nuit2,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _C.violet.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _C.violet.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.smart_toy, color: _C.violet, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Coach Baobab', style: _serif(14, color: Colors.white)),
                const Text('En ligne · Réponds à tes questions',
                    style: TextStyle(color: _C.vert, fontSize: 10)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: _C.or, size: 18),
            onPressed: _regenererContenu,
            tooltip: 'Régénérer',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // LISTE DES MESSAGES (CHAT)
  // ===========================================================================
  Widget _listeMessages() {
    if (_historique.isEmpty && _contenuIA == null) {
      return const SizedBox.shrink();
    }

    return Container(
      constraints: const BoxConstraints(minHeight: 200, maxHeight: 450),
      decoration: BoxDecoration(
        color: _C.nuit3,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _C.violet.withOpacity(0.3)),
      ),
      child: ListView.builder(
        controller: _chatScroll,
        padding: const EdgeInsets.all(12),
        itemCount: _historique.length + ( _envoiEnCours ? 1 : 0),
        itemBuilder: (ctx, i) {
          // Indicateur d'envoi en dernier
          if (i == _historique.length && _envoiEnCours) {
            return _bulleChargement();
          }
          final msg = _historique[i];
          return _bulleMessage(msg);
        },
      ),
    );
  }

  Widget _bulleMessage(Map<String, dynamic> msg) {
    final estUser = msg['role'] == 'user';
    final contenu = msg['contenu']?.toString() ?? '';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
            estUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!estUser) ...[
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: _C.violet.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.smart_toy, color: _C.violet, size: 14),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: estUser
                    ? _C.or.withOpacity(0.2)
                    : _C.nuit2,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: estUser
                      ? _C.or.withOpacity(0.5)
                      : _C.violet.withOpacity(0.3),
                ),
              ),
              child: SelectableText(
                contenu,
                style: TextStyle(
                  color: estUser ? Colors.white : Colors.white70,
                  fontSize: 13,
                  height: 1.6,
                ),
              ),
            ),
          ),
          if (estUser) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: _C.or.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.person, color: _C.or, size: 14),
            ),
          ],
        ],
      ),
    );
  }

  Widget _bulleChargement() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: _C.violet.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.smart_toy, color: _C.violet, size: 14),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: _C.nuit2,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _C.violet.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: _C.violet),
                ),
                const SizedBox(width: 8),
                Text('Coach Baobab écrit...',
                    style: TextStyle(
                        color: Colors.white54,
                        fontSize: 11,
                        fontStyle: FontStyle.italic)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // ZONE DE SAISIE
  // ===========================================================================
  Widget _zoneSaisie() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: _C.nuit2,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _C.or.withOpacity(0.4), width: 1.5),
      ),
      child: Row(
        children: [
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _messageCtrl,
              enabled: !_envoiEnCours,
              maxLines: 3,
              minLines: 1,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: const InputDecoration(
                hintText: 'Tape ton message à Coach Baobab...',
                hintStyle: TextStyle(color: Colors.white38, fontSize: 12),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 10),
              ),
              onSubmitted: (_) => _envoyerMessage(),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.mic, color: _C.or, size: 22),
            onPressed: _envoiEnCours ? null : _dicterMessage,
            tooltip: 'Dicter un message',
          ),
          Container(
            decoration: BoxDecoration(
              color: _envoiEnCours ? Colors.white10 : _C.or,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: Icon(
                Icons.send,
                color: _envoiEnCours ? Colors.white38 : Colors.black,
                size: 20,
              ),
              onPressed: _envoiEnCours ? null : _envoyerMessage,
              tooltip: 'Envoyer',
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // RÉGÉNÉRER LE CONTENU
  // ===========================================================================
  Future<void> _regenererContenu() async {
    setState(() {
      _historique.clear();
      _contenuIA = null;
    });
    await _genererContenuAvecSauvegarde();
  }

  Future<void> _genererContenuAvecSauvegarde() async {
    setState(() => _chargementContenu = true);

    try {
      final contenu = await AiService.genererContenuModule(
        module: _module,
        apprenant: _apprenant,
      );

      setState(() {
        _contenuIA = contenu;
        _chargementContenu = false;
        _historique.add({
          'role': 'assistant',
          'contenu': contenu,
          'created_at': DateTime.now().toIso8601String(),
        });
      });

      if (_userId != null) {
        await AiService.sauvegarderConversation(
          userId: _userId!,
          moduleId: '${_module['id']}',
          moduleType: 'cursus',
          role: 'assistant',
          contenu: contenu,
        );
      }

      _scrollEnBas();
    } catch (e) {
      setState(() => _chargementContenu = false);
      _toast('Erreur IA : $e', rouge: true);
    }
  }

  // ===========================================================================
  // DICTÉE VOCALE (placeholder — à améliorer avec speech_to_text)
  // ===========================================================================
  void _dicterMessage() {
    _toast('Dictée vocale bientôt disponible');
  }

  Widget _tabRessources() {
    if (_ressources.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.inbox, color: Colors.white38, size: 48),
              SizedBox(height: 12),
              Text('Aucune ressource pour ce module',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white54, fontSize: 13)),
              SizedBox(height: 6),
              Text('Le coach IA te fournit tout le contenu nécessaire.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white38, fontSize: 11)),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _sectionTitle('📎 RESSOURCES OFFICIELLES'),
        const SizedBox(height: 10),
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
        color = _C.teal;
    }

    return InkWell(
      onTap: () => _openRessource(r),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _C.nuit2,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${r['titre']}',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w700)),
                  if (r['description'] != null)
                    Text('${r['description']}',
                        style: const TextStyle(
                            color: Colors.white54, fontSize: 11),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            Icon(Icons.open_in_new, color: color, size: 18),
          ],
        ),
      ),
    );
  }

  Future<void> _openRessource(Map<String, dynamic> r) async {
    final url = r['url']?.toString() ?? '';
    if (url.isEmpty) {
      _toast('Pas d\'URL');
      return;
    }
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}
  }

  // ===========================================================================
  // TAB 3 : QUIZ IA
  // ===========================================================================
  Widget _tabQuizIA() {
    // Vérifier le verrouillage
    if (!_quizDebloque) {
      return _quizVerrouille();
    }

    if (_chargementQuiz) {
      return Center(
        child: _loadingCard('Coach Baobab prépare ton quiz...'),
      );
    }

    if (_resultatQuiz != null) {
      return _resultatQuizUI();
    }

    if (_quizEnCours && _quizActuel != null) {
      return _quizQuestionUI();
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _C.or.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.quiz, color: _C.or, size: 48),
            ),
            const SizedBox(height: 20),
            Text('Évaluation par Coach IA',
                style: _serif(20, color: Colors.white)),
            const SizedBox(height: 8),
            const Text(
              'Ton coach va générer un quiz UNIQUE, adapté à ton niveau.\n\nLes questions sont différentes à chaque tentative.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: Colors.white70, fontSize: 13, height: 1.5),
            ),
            const SizedBox(height: 8),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _C.vert.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Seuil de validation : ${_module['ia_seuil'] ?? 85}%',
                style: const TextStyle(
                    color: _C.vert,
                    fontSize: 12,
                    fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _demarrerQuiz,
                icon: const Icon(Icons.auto_awesome, size: 18),
                label: const Text('DÉMARRER LE QUIZ',
                    style: TextStyle(
                        fontWeight: FontWeight.w900, fontSize: 13)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _C.or,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _quizVerrouille() {
    final messagesApprenant =
        _historique.where((m) => m['role'] == 'user').length;

    String message;
    if (_contenuIA == null) {
      message =
          'Commence par discuter avec Coach Baobab.\nIl va te présenter le module et te poser des questions.';
    } else if (messagesApprenant == 0) {
      message =
          'Réponds au moins une fois à Coach Baobab pour débloquer le quiz.\nIl t\'a posé des questions — prends le temps de réfléchir et de répondre.';
    } else {
      message = 'Discute encore un peu avec le coach.';
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _C.rouge.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.lock, color: _C.rouge, size: 48),
            ),
            const SizedBox(height: 20),
            Text('Quiz verrouillé',
                style: _serif(20, color: Colors.white)),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: Colors.white70, fontSize: 13, height: 1.5),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => setState(() => _currentTab = 0),
                icon: const Icon(Icons.smart_toy, size: 18),
                label: const Text('ALLER AU COACH IA',
                    style: TextStyle(
                        fontWeight: FontWeight.w900, fontSize: 12)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _C.violet,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _quizQuestionUI() {
    final questions = _quizActuel!['questions'] as List;
    final q = questions[_questionIndex];
    final qId = q['id']?.toString() ?? '$_questionIndex';
    final options = q['options'] as List;
    final progression = (_questionIndex + 1) / questions.length;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _C.nuit2,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.smart_toy,
                      color: _C.violet, size: 18),
                  const SizedBox(width: 8),
                  Text('Coach Baobab te questionne',
                      style: _serif(13, color: Colors.white)),
                  const Spacer(),
                  Text('${_questionIndex + 1}/${questions.length}',
                      style: const TextStyle(
                          color: _C.or,
                          fontSize: 14,
                          fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: progression,
                  minHeight: 6,
                  backgroundColor: Colors.white10,
                  valueColor:
                      const AlwaysStoppedAnimation(_C.or),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: _C.nuit3,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _C.or.withOpacity(0.4)),
          ),
          child: Text('${q['question']}',
              style: _serif(16, color: Colors.white)),
        ),
        const SizedBox(height: 20),
        ...options.map((opt) {
          final optId = opt['id']?.toString() ?? '';
          final optTexte = opt['texte']?.toString() ?? '';
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: InkWell(
              onTap: () => _repondreQuestion(qId, optId),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _C.nuit2,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: _C.or.withOpacity(0.3), width: 1.5),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: _C.or.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          optId.toUpperCase(),
                          style: const TextStyle(
                              color: _C.or,
                              fontSize: 14,
                              fontWeight: FontWeight.w900),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(optTexte,
                          style: const TextStyle(
                              color: Colors.white, fontSize: 14)),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _resultatQuizUI() {
    final r = _resultatQuiz!;
    final score = r['score'] ?? 0;
    final valide = r['valide'] == true;
    final feedback = r['feedback'] ?? '';
    final seuil = r['seuil'] ?? 85;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: valide
                  ? [_C.vert, const Color(0xFF0F4A2F)]
                  : [_C.rouge, const Color(0xFF8B2020)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Icon(
                valide ? Icons.check_circle : Icons.cancel,
                color: Colors.white,
                size: 60,
              ),
              const SizedBox(height: 16),
              Text('$score%',
                  style: _serif(48,
                      color: Colors.white, weight: FontWeight.w900)),
              const SizedBox(height: 4),
              Text(
                valide
                    ? 'Module validé !'
                    : 'Presque... (seuil $seuil%)',
                style: _serif(18, color: Colors.white),
              ),
              const SizedBox(height: 8),
              Text(
                '${r['bonnes_reponses']} / ${r['total']} bonnes réponses',
                style: const TextStyle(
                    color: Colors.white70, fontSize: 13),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Container(
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
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _C.violet.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.smart_toy,
                        color: _C.violet, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Text('Feedback de Coach Baobab',
                      style: _serif(14, color: Colors.white)),
                ],
              ),
              const SizedBox(height: 12),
              Text(feedback,
                  style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      height: 1.6)),
            ],
          ),
        ),
        const SizedBox(height: 20),
        if (valide)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
              },
              icon: const Icon(Icons.arrow_forward, size: 18),
              label: const Text('PASSER AU MODULE SUIVANT',
                  style: TextStyle(
                      fontWeight: FontWeight.w900, fontSize: 13)),
              style: ElevatedButton.styleFrom(
                backgroundColor: _C.vert,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
          )
        else
          Column(
            children: [
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _demarrerQuiz,
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('RÉESSAYER AVEC UN NOUVEAU QUIZ',
                      style: TextStyle(
                          fontWeight: FontWeight.w900, fontSize: 12)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _C.or,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Le nouveau quiz sera différent du précédent.',
                style: TextStyle(
                    color: Colors.white54, fontSize: 11),
              ),
            ],
          ),
      ],
    );
  }

  Widget _actionSuivant() {
    final dejaValide = _progress != null &&
        (_progress!['statut'] == 'termine' ||
            _progress!['statut'] == 'certifie');

    if (dejaValide) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _C.vert.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _C.vert.withOpacity(0.4)),
        ),
        child: Row(
          children: [
            const Icon(Icons.check_circle,
                color: _C.vert, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Tu as validé ce module ! Le suivant est déverrouillé.',
                style: const TextStyle(
                    color: _C.vert,
                    fontSize: 13,
                    fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _C.nuit3,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _C.or.withOpacity(0.4)),
      ),
      child: Column(
        children: [
          const Icon(Icons.info_outline, color: _C.or, size: 28),
          const SizedBox(height: 10),
          Text('Prêt pour l\'évaluation ?',
              style: _serif(16, color: Colors.white)),
          const SizedBox(height: 6),
          Text(
            'Passe le quiz pour valider ce module (seuil : ${_module['ia_seuil'] ?? 85}%)',
            textAlign: TextAlign.center,
            style: const TextStyle(
                color: Colors.white70, fontSize: 12, height: 1.5),
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: () => setState(() => _currentTab = 2),
            icon: const Icon(Icons.quiz, color: _C.or, size: 16),
            label: const Text('ALLER AU QUIZ',
                style: TextStyle(
                    color: _C.or,
                    fontSize: 12,
                    fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
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
  // ENVOYER UN MESSAGE AU COACH
  // ===========================================================================
  Future<void> _envoyerMessage() async {
    final message = _messageCtrl.text.trim();
    if (message.isEmpty || _envoiEnCours) return;

    // Ajouter le message de l'apprenant à l'historique local
    setState(() {
      _historique.add({
        'role': 'user',
        'contenu': message,
        'created_at': DateTime.now().toIso8601String(),
      });
      _messageCtrl.clear();
      _envoiEnCours = true;
    });

    // Scroll en bas
    _scrollEnBas();

    // Sauvegarder dans Supabase
    if (_userId != null) {
      await AiService.sauvegarderConversation(
        userId: _userId!,
        moduleId: '${_module['id']}',
        moduleType: 'cursus',
        role: 'user',
        contenu: message,
      );
    }

    try {
      // Construire l'historique pour l'IA (sans le message actuel qui est déjà dedans)
      final historiqueIA = _historique
          .where((m) => m['role'] == 'user' || m['role'] == 'assistant')
          .map((m) => {
                'role': m['role'] == 'user' ? 'Apprenant' : 'Coach',
                'contenu': m['contenu']?.toString() ?? '',
              })
          .toList();

      final reponse = await AiService.repondreQuestion(
        module: _module,
        questionApprenant: message,
        historique: historiqueIA,
        apprenant: _apprenant,
      );

      if (!mounted) return;

      setState(() {
        _historique.add({
          'role': 'assistant',
          'contenu': reponse,
          'created_at': DateTime.now().toIso8601String(),
        });
        _envoiEnCours = false;
      });

      // Sauvegarder la réponse du coach
      if (_userId != null) {
        await AiService.sauvegarderConversation(
          userId: _userId!,
          moduleId: '${_module['id']}',
          moduleType: 'cursus',
          role: 'assistant',
          contenu: reponse,
        );
      }

      _scrollEnBas();
    } catch (e) {
      setState(() {
        _envoiEnCours = false;
        _historique.add({
          'role': 'assistant',
          'contenu': 'Désolé, une erreur est survenue. Réessaie dans un instant.',
          'created_at': DateTime.now().toIso8601String(),
        });
      });
      _toast('Erreur : $e', rouge: true);
    }
  }

  void _scrollEnBas() {
    Future.delayed(const Duration(milliseconds: 200), () {
      if (_chatScroll.hasClients) {
        _chatScroll.animateTo(
          _chatScroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // ===========================================================================
  // CHARGER L'HISTORIQUE EXISTANT
  // ===========================================================================
  Future<void> _chargerHistorique() async {
    if (_userId == null) return;
    try {
      final hist = await AiService.chargerHistorique(
        userId: _userId!,
        moduleId: '${_module['id']}',
        moduleType: 'cursus',
      );
      if (hist.isNotEmpty && mounted) {
        setState(() {
          _historique = hist;
          _contenuIA = hist.firstWhere(
            (m) => m['role'] == 'assistant',
            orElse: () => {},
          )['contenu']?.toString();
        });
        _scrollEnBas();
      }
    } catch (_) {}
  }

  // ===========================================================================
  // LE QUIZ EST-IL DÉBLOQUÉ ?
  // ===========================================================================
  bool get _quizDebloque {
    // Le quiz est débloqué si :
    // 1. Le contenu a été généré
    // 2. L'apprenant a envoyé au moins 1 message
    final messagesApprenant =
        _historique.where((m) => m['role'] == 'user').length;
    return _contenuIA != null && messagesApprenant >= 1;
  }
}
