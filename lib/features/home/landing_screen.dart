import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/l10n.dart';
import '../../widgets/africa_map.dart';

// ---------------------------------------------------------------------------
// Chiffres affichés sur l'accueil : modifiez-les ici.
// ---------------------------------------------------------------------------
const int kCites = 55;
const int kNbRegions = 5;
const int kNiveaux = 6;
const int kPoles = 21;
const int kGrades = 7;
const String kCoopVersion = 'V2.0';

// ---------------------------------------------------------------------------
// Palette institutionnelle : marine, ivoire, or, émeraude
// ---------------------------------------------------------------------------
class _C {
  static const nuit = Color(0xFF0A1330);
  static const nuit2 = Color(0xFF111C45);
  static const ivoire = Color(0xFFF7F3EA);
  static const ivoire2 = Color(0xFFEDE6D3);
  static const encre = Color(0xFF0E1630); // titres sur fond clair
  static const texte = Color(0xFF3B4466); // paragraphes sur fond clair
  static const or = Color(0xFFD9AE45); // or sur fond sombre
  static const orFonce = Color(0xFF8A6417); // or sur fond clair
  static const orClair = Color(0xFFF0D9A0);
  static const emeraude = Color(0xFF0C4A3E);
  static const emeraude2 = Color(0xFF0F5C4D);
}

TextStyle _serif(double size,
    {Color color = Colors.white,
    FontWeight weight = FontWeight.w700,
    double? height,
    double? spacing}) {
  return TextStyle(
    fontFamily: 'Georgia',
    fontFamilyFallback: const ['Times New Roman', 'serif'],
    fontSize: size,
    color: color,
    fontWeight: weight,
    height: height,
    letterSpacing: spacing,
  );
}

bool _wide(BuildContext c) => MediaQuery.of(c).size.width >= 860;

// Grille responsive : une ligne sur grand écran, une colonne sur mobile
Widget _grid(BuildContext context, List<Widget> kids, {double gap = 18}) {
  if (!_wide(context)) {
    return Column(children: [
      for (var i = 0; i < kids.length; i++) ...[
        if (i > 0) SizedBox(height: gap),
        kids[i],
      ],
    ]);
  }
  return IntrinsicHeight(
    child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      for (var i = 0; i < kids.length; i++) ...[
        if (i > 0) SizedBox(width: gap),
        Expanded(child: kids[i]),
      ],
    ]),
  );
}

