import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

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

class _C {
  static const nuit = Color(0xFF060A1F);
  static const nuit2 = Color(0xFF121845);
  static const nuit3 = Color(0xFF0B102E);
  static const or = Color(0xFFC4952B);
  static const orClair = Color(0xFFF0D9A0);
  static const ivoire = Color(0xFFFBF8F1);
}

TextStyle _serif(double size,
    {Color color = Colors.white, FontWeight weight = FontWeight.w700, double? height, double? spacing}) {
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

class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});
  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          backgroundColor: const Color(0xFF101845),
          content: const Text(
              'IA Guide : Bienvenue ! Je suis ton guide depuis ton acces. Clique sur le robot pour comprendre Charte & Modele Eco',
              style: TextStyle(color: Color(0xFFFFC400), fontSize: 11)),
          action: SnackBarAction(label: 'Ouvrir IA', textColor: const Color(0xFFFFC400), onPressed: () => context.go('/ia-guide')),
          duration: const Duration(seconds: 5),
        ));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      backgroundColor: const Color(0xFF080C1F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF080C1F),
        title: Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(10)),
            child: Image.asset('assets/logo_ligue.jpg', width: 28, height: 28, fit: BoxFit.contain),
          ),
          const SizedBox(width: 10),
          Text(L10n.t('ligue'), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white70)),
        ]),
        actions: [
          DropdownButton<String>(
              value: L10n.lang,
              dropdownColor: const Color(0xFF101845),
              underline: const SizedBox(),
              style: const TextStyle(color: Colors.white, fontSize: 12),
              items: const [DropdownMenuItem(value: 'fr', child: Text('FR')), DropdownMenuItem(value: 'en', child: Text('EN'))],
              onChanged: (v) {
                setState(() => L10n.setLang(v!));
              }),
          IconButton(icon: const Icon(Icons.smart_toy, color: Color(0xFFFFC400)), onPressed: () => context.go('/ia-guide')),
          const SizedBox(width: 8),
        ],
      ),
      drawer: Drawer(
          backgroundColor: const Color(0xFF101845),
          child: ListView(children: [
            const DrawerHeader(
                decoration: BoxDecoration(color: Color(0xFF080C1F)),
                child: Text('Ligue Panafricaine', style: TextStyle(color: Colors.white))),
            ListTile(leading: const Icon(Icons.home, color: Colors.white70), title: const Text('Accueil', style: TextStyle(color: Colors.white70)), onTap: () => context.go('/')),
            ListTile(leading: const Icon(Icons.dashboard, color: Colors.white70), title: const Text('Dashboard', style: TextStyle(color: Colors.white70)), onTap: () => context.go('/dashboard')),
            ListTile(leading: const Icon(Icons.school, color: Colors.white70), title: const Text('Modules', style: TextStyle(color: Colors.white70)), onTap: () => context.go('/modules')),
            ListTile(leading: const Icon(Icons.cast_for_education, color: Colors.white70), title: const Text('Universite', style: TextStyle(color: Colors.white70)), onTap: () => context.go('/universite')),
          ])),
      bottomNavigationBar: SafeArea(
        child: Container(
          height: 70 + MediaQuery.of(context).padding.bottom,
          color: const Color(0xFF101845),
          child: BottomNavigationBar(
            backgroundColor: const Color(0xFF101845),
            selectedItemColor: const Color(0xFFFFC400),
            unselectedItemColor: Colors.white54,
            type: BottomNavigationBarType.fixed,
            onTap: (i) => context.go(['/', '/carte', '/dashboard', '/modules', '/profil'][i]),
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Accueil'),
              BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Cités'),
              BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Board'),
              BottomNavigationBarItem(icon: Icon(Icons.school), label: 'Modules'),
              BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
            ],
          ),
        ),
      ),
      body: Padding(
  padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom + 70),
  child: ListView(
    children: const [
      _Hero(),
      _StatsBand(),
      body: ListView(
        children: const [
          _Hero(),
          _StatsBand(),
          _Governance(),
          _Cooperative(),
          _Diaspora(),
          _FinalCta(),
          _Footer(),
        ],
      ),
      floatingActionButton: Padding(
        padding: EdgeInsets.only(bottom: 90 + MediaQuery.of(context).viewPadding.bottom),
        child: FloatingActionButton.extended(
            onPressed: () => context.go('/ia-guide'),
            backgroundColor: const Color(0xFFFFC400),
            icon: const Icon(Icons.smart_toy, color: Colors.black),
            label: const Text('IA Guide', style: TextStyle(color: Colors.black, fontSize: 11))),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Mise en page commune
// ---------------------------------------------------------------------------
class _Section extends StatelessWidget {
  const _Section({
    required this.child,
    this.decoration,
    this.padding = const EdgeInsets.symmetric(horizontal: 20, vertical: 56),
  });

  final Widget child;
  final BoxDecoration? decoration;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: decoration,
      padding: padding,
      child: Center(
        child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 1200), child: child),
      ),
    );
  }
}

class _ResponsiveGrid extends StatelessWidget {
  const _ResponsiveGrid({required this.children, this.minWidth = 300, this.gap = 16});

  final List<Widget> children;
  final double minWidth;
  final double gap;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, cons) {
      final cols = math.max(1, ((cons.maxWidth + gap) / (minWidth + gap)).floor());
      final w = (cons.maxWidth - gap * (cols - 1)) / cols;
      return Wrap(
        spacing: gap,
        runSpacing: gap,
        children: [for (final c in children) SizedBox(width: w, child: c)],
      );
    });
  }
}

class _Eyebrow extends StatelessWidget {
  const _Eyebrow(this.text, {this.center = false});
  final String text;
  final bool center;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      textAlign: center ? TextAlign.center : TextAlign.start,
      style: const TextStyle(color: _C.or, letterSpacing: 4, fontSize: 12, fontWeight: FontWeight.bold),
    );
  }
}

// ---------------------------------------------------------------------------
// 1. HERO : texte + carte interactive
// ---------------------------------------------------------------------------
class _Hero extends StatefulWidget {
  const _Hero();

  @override
  State<_Hero> createState() => _HeroState();
}

class _HeroState extends State<_Hero> {
  String? _region;
  String? _selected;
  bool _org = false;

  @override
  Widget build(BuildContext context) {
    return _Section(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [_C.nuit, _C.nuit2],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.fromLTRB(20, 48, 20, 56),
      child: LayoutBuilder(builder: (context, cons) {
        final wide = cons.maxWidth >= 940;
        final text = _heroText(context, wide);
        final map = _mapCard(context);
        if (wide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(flex: 5, child: text),
              const SizedBox(width: 40),
              Expanded(flex: 6, child: map),
            ],
          );
        }
        return Column(children: [text, const SizedBox(height: 36), map]);
      }),
    );
  }

  Widget _heroText(BuildContext context, bool wide) {
    final align = wide ? CrossAxisAlignment.start : CrossAxisAlignment.center;
    final ta = wide ? TextAlign.start : TextAlign.center;
    return Column(
      crossAxisAlignment: align,
      children: [
        const SizedBox(width: 96, height: 96, child: CustomPaint(painter: _EmblemPainter())),
        const SizedBox(height: 22),
        const _Eyebrow('Ligue panafricaine'),
        const SizedBox(height: 6),
        Text('DES NEUROCITOYENS', textAlign: ta, style: _serif(wide ? 44 : 32, weight: FontWeight.w900, height: 1.05)),
        const SizedBox(height: 16),
        Text(
          'Une fédération de Cités. Une voix par membre.',
          textAlign: ta,
          style: _serif(20, color: _C.orClair, weight: FontWeight.w400, height: 1.4),
        ),
        const SizedBox(height: 12),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Text(
            'Cinq régions, $kCites Cités et une Charte commune pour former, certifier et faire circuler '
            'la valeur par la coopérative.',
            textAlign: ta,
            style: const TextStyle(color: Colors.white70, fontSize: 16, height: 1.6),
          ),
        ),
        const SizedBox(height: 28),
        Wrap(
          alignment: wide ? WrapAlignment.start : WrapAlignment.center,
          spacing: 12,
          runSpacing: 12,
          children: [
            ElevatedButton(
              onPressed: () => context.go('/carte'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _C.or,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
              child: Text(L10n.t('rejoindre'), style: const TextStyle(fontWeight: FontWeight.w900)),
            ),
            OutlinedButton(
              onPressed: () => context.go('/ia-guide'),
              style: OutlinedButton.styleFrom(
                foregroundColor: _C.or,
                side: const BorderSide(color: _C.or),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
              child: const Text('IA GUIDE CHARTE & MODÈLE'),
            ),
            OutlinedButton(
              onPressed: () => context.go('/universite'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Colors.white38),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
              child: const Text('UNIVERSITÉ'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _mapCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: _C.nuit3.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _C.or.withValues(alpha: 0.5)),
        boxShadow: [BoxShadow(color: _C.or.withValues(alpha: 0.15), blurRadius: 40)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(child: _Eyebrow('Carte des Cités')),
              const Text('Organigramme', style: TextStyle(color: Colors.white70, fontSize: 12)),
              Switch(value: _org, activeColor: _C.or, onChanged: (v) => setState(() => _org = v)),
            ],
          ),
          AfricaMap(
            highlightRegion: _region,
            selectedId: _selected,
            showOrg: _org,
            onCountryTap: (c) {
              setState(() => _selected = c.id);
              showCountrySheet(context, c);
            },
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _chip(null, 'Toutes'),
              for (final r in kRegions.values) _chip(r.code, r.name),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'Touchez un pays pour ouvrir sa fiche · pincez pour zoomer',
            style: TextStyle(color: Colors.white54, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _chip(String? code, String label) {
    final selected = _region == code;
    final color = code == null ? _C.or : kRegions[code]!.color;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => setState(() => _region = selected ? null : code),
      selectedColor: color,
      backgroundColor: Colors.white10,
      side: BorderSide(color: color.withValues(alpha: 0.7)),
      labelStyle: TextStyle(
        color: selected ? Colors.white : Colors.white70,
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
      showCheckmark: false,
    );
  }
}

class _EmblemPainter extends CustomPainter {
  const _EmblemPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width / 2;
    canvas.drawCircle(c, r - 2, Paint()..color = _C.nuit3);
    canvas.drawCircle(c, r - 2, Paint()..style = PaintingStyle.stroke..strokeWidth = 2.5..color = _C.or);
    canvas.drawCircle(c, r * 0.8, Paint()..style = PaintingStyle.stroke..strokeWidth = 0.8..color = _C.or.withValues(alpha: 0.6));
    canvas.drawCircle(c, r * 0.5, Paint()..style = PaintingStyle.stroke..strokeWidth = 1..color = _C.orClair);
    final star = Path();
    for (var i = 0; i < 10; i++) {
      final rad = i.isEven ? r * 0.42 : r * 0.17;
      final a = i * math.pi / 5;
      final p = Offset(c.dx + rad * math.sin(a), c.dy - rad * math.cos(a));
      if (i == 0) {
        star.moveTo(p.dx, p.dy);
      } else {
        star.lineTo(p.dx, p.dy);
      }
    }
    star.close();
    canvas.drawPath(star, Paint()..color = _C.or);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ---------------------------------------------------------------------------
// 2. BANDE DE CHIFFRES animés
// ---------------------------------------------------------------------------
class _StatsBand extends StatelessWidget {
  const _StatsBand();

  @override
  Widget build(BuildContext context) {
    return _Section(
      decoration: const BoxDecoration(
        color: _C.nuit3,
        border: Border.symmetric(horizontal: BorderSide(color: Color(0x33C4952B))),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
      child: Wrap(
        alignment: WrapAlignment.spaceEvenly,
        runSpacing: 24,
        spacing: 40,
        children: const [
          _Stat(value: kCites, label: 'Cités'),
          _Stat(value: kNbRegions, label: 'Régions'),
          _Stat(value: kNiveaux, label: 'Niveaux'),
          _Stat(value: kPoles, label: 'Pôles'),
          _Stat(value: kGrades, label: 'Grades'),
          _Stat(text: kCoopVersion, label: 'Modèle coopératif'),
        ],
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
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (value != null)
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: value!.toDouble()),
            duration: const Duration(milliseconds: 1400),
            curve: Curves.easeOutCubic,
            builder: (_, v, __) => Text(v.round().toString(), style: _serif(40, color: _C.or, weight: FontWeight.w900)),
          )
        else
          Text(text ?? '', style: _serif(40, color: _C.or, weight: FontWeight.w900)),
        const SizedBox(height: 4),
        Text(label.toUpperCase(), style: const TextStyle(color: Colors.white70, fontSize: 12, letterSpacing: 2)),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// 3. GOUVERNANCE : six niveaux
// ---------------------------------------------------------------------------
class _Level {
  const _Level(this.n, this.territory, this.title, this.text);
  final String n;
  final String territory;
  final String title;
  final String text;
}

const _levels = <_Level>[
  _Level('1', 'Ligue Panafricaine', 'Mansa', 'Préside la Ligue en rotation entre les régions et veille à la Charte.'),
  _Level('2', 'Région', 'Ola', 'Assure la liaison entre les Cités d’une région et la Ligue.'),
  _Level('3', 'Cité (pays)', 'Mwalimu', 'Autorité morale et pédagogique de la Cité, élue par son Forum.'),
  _Level('4', 'Nome (département)', 'Nomarque', 'Représente la Cité dans le département.'),
  _Level('5', 'Dème (commune)', 'Démarque', 'Relie les Agoras de la commune à la Cité.'),
  _Level('6', 'Agora (quartier)', 'Agoranome', 'Veille à la vie, à l’entraide et à la confiance dans le quartier.'),
];

class _Governance extends StatelessWidget {
  const _Governance();

  @override
  Widget build(BuildContext context) {
    return _Section(
      decoration: const BoxDecoration(color: _C.ivoire),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _Eyebrow('Gouvernance'),
          const SizedBox(height: 8),
          Text('Six niveaux, du continent au quartier', style: _serif(32, color: _C.nuit, height: 1.15)),
          const SizedBox(height: 8),
          const Text(
            'Chaque niveau a son Forum et son dirigeant. Les décisions montent par délégation, '
            'les orientations descendent par la Charte.',
            style: TextStyle(color: Color(0xFF5A6272), height: 1.6),
          ),
          const SizedBox(height: 28),
          _ResponsiveGrid(
            minWidth: 320,
            children: [for (final l in _levels) _LevelCard(l)],
          ),
        ],
      ),
    );
  }
}

class _LevelCard extends StatelessWidget {
  const _LevelCard(this.l);
  final _Level l;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.go('/dashboard'),
      borderRadius: BorderRadius.circular(14),
      child: Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: const Border(top: BorderSide(color: _C.or, width: 4)),
        boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 16, offset: Offset(0, 6))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              width: 30,
              height: 30,
              alignment: Alignment.center,
              decoration: const BoxDecoration(color: _C.nuit, shape: BoxShape.circle),
              child: Text(l.n, style: const TextStyle(color: _C.or, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(l.territory.toUpperCase(),
                  style: const TextStyle(color: Color(0xFF9A3B26), fontSize: 11, letterSpacing: 2, fontWeight: FontWeight.bold)),
            ),
          ]),
          const SizedBox(height: 12),
          Text(l.title, style: _serif(26, color: _C.nuit)),
          const SizedBox(height: 6),
          Text(l.text, style: const TextStyle(color: Color(0xFF3A3D44), height: 1.5)),
        ],
      ),
    ));
  }
}

// ---------------------------------------------------------------------------
// 4. COOPÉRATIVE
// ---------------------------------------------------------------------------
class _Cooperative extends StatelessWidget {
  const _Cooperative();

  @override
  Widget build(BuildContext context) {
    return _Section(
      decoration: const BoxDecoration(color: _C.nuit2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _Eyebrow('Économie sociale et circulaire'),
          const SizedBox(height: 8),
          Text('Une fédération de coopératives', style: _serif(32, height: 1.15)),
          const SizedBox(height: 8),
          const Text(
            'La valeur créée circule entre ceux qui la produisent. On est payé pour un service rendu, '
            'jamais pour un recrutement.',
            style: TextStyle(color: Colors.white70, height: 1.6),
          ),
          const SizedBox(height: 28),
          const _ResponsiveGrid(
            minWidth: 320,
            children: [
              _Pillar('Centrale d’achat', 'Des achats groupés pour toute la communauté : prix de gros, ristourne en fin d’année, relevé des économies.'),
              _Pillar('Coopératives de travailleurs', 'Les responsables de chaque Cité vendent des formations aux enseignants, aux entreprises et aux institutions, et fondent des coopératives locales.'),
              _Pillar('École d’entrepreneuriat coopératif', 'Soixante heures pour passer de l’idée à la coopérative, commune à tous les pays de la Ligue.'),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _C.or.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _C.or.withValues(alpha: 0.5)),
            ),
            child: const Text(
              'Entrée sans barrière : une première étape gratuite, un paiement fractionné par mobile money, '
              'une part sociale remboursable à tout moment.',
              style: TextStyle(color: _C.orClair, height: 1.6, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(spacing: 12, children: [
            TextButton(
              onPressed: () => context.go('/modele-eco'),
              child: const Text('Voir le modèle économique →', style: TextStyle(color: _C.or)),
            ),
            TextButton(
              onPressed: () => context.go('/coop'),
              child: const Text('Les coopératives →', style: TextStyle(color: _C.or)),
            ),
            TextButton(
              onPressed: () => context.go('/charte'),
              child: const Text('La Charte →', style: TextStyle(color: _C.or)),
            ),
          ]),
        ],
      ),
    );
  }
}

class _Pillar extends StatelessWidget {
  const _Pillar(this.title, this.text);
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(width: 36, height: 3, color: _C.or),
          const SizedBox(height: 14),
          Text(title, style: _serif(20)),
          const SizedBox(height: 8),
          Text(text, style: const TextStyle(color: Colors.white70, height: 1.55)),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 5. DIASPORA : un forum sans territoire, distinct de tout pays
// ---------------------------------------------------------------------------
class _Diaspora extends StatelessWidget {
  const _Diaspora();

  @override
  Widget build(BuildContext context) {
    return _Section(
      decoration: const BoxDecoration(color: _C.nuit3),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 48),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _C.or.withValues(alpha: 0.5)),
          gradient: LinearGradient(colors: [_C.or.withValues(alpha: 0.10), Colors.transparent]),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.travel_explore, color: _C.or, size: 40),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Forum de la Diaspora', style: _serif(24)),
                  const SizedBox(height: 8),
                  const Text(
                    'La diaspora forme un forum à part, sans territoire : elle n’est ni une région ni un pays. '
                    'Ses membres, représentés par les Proxènes, relient la Ligue aux partenaires et aux compétences '
                    'du monde entier. Chaque pays, Haïti compris, garde son identité propre et n’est pas rangé sous la diaspora.',
                    style: TextStyle(color: Colors.white70, height: 1.6),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 6. APPEL FINAL + PIED DE PAGE
// ---------------------------------------------------------------------------
class _FinalCta extends StatelessWidget {
  const _FinalCta();

  @override
  Widget build(BuildContext context) {
    return _Section(
      decoration: const BoxDecoration(
        gradient: LinearGradient(colors: [_C.nuit2, _C.nuit], begin: Alignment.topCenter, end: Alignment.bottomCenter),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 64),
      child: Column(
        children: [
          Text('Votre Cité vous attend', textAlign: TextAlign.center, style: _serif(34, height: 1.15)),
          const SizedBox(height: 12),
          const Text(
            'Commencez gratuitement, avancez à votre rythme, décidez avec les autres membres.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70, fontSize: 16, height: 1.6),
          ),
          const SizedBox(height: 28),
          ElevatedButton(
            onPressed: () => context.go('/carte'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _C.or,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 44, vertical: 22),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
            ),
            child: const Text('REJOINDRE LA LIGUE →', style: TextStyle(fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: _C.nuit,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: const Text(
        'Ligue Panafricaine des Neurocitoyens · Conscience · Compétence · Engagement · Impact',
        textAlign: TextAlign.center,
        style: TextStyle(color: Colors.white54, fontSize: 12, letterSpacing: 1),
      ),
    );
  }
}