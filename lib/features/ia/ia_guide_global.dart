import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

// ---------------------------------------------------------------------------
// Palette de la Ligue : fond marine, accent or, cartes de lecture claires
// ---------------------------------------------------------------------------
class _C {
  static const bg = Color(0xFF080C1F); // fond de l'écran
  static const surface = Color(0xFF111735); // barre du haut et zone de saisie
  static const field = Color(0xFF1A2150); // champ de saisie, puces
  static const gold = Color(0xFFFFC400); // accent
  static const card = Color(0xFFF5F7FC); // carte de réponse de l'IA
  static const ink = Color(0xFF0B1230); // texte foncé
  static const muted = Color(0xFF5B6483);
  static const line = Color(0xFFD3D9EC);
}

enum _Kind { user, ai, error, result }

class _Msg {
  final _Kind kind;
  final String text;
  const _Msg(this.kind, this.text);
}

// ---------------------------------------------------------------------------
// Écran de chat. `const IAGuideGlobal()` fonctionne toujours (IA Guide).
// Pour un module : IAGuideGlobal(iaType: 'FORMATION' ou 'ECOLE', moduleId: '<uuid>', title: '...')
// ---------------------------------------------------------------------------
class IAGuideGlobal extends StatefulWidget {
  const IAGuideGlobal({
    super.key,
    this.iaType = 'GUIDE',
    this.moduleId,
    this.title = 'Guide IA',
    this.subtitle = 'République des Neurocitoyens',
  });

  final String iaType;
  final String? moduleId;
  final String title;
  final String subtitle;

  @override
  State<IAGuideGlobal> createState() => _IAGuideGlobalState();
}

class _IAGuideGlobalState extends State<IAGuideGlobal> {
  late final List<_Msg> _msgs;
  final _ctrl = TextEditingController();
  final _scroll = ScrollController();
  final _focus = FocusNode();
  bool _loading = false;
  String _lastUserText = '';

  bool get _isGuide => widget.iaType == 'GUIDE';

  List<String> get _suggestions => _isGuide
      ? const [
          "C'est quoi la neurocitoyenneté ?",
          'Comment fonctionne le parcours ?',
          'Quelles formations puis-je suivre ?',
          'Que contient la Charte ?',
        ]
      : const ['Bonjour, je suis prêt à commencer'];

  @override
  void initState() {
    super.initState();
    _msgs = [
      _Msg(
        _Kind.ai,
        _isGuide
            ? 'Bienvenue 🧠\n\nJe suis ton **Guide IA**. Je peux t\'expliquer la Charte, '
                'les institutions, le parcours, les écoles et les formations, '
                'et t\'orienter vers le bon module.\n\nPose ta question !'
            : 'Bienvenue 🧠\n\nJe suis ton **Professeur-Coach**. '
                'Dis-moi **Bonjour** pour commencer ce module.',
      ),
    ];
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _scroll.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _send(String raw, {bool retry = false}) async {
    final text = raw.trim();
    if (text.isEmpty || _loading) return;

    setState(() {
      if (retry) {
        if (_msgs.isNotEmpty && _msgs.last.kind == _Kind.error) _msgs.removeLast();
      } else {
        _msgs.add(_Msg(_Kind.user, text));
      }
      _loading = true;
    });
    _lastUserText = text;
    if (!retry) _ctrl.clear();
    _scrollToEnd();

    try {
      final res = await Supabase.instance.client.functions.invoke('ia-chat', body: {
        'message': text,
        'ia_type': widget.iaType,
        if (widget.moduleId != null) 'module_id': widget.moduleId,
      });

      final data = res.data;
      String answer = '';
      Map? resultat;
      if (data is Map) {
        answer = (data['reponse'] ?? data['response'] ?? data['text'] ?? '').toString();
        if (data['resultat'] is Map) resultat = data['resultat'] as Map;
      }
      if (answer.trim().isEmpty) {
        answer = "Je n'ai pas pu formuler de réponse. Peux-tu reformuler ?";
      }

      if (!mounted) return;
      setState(() {
        _msgs.add(_Msg(_Kind.ai, answer));
        if (resultat != null) {
          final ok = resultat['valide'] == true;
          final verdict = ok ? 'Module validé ✅' : 'À revoir 🔁';
          _msgs.add(_Msg(
            _Kind.result,
            '🎯 Résultat : ${resultat['score']}/${resultat['total']} '
            '(${resultat['pourcentage']} %) · $verdict',
          ));
        }
      });
    } on FunctionException catch (e) {
      String msg;
      if (e.status == 401) {
        msg = 'Ta session a expiré. Reconnecte-toi puis réessaie.';
      } else if (e.status == 502) {
        msg = "L'assistant est momentanément indisponible. Réessaie dans un instant.";
      } else {
        msg = 'Une erreur est survenue (code ${e.status}). Réessaie.';
      }
      if (mounted) setState(() => _msgs.add(_Msg(_Kind.error, msg)));
    } catch (_) {
      if (mounted) {
        setState(() => _msgs.add(
              const _Msg(_Kind.error, 'Connexion impossible. Vérifie ton réseau puis réessaie.'),
            ));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
      _scrollToEnd();
    }
  }

  void _copy(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Réponse copiée'), duration: Duration(seconds: 1)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final showChips = _msgs.length == 1 && !_loading;
    final maxW = math.min(MediaQuery.of(context).size.width, 820.0) * 0.84;

    return Scaffold(
      backgroundColor: _C.bg,
      appBar: AppBar(
        backgroundColor: _C.surface,
        foregroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.canPop() ? context.pop() : context.go('/'),
        ),
        titleSpacing: 0,
        title: Row(children: [
          const _Avatar(size: 34),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(widget.title,
                  style: const TextStyle(
                      color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
              Text(widget.subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white60, fontSize: 11)),
            ]),
          ),
        ]),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: _C.gold.withOpacity(0.35)),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 820),
            child: Column(children: [
              Expanded(
                child: SelectionArea(
                  child: ListView.builder(
                    controller: _scroll,
                    padding: const EdgeInsets.fromLTRB(12, 16, 12, 8),
                    itemCount: _msgs.length + (_loading ? 1 : 0),
                    itemBuilder: (context, i) {
                      if (i == _msgs.length) return const _TypingBubble();
                      final m = _msgs[i];
                      if (m.kind == _Kind.user) return _UserBubble(text: m.text, maxW: maxW);
                      if (m.kind == _Kind.error) {
                        return _ErrorBubble(
                          text: m.text,
                          onRetry: () => _send(_lastUserText, retry: true),
                        );
                      }
                      if (m.kind == _Kind.result) return _ResultPill(text: m.text);
                      return _AiBubble(text: m.text, maxW: maxW, onCopy: () => _copy(m.text));
                    },
                  ),
                ),
              ),
              if (showChips) _buildChips(),
              _buildInputBar(),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _buildChips() => Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Wrap(spacing: 8, runSpacing: 8, children: [
            for (final s in _suggestions)
              ActionChip(
                label: Text(s, style: const TextStyle(color: Colors.white, fontSize: 13)),
                backgroundColor: _C.field,
                side: BorderSide(color: _C.gold.withOpacity(0.6)),
                onPressed: () => _send(s),
              ),
          ]),
        ),
      );

  Widget _buildInputBar() => Container(
        decoration: const BoxDecoration(
          color: _C.surface,
          border: Border(top: BorderSide(color: Color(0x22FFFFFF))),
        ),
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Expanded(
            child: TextField(
              controller: _ctrl,
              focusNode: _focus,
              minLines: 1,
              maxLines: 4,
              keyboardType: TextInputType.text,
              textInputAction: TextInputAction.send,
              onSubmitted: (v) {
                _send(v);
                _focus.requestFocus();
              },
              cursorColor: _C.gold,
              style: const TextStyle(color: Colors.white, fontSize: 15),
              decoration: InputDecoration(
                hintText: 'Pose ta question…',
                hintStyle: const TextStyle(color: Colors.white54, fontSize: 14),
                filled: true,
                fillColor: _C.field,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton.filled(
            onPressed: _loading ? null : () => _send(_ctrl.text),
            icon: const Icon(Icons.send_rounded),
            style: IconButton.styleFrom(
              backgroundColor: _C.gold,
              foregroundColor: _C.ink,
              disabledBackgroundColor: _C.gold.withOpacity(0.35),
              disabledForegroundColor: _C.ink.withOpacity(0.5),
              minimumSize: const Size(46, 46),
            ),
          ),
        ]),
      );
}

// ---------------------------------------------------------------------------
// Style Markdown : texte foncé sur carte claire, tableaux défilants et lisibles
// ---------------------------------------------------------------------------
MarkdownStyleSheet _mdStyle(BuildContext context) {
  final base = MarkdownStyleSheet.fromTheme(Theme.of(context));
  return base.copyWith(
    p: const TextStyle(color: _C.ink, fontSize: 15, height: 1.5),
    h1: const TextStyle(color: _C.ink, fontSize: 20, fontWeight: FontWeight.w800, height: 1.3),
    h2: const TextStyle(color: _C.ink, fontSize: 18, fontWeight: FontWeight.w800, height: 1.3),
    h3: const TextStyle(color: _C.ink, fontSize: 16, fontWeight: FontWeight.w700, height: 1.3),
    strong: const TextStyle(color: _C.ink, fontWeight: FontWeight.w700),
    em: const TextStyle(color: _C.ink, fontStyle: FontStyle.italic),
    a: const TextStyle(color: Color(0xFF1D4ED8), decoration: TextDecoration.underline),
    listBullet: const TextStyle(color: _C.ink, fontSize: 15),
    listIndent: 20,
    blockSpacing: 10,
    blockquote: const TextStyle(color: _C.ink, fontSize: 15, height: 1.5),
    blockquotePadding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
    blockquoteDecoration: BoxDecoration(
      color: const Color(0xFFFFF4CC),
      borderRadius: BorderRadius.circular(6),
      border: const Border(left: BorderSide(color: _C.gold, width: 4)),
    ),
    code: const TextStyle(
      color: _C.ink,
      backgroundColor: Color(0xFFE6EAF6),
      fontFamily: 'monospace',
      fontSize: 13,
    ),
    codeblockDecoration: BoxDecoration(
      color: const Color(0xFFE6EAF6),
      borderRadius: BorderRadius.circular(8),
    ),
    horizontalRuleDecoration: const BoxDecoration(
      border: Border(top: BorderSide(color: _C.line, width: 1)),
    ),
    // Tableaux : bordures fines, cellules blanches, défilement horizontal automatique
    tableHead: const TextStyle(color: _C.ink, fontWeight: FontWeight.w800, fontSize: 13),
    tableBody: const TextStyle(color: _C.ink, fontSize: 13, height: 1.4),
    tableBorder: TableBorder.all(color: _C.line, width: 1, borderRadius: BorderRadius.circular(8)),
    tableCellsPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    tableCellsDecoration: const BoxDecoration(color: Colors.white),
    tableColumnWidth: const IntrinsicColumnWidth(),
  );
}

// ---------------------------------------------------------------------------
// Éléments visuels
// ---------------------------------------------------------------------------
class _Avatar extends StatelessWidget {
  const _Avatar({this.size = 30});
  final double size;

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(color: _C.gold, shape: BoxShape.circle),
        child: Icon(Icons.psychology_alt_rounded, color: _C.ink, size: size * 0.62),
      );
}

class _UserBubble extends StatelessWidget {
  const _UserBubble({required this.text, required this.maxW});
  final String text;
  final double maxW;

  @override
  Widget build(BuildContext context) => Align(
        alignment: Alignment.centerRight,
        child: Container(
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          constraints: BoxConstraints(maxWidth: maxW),
          decoration: const BoxDecoration(
            color: _C.gold,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(18),
              topRight: Radius.circular(18),
              bottomLeft: Radius.circular(18),
              bottomRight: Radius.circular(4),
            ),
          ),
          child: Text(text,
              style: const TextStyle(
                  color: _C.ink, fontSize: 15, height: 1.4, fontWeight: FontWeight.w500)),
        ),
      );
}

class _AiBubble extends StatelessWidget {
  const _AiBubble({required this.text, required this.maxW, required this.onCopy});
  final String text;
  final double maxW;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const _Avatar(),
          const SizedBox(width: 8),
          Flexible(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxW),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                  decoration: const BoxDecoration(
                    color: _C.card,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(4),
                      topRight: Radius.circular(18),
                      bottomLeft: Radius.circular(18),
                      bottomRight: Radius.circular(18),
                    ),
                  ),
                  child: MarkdownBody(
                    data: text,
                    softLineBreak: true,
                    styleSheet: _mdStyle(context),
                    onTapLink: (label, href, title) {
                      if (href == null) return;
                      final uri = Uri.tryParse(href);
                      if (uri != null) launchUrl(uri, mode: LaunchMode.externalApplication);
                    },
                  ),
                ),
                TextButton.icon(
                  onPressed: onCopy,
                  icon: const Icon(Icons.copy_rounded, size: 14),
                  label: const Text('Copier', style: TextStyle(fontSize: 12)),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white54,
                    minimumSize: Size.zero,
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ]),
            ),
          ),
        ]),
      );
}

class _ErrorBubble extends StatelessWidget {
  const _ErrorBubble({required this.text, required this.onRetry});
  final String text;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const _Avatar(),
          const SizedBox(width: 8),
          Flexible(
            child: Container(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
              decoration: BoxDecoration(
                color: const Color(0xFFFDECEC),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE5A3A3)),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(text,
                    style: const TextStyle(color: Color(0xFF7A1F1F), fontSize: 14, height: 1.4)),
                TextButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh_rounded, size: 16),
                  label: const Text('Réessayer'),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF7A1F1F),
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(0, 32),
                  ),
                ),
              ]),
            ),
          ),
        ]),
      );
}

class _ResultPill extends StatelessWidget {
  const _ResultPill({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) => Center(
        child: Container(
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: _C.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _C.gold),
          ),
          child: Text(text,
              style: const TextStyle(
                  color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
        ),
      );
}

class _TypingBubble extends StatefulWidget {
  const _TypingBubble();

  @override
  State<_TypingBubble> createState() => _TypingBubbleState();
}

class _TypingBubbleState extends State<_TypingBubble> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Row(children: [
          const _Avatar(),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: _C.card,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              for (int i = 0; i < 3; i++)
                AnimatedBuilder(
                  animation: _c,
                  builder: (_, __) {
                    final t = (_c.value - i * 0.2) % 1.0;
                    final o = 0.25 + 0.75 * (t < 0.5 ? t * 2 : (1 - t) * 2);
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _C.ink.withOpacity(o),
                        shape: BoxShape.circle,
                      ),
                    );
                  },
                ),
            ]),
          ),
        ]),
      );
}