// =============================================================================
// ÉCRAN D'ACCUEIL
// =============================================================================
class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});
  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen> {
  final GlobalKey _mapKey = GlobalKey();
  String? _selected;
  String? _region;
  bool _org = false;
  String _paysSelectionne = 'BJ';
  bool _logged = false;

  @override
  void initState() {
    super.initState();
    _checkLogin();
  }

  Future<void> _checkLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final pays = prefs.getString('pays_id') ?? 'BJ';
    if (mounted) {
      setState(() {
        _logged = prefs.getString('code_parrain') != null;
        _paysSelectionne = pays;
      });
    }
  }

  void _goToMap() {
    final ctx = _mapKey.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(ctx,
          duration: const Duration(milliseconds: 600), curve: Curves.easeInOutCubic);
    }
  }

  void _goLogin() => context.go(_logged ? '/dashboard' : '/connexion');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.nuit,
      appBar: AppBar(
        backgroundColor: _C.nuit,
        foregroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        titleSpacing: 16,
        title: Row(children: [
          Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
                color: Colors.white, borderRadius: BorderRadius.circular(8)),
            child: Image.asset('assets/logo_ligue.jpg',
                width: 26, height: 26, fit: BoxFit.contain),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Text(L10n.t('ligue'),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                    color: Colors.white)),
          ),
        ]),
        actions: [
          IconButton(
              tooltip: 'IA Guide',
              icon: const Icon(Icons.smart_toy_outlined, color: _C.or),
              onPressed: () => context.go('/ia-guide')),
          const SizedBox(width: 4),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: _C.or.withOpacity(0.35)),
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: _C.nuit,
          border: Border(top: BorderSide(color: _C.or.withOpacity(0.35))),
        ),
        child: SafeArea(
          top: false,
          child: BottomNavigationBar(
            backgroundColor: _C.nuit,
            elevation: 0,
            selectedItemColor: _C.or,
            unselectedItemColor: Colors.white54,
            selectedFontSize: 12,
            unselectedFontSize: 12,
            type: BottomNavigationBarType.fixed,
            currentIndex: 0,
            onTap: (i) => context
                .go(['/', '/carte', '/dashboard', '/modules', '/profil'][i]),
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Accueil'),
              BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Cités'),
              BottomNavigationBarItem(
                  icon: Icon(Icons.dashboard), label: 'Board'),
              BottomNavigationBarItem(
                  icon: Icon(Icons.school), label: 'Modules'),
              BottomNavigationBarItem(
                  icon: Icon(Icons.person), label: 'Profil'),
            ],
          ),
        ),
      ),
      body: ListView(
        children: [
          _Hero(logged: _logged, onJoin: _goToMap, onLogin: _goLogin),
          KeyedSubtree(
            key: _mapKey,
            child: _MapSection(
              selectedId: _selected,
              highlightRegion: _region,
              showOrg: _org,
              onRegion: (r) => setState(() => _region = r),
              onOrg: (v) => setState(() => _org = v),
              onCountryTap: (c) {
                setState(() {
                  _selected = c.id;
                  _paysSelectionne = c.a2;
                });
                showCountrySheet(context, c);
              },
            ),
          ),
          const _ConstatSection(),
          const _DemarcheSection(),
          const _EconomieSection(),
          const _StatsBand(),
          _CtaFinal(logged: _logged, onJoin: _goToMap, onLogin: _goLogin),
          const _Footer(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
          onPressed: () => context.go('/ia-guide'),
          backgroundColor: _C.or,
          foregroundColor: _C.nuit,
          icon: const Icon(Icons.smart_toy_outlined),
          label: const Text('IA Guide',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12))),
    );
  }
}

// =============================================================================
// BRIQUES COMMUNES
// =============================================================================
class _Section extends StatelessWidget {
  const _Section({required this.color, required this.child, this.vertical = 72});
  final Color color;
  final Widget child;
  final double vertical;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        color: color,
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: vertical),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1100),
            child: child,
          ),
        ),
      );
}

class _Kicker extends StatelessWidget {
  const _Kicker(this.text, {required this.color});
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 28, height: 2, color: color),
        const SizedBox(width: 10),
        Flexible(
          child: Text(text,
              style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2.6)),
        ),
      ]);
}

class _H2 extends StatelessWidget {
  const _H2(this.text, {required this.color});
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Text(text,
      style: _serif(_wide(context) ? 40 : 28, color: color, height: 1.15));
}

enum _BtnKind { gold, navy, outlineLight, outlineDark }

class _Btn extends StatelessWidget {
  const _Btn(this.label, this.onTap, {this.icon, this.kind = _BtnKind.gold});
  final String label;
  final VoidCallback onTap;
  final IconData? icon;
  final _BtnKind kind;

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    BorderSide side = BorderSide.none;
    switch (kind) {
      case _BtnKind.gold:
        bg = _C.or;
        fg = _C.nuit;
        break;
      case _BtnKind.navy:
        bg = _C.nuit;
        fg = Colors.white;
        break;
      case _BtnKind.outlineLight:
        bg = Colors.transparent;
        fg = Colors.white;
        side = const BorderSide(color: Colors.white54, width: 1.5);
        break;
      case _BtnKind.outlineDark:
        bg = Colors.transparent;
        fg = _C.nuit;
        side = const BorderSide(color: _C.nuit, width: 1.5);
        break;
    }
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: bg,
        foregroundColor: fg,
        elevation: 0,
        minimumSize: const Size(0, 54),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10), side: side),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Text(label,
            style: const TextStyle(
                fontWeight: FontWeight.w800, fontSize: 13, letterSpacing: 1.2)),
        if (icon != null) ...[
          const SizedBox(width: 10),
          Icon(icon, size: 18),
        ],
      ]),
    );
  }
}

// =============================================================================
// 1. HERO
// =============================================================================
class _Hero extends StatelessWidget {
  const _Hero({required this.logged, required this.onJoin, required this.onLogin});
  final bool logged;
  final VoidCallback onJoin;
  final VoidCallback onLogin;

  @override
  Widget build(BuildContext context) {
    final wide = _wide(context);
    return ClipRect(
      child: Stack(children: [
        const Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [_C.nuit, _C.nuit2],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
        ),
        Positioned(
          right: -140,
          top: -120,
          child: IgnorePointer(
            child: CustomPaint(size: const Size(560, 560), painter: _RingsPainter()),
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: wide ? 104 : 60),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1100),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const _Kicker('LIGUE PANAFRICAINE DES NEUROCITOYENS', color: _C.or),
                const SizedBox(height: 24),
                Text.rich(
                  TextSpan(
                    style: _serif(wide ? 64 : 37, weight: FontWeight.w800, height: 1.06),
                    children: const [
                      TextSpan(text: 'Libérons les esprits.\nBâtissons l’économie\n'),
                      TextSpan(text: 'de nos Cités.', style: TextStyle(color: _C.or)),
                    ],
                  ),
                ),
                const SizedBox(height: 26),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 700),
                  child: Text(
                    'Une Ligue panafricaine qui déconstruit les schémas cognitivo-comportementaux '
                    'freinant l’épanouissement de chacun et le développement de tous, pour leur '
                    'substituer l’intégrité, l’intelligence émotionnelle et la coopération, puis '
                    'les traduire en coopératives, en emplois et en autonomie.',
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.84),
                        fontSize: wide ? 19 : 16.5,
                        height: 1.65),
                  ),
                ),
                const SizedBox(height: 34),
                Wrap(spacing: 12, runSpacing: 12, children: [
                  _Btn('REJOINDRE MA CITÉ', onJoin, icon: Icons.arrow_forward_rounded),
                  _Btn(logged ? 'MON ESPACE' : 'SE CONNECTER', onLogin,
                      icon: logged ? Icons.dashboard_outlined : Icons.login,
                      kind: _BtnKind.outlineLight),
                ]),
                const SizedBox(height: 44),
                Wrap(spacing: 14, runSpacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: [
                  for (final (i, t) in ['Conscience', 'Intégrité', 'Autonomie'].indexed) ...[
                    if (i > 0)
                      Container(
                          width: 5,
                          height: 5,
                          decoration: const BoxDecoration(color: _C.or, shape: BoxShape.circle)),
                    Text(t.toUpperCase(),
                        style: const TextStyle(
                            color: _C.orClair,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 2.4)),
                  ],
                ]),
              ]),
            ),
          ),
        ),
      ]),
    );
  }
}

class _RingsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = _C.or.withOpacity(0.14);
    final c = size.center(Offset.zero);
    for (var i = 1; i <= 5; i++) {
      canvas.drawCircle(c, size.width / 2 * i / 5, p);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// =============================================================================
// 2. CARTE DES CITÉS
// =============================================================================
class _MapSection extends StatelessWidget {
  const _MapSection({
    required this.selectedId,
    required this.highlightRegion,
    required this.showOrg,
    required this.onRegion,
    required this.onOrg,
    required this.onCountryTap,
  });

  final String? selectedId;
  final String? highlightRegion;
  final bool showOrg;
  final void Function(String?) onRegion;
  final void Function(bool) onOrg;
  final void Function(CountryShape) onCountryTap;

  @override
  Widget build(BuildContext context) {
    return _Section(
      color: _C.ivoire,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const _Kicker('LES CITÉS', color: _C.orFonce),
        const SizedBox(height: 14),
        const _H2('Choisissez votre Cité.', color: _C.encre),
        const SizedBox(height: 12),
        const Row(children: [
          Icon(Icons.touch_app_outlined, size: 18, color: _C.orFonce),
          SizedBox(width: 8),
          Expanded(
            child: Text('Touchez votre pays pour ouvrir sa fiche et rejoindre votre Cité.',
                style: TextStyle(color: _C.texte, fontSize: 15, height: 1.4)),
          ),
        ]),
        const SizedBox(height: 26),
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 820),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _C.ivoire2),
                boxShadow: const [
                  BoxShadow(color: Color(0x14000000), blurRadius: 24, offset: Offset(0, 10)),
                ],
              ),
              child: Column(children: [
                Row(children: [
                  const Expanded(
                    child: Text('CARTE DES CITÉS',
                        style: TextStyle(
                            color: _C.orFonce,
                            letterSpacing: 2.5,
                            fontSize: 12,
                            fontWeight: FontWeight.w800)),
                  ),
                  const Text('Organigramme',
                      style: TextStyle(
                          color: _C.texte, fontSize: 12.5, fontWeight: FontWeight.w600)),
                  Switch(value: showOrg, activeColor: _C.nuit, onChanged: onOrg),
                ]),
                const SizedBox(height: 6),
                AfricaMap(
                  highlightRegion: highlightRegion,
                  selectedId: selectedId,
                  showOrg: showOrg,
                  onCountryTap: onCountryTap,
                ),
                const SizedBox(height: 18),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _RegionChip(
                      label: 'Toutes',
                      color: _C.nuit,
                      selected: highlightRegion == null,
                      onTap: () => onRegion(null),
                    ),
                    for (final r in kRegions.values)
                      _RegionChip(
                        label: r.name,
                        color: r.color,
                        selected: highlightRegion == r.code,
                        onTap: () => onRegion(highlightRegion == r.code ? null : r.code),
                      ),
                  ],
                ),
              ]),
            ),
          ),
        ),
        const SizedBox(height: 26),
        Center(
          child: _Btn('VOIR TOUTES LES CITÉS', () => context.go('/carte'),
              icon: Icons.map_outlined, kind: _BtnKind.navy),
        ),
      ]),
    );
  }
}

// Chip de région dessinée à la main : couleurs imposées, toujours lisible
class _RegionChip extends StatelessWidget {
  const _RegionChip({
    required this.label,
    required this.color,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: selected ? color : Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: color, width: 1.5),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            if (selected)
              const Padding(
                padding: EdgeInsets.only(right: 6),
                child: Icon(Icons.check, size: 15, color: Colors.white),
              )
            else
              Container(
                width: 9,
                height: 9,
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
            Text(label,
                style: TextStyle(
                    color: selected ? Colors.white : _C.encre,
                    fontSize: 13,
                    fontWeight: FontWeight.w700)),
          ]),
        ),
      ),
    );
  }
}

// =============================================================================
// 3. LE CONSTAT
// =============================================================================
class _ConstatSection extends StatelessWidget {
  const _ConstatSection();

  @override
  Widget build(BuildContext context) {
    return _Section(
      color: _C.nuit,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const _Kicker('LE CONSTAT', color: _C.or),
        const SizedBox(height: 14),
        const _H2('Avant de reconstruire la Cité, brisons les murs invisibles de nos esprits.',
            color: Colors.white),
        const SizedBox(height: 38),
        _grid(context, const [
          _InfoCard(
            icon: Icons.lock_outline,
            title: 'Le fatalisme',
            text: '« Ici, rien ne changera. » Une croyance qui paralyse l’action '
                'avant même qu’elle ne commence.',
          ),
          _InfoCard(
            icon: Icons.person_outline,
            title: 'L’individualisme',
            text: 'Des réflexes centrés sur le moi, au détriment du nous, qui '
                'empêchent la coopération.',
          ),
          _InfoCard(
            icon: Icons.shield_outlined,
            title: 'La peur',
            text: 'Des peurs qui figent les potentiels, individuels comme collectifs.',
          ),
        ]),
        const SizedBox(height: 40),
        Container(
          padding: const EdgeInsets.fromLTRB(22, 6, 0, 6),
          decoration: const BoxDecoration(
            border: Border(left: BorderSide(color: _C.or, width: 4)),
          ),
          child: Text('Prendre conscience, c’est déjà briser la prison intérieure.',
              style: _serif(_wide(context) ? 28 : 22,
                      color: _C.orClair, weight: FontWeight.w600, height: 1.3)
                  .copyWith(fontStyle: FontStyle.italic)),
        ),
      ]),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.icon, required this.title, required this.text});
  final IconData icon;
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _C.or.withOpacity(0.28)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(color: _C.or.withOpacity(0.15), shape: BoxShape.circle),
            child: Icon(icon, color: _C.or, size: 24),
          ),
          const SizedBox(height: 16),
          Text(title, style: _serif(21)),
          const SizedBox(height: 8),
          Text(text,
              style: TextStyle(
                  color: Colors.white.withOpacity(0.78), height: 1.6, fontSize: 15)),
        ]),
      );
}

// =============================================================================
// 4. NOTRE DÉMARCHE
// =============================================================================
class _DemarcheSection extends StatelessWidget {
  const _DemarcheSection();

  @override
  Widget build(BuildContext context) {
    return _Section(
      color: _C.ivoire,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const _Kicker('NOTRE DÉMARCHE', color: _C.orFonce),
        const SizedBox(height: 14),
        const _H2('Déconstruire. Reconstruire. Entreprendre ensemble.', color: _C.encre),
        const SizedBox(height: 16),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: const Text(
            'La Ligue offre à chaque neurocitoyen un chemin de transformation : comprendre '
            'les schémas cognitivo-comportementaux qui freinent l’épanouissement individuel '
            'et le développement collectif, puis bâtir de nouveaux schèmes — intégrité, '
            'intelligence émotionnelle, confiance, coopération.',
            style: TextStyle(color: _C.texte, fontSize: 16.5, height: 1.7),
          ),
        ),
        const SizedBox(height: 38),
        _grid(context, const [
          _StepCard(
            number: '01',
            title: 'Déconstruire',
            text: 'Repérer et désamorcer les croyances, réflexes et peurs hérités qui '
                'limitent l’épanouissement de chacun et le progrès de tous.',
          ),
          _StepCard(
            number: '02',
            title: 'Reconstruire',
            text: 'Installer de nouveaux schèmes : intégrité, intelligence émotionnelle, '
                'confiance et esprit de coopération.',
          ),
          _StepCard(
            number: '03',
            title: 'Entreprendre ensemble',
            text: 'Traduire ces acquis en actions collectives au service de la '
                'communauté, par l’économie sociale et circulaire.',
          ),
        ]),
      ]),
    );
  }
}

class _StepCard extends StatelessWidget {
  const _StepCard({required this.number, required this.title, required this.text});
  final String number;
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(26),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _C.ivoire2),
          boxShadow: const [
            BoxShadow(color: Color(0x0F000000), blurRadius: 18, offset: Offset(0, 8)),
          ],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(number, style: _serif(44, color: _C.or, weight: FontWeight.w900)),
          const SizedBox(height: 10),
          Text(title, style: _serif(22, color: _C.encre)),
          const SizedBox(height: 10),
          Text(text, style: const TextStyle(color: _C.texte, height: 1.6, fontSize: 15)),
        ]),
      );
}

// =============================================================================
// 5. ÉCONOMIE SOCIALE ET CIRCULAIRE
// =============================================================================
class _EconomieSection extends StatelessWidget {
  const _EconomieSection();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [_C.emeraude, _C.emeraude2],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 72),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const _Kicker('ÉCONOMIE SOCIALE ET CIRCULAIRE', color: _C.or),
            const SizedBox(height: 14),
            const _H2('La coopérative : l’entreprise collective de la Cité.',
                color: Colors.white),
            const SizedBox(height: 16),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 780),
              child: Text(
                'Changer les mentalités ne suffit pas : il faut des structures qui transforment '
                'les conditions de vie. La Ligue place l’économie sociale et circulaire au cœur '
                'de son action. Les coopératives, entreprises détenues et pilotées collectivement '
                'par leurs membres, portent le leadership économique local, créent de l’emploi et '
                'font circuler la richesse au sein de la communauté.',
                style: TextStyle(
                    color: Colors.white.withOpacity(0.86), fontSize: 16.5, height: 1.7),
              ),
            ),
            const SizedBox(height: 36),
            _grid(context, const [
              _EcoTile(
                title: 'Leadership économique',
                text: 'Former des neurocitoyens capables de piloter des entreprises collectives.',
              ),
              _EcoTile(
                title: 'Emploi local',
                text: 'Créer des activités et des emplois ancrés dans chaque communauté.',
              ),
              _EcoTile(
                title: 'Richesse partagée',
                text: 'Une valeur produite ensemble, réinvestie et mise en circulation localement.',
              ),
              _EcoTile(
                title: 'Autonomie',
                text: 'Des neurocitoyens acteurs de leur autonomie, y compris financière.',
              ),
            ], gap: 14),
            const SizedBox(height: 44),
            const _Chain(),
            const SizedBox(height: 18),
            Text(
              'Par ricochet, chaque coopérative renforce la Cité qui la porte, '
              'puis le pays tout entier.',
              style: TextStyle(
                  color: _C.orClair.withOpacity(0.95), fontSize: 15, height: 1.5),
            ),
          ]),
        ),
      ),
    );
  }
}

class _EcoTile extends StatelessWidget {
  const _EcoTile({required this.title, required this.text});
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withOpacity(0.16)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(width: 36, height: 3, color: _C.or),
          const SizedBox(height: 14),
          Text(title, style: _serif(18, color: _C.orClair)),
          const SizedBox(height: 8),
          Text(text,
              style: TextStyle(
                  color: Colors.white.withOpacity(0.82), fontSize: 14.5, height: 1.55)),
        ]),
      );
}

class _Chain extends StatelessWidget {
  const _Chain();

  static const _items = ['Le neurocitoyen', 'La communauté', 'La Cité', 'Le pays'];

  @override
  Widget build(BuildContext context) {
    final wide = _wide(context);
    Widget arrow(IconData icon) => Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(icon, color: _C.or, size: 22),
        );
    final nodes = [
      for (var i = 0; i < _items.length; i++)
        _ChainNode(_items[i], last: i == _items.length - 1),
    ];
    if (wide) {
      return Row(children: [
        for (var i = 0; i < nodes.length; i++) ...[
          if (i > 0) arrow(Icons.arrow_forward_rounded),
          Expanded(child: nodes[i]),
        ],
      ]);
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      for (var i = 0; i < nodes.length; i++) ...[
        if (i > 0) arrow(Icons.arrow_downward_rounded),
        nodes[i],
      ],
    ]);
  }
}

class _ChainNode extends StatelessWidget {
  const _ChainNode(this.label, {required this.last});
  final String label;
  final bool last;

  @override
  Widget build(BuildContext context) => Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
        decoration: BoxDecoration(
          color: last ? _C.or : Colors.white.withOpacity(0.07),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _C.or.withOpacity(last ? 1 : 0.5)),
        ),
        child: Text(label,
            textAlign: TextAlign.center,
            style: _serif(18, color: last ? _C.nuit : Colors.white)),
      );
}

// =============================================================================
// 6. BANDE DE CHIFFRES
// =============================================================================
class _StatsBand extends StatelessWidget {
  const _StatsBand();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: _C.nuit,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 48),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: const Wrap(
            alignment: WrapAlignment.spaceEvenly,
            runSpacing: 28,
            spacing: 44,
            children: [
              _Stat(value: kCites, label: 'Cités'),
              _Stat(value: kNbRegions, label: 'Régions'),
              _Stat(value: kNiveaux, label: 'Niveaux'),
              _Stat(value: kPoles, label: 'Pôles'),
              _Stat(value: kGrades, label: 'Grades'),
              _Stat(text: kCoopVersion, label: 'Modèle coopératif'),
            ],
          ),
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({this.value, this.text, required this.label});
  final int? value;
  final String? text;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      if (value != null)
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: value!.toDouble()),
          duration: const Duration(milliseconds: 1400),
          curve: Curves.easeOutCubic,
          builder: (_, v, __) => Text(v.round().toString(),
              style: _serif(44, color: _C.or, weight: FontWeight.w900)),
        )
      else
        Text(text ?? '', style: _serif(44, color: _C.or, weight: FontWeight.w900)),
      const SizedBox(height: 6),
      Text(label.toUpperCase(),
          style: const TextStyle(
              color: Colors.white70, fontSize: 11.5, letterSpacing: 2.2)),
    ]);
  }
}

// =============================================================================
// 7. APPEL FINAL
// =============================================================================
class _CtaFinal extends StatelessWidget {
  const _CtaFinal({required this.logged, required this.onJoin, required this.onLogin});
  final bool logged;
  final VoidCallback onJoin;
  final VoidCallback onLogin;

  @override
  Widget build(BuildContext context) {
    return _Section(
      color: _C.ivoire,
      child: Column(children: [
        Text('Votre Cité vous attend.',
            textAlign: TextAlign.center,
            style: _serif(_wide(context) ? 42 : 30, color: _C.encre, height: 1.15)),
        const SizedBox(height: 14),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: const Text(
            'Rejoignez la Ligue, choisissez votre Cité et commencez votre transformation.',
            textAlign: TextAlign.center,
            style: TextStyle(color: _C.texte, fontSize: 16.5, height: 1.6),
          ),
        ),
        const SizedBox(height: 28),
        Wrap(alignment: WrapAlignment.center, spacing: 12, runSpacing: 12, children: [
          _Btn('REJOINDRE MA CITÉ', onJoin,
              icon: Icons.arrow_forward_rounded, kind: _BtnKind.navy),
          _Btn(logged ? 'MON ESPACE' : 'SE CONNECTER', onLogin,
              icon: logged ? Icons.dashboard_outlined : Icons.login,
              kind: _BtnKind.outlineDark),
        ]),
      ]),
    );
  }
}

// =============================================================================
// 8. PIED DE PAGE
// =============================================================================
class _Footer extends StatelessWidget {
  const _Footer();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: _C.nuit,
      padding: const EdgeInsets.fromLTRB(20, 32, 20, 32),
      child: Column(children: [
        Text('Ligue Panafricaine des Neurocitoyens',
            textAlign: TextAlign.center, style: _serif(16)),
        const SizedBox(height: 8),
        const Text('CONSCIENCE · INTÉGRITÉ · AUTONOMIE',
            textAlign: TextAlign.center,
            style: TextStyle(
                color: _C.or, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 2.2)),
        const SizedBox(height: 16),
        const Text(
          'La Ligue forme, accompagne et structure des projets collectifs. '
          'Aucun gain individuel n’est garanti.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white54, fontSize: 11.5, height: 1.5),
        ),
      ]),
    );
  }
}