import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/l10n.dart';
import '../../widgets/africa_map.dart';

class _C {
  static const nuit = Color(0xFF060A1F);
  static const nuit2 = Color(0xFF121845);
  static const nuit3 = Color(0xFF0B102E);
  static const or = Color(0xFFC4952B);
  static const orClair = Color(0xFFF0D9A0);
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
  String? _selected;
  String? _region;
  bool _org = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      backgroundColor: const Color(0xFF080C1F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF080C1F),
        title: Row(children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(10)),
            child: Image.asset('assets/logo_ligue.jpg', width: 28, height: 28, fit: BoxFit.contain),
          ),
          const SizedBox(width: 10),
          Text(L10n.t('ligue'), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white70)),
        ]),
        actions: [
          IconButton(icon: const Icon(Icons.smart_toy, color: Color(0xFFFFC400)), onPressed: () => context.go('/ia-guide')),
          const SizedBox(width: 8),
        ],
      ),
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
      body: ListView(
        children: [
          _HeroSimple(
            onStart: () => context.go('/dashboard'),
          ),
          _MapSection(
            selectedId: _selected,
            highlightRegion: _region,
            showOrg: _org,
            onRegion: (r) => setState(() => _region = r),
            onOrg: (v) => setState(() => _org = v),
            onCountryTap: (c) {
              setState(() => _selected = c.id);
              showCountrySheet(context, c);
            },
          ),
          _Footer(),
        ],
      ),
      floatingActionButton: Padding(
        padding: EdgeInsets.only(bottom: 90 + MediaQuery.of(context).viewPadding.bottom),
        child: FloatingActionButton.extended(
            onPressed: () => context.go('/dashboard'),
            backgroundColor: const Color(0xFFFFC400),
            icon: const Icon(Icons.explore, color: Colors.black),
            label: const Text('COMMENCER', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 12))),
      ),
    );
  }
}

// HERO SIMPLE - SEULEMENT LE MESSAGE QUI FAIT CLIQUER
class _HeroSimple extends StatelessWidget {
  const _HeroSimple({required this.onStart});
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(colors: [_C.nuit, _C.nuit2], begin: Alignment.topLeft, end: Alignment.bottomRight),
      ),
      padding: const EdgeInsets.fromLTRB(20, 48, 20, 32),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text('Ne soyez plus seulement spectateur du changement.',
                  textAlign: TextAlign.center, style: _serif(28, weight: FontWeight.w400, color: Colors.white70, height: 1.2)),
              const SizedBox(height: 8),
              Text('Devenez acteur de la transformation de votre Cité.',
                  textAlign: TextAlign.center, style: _serif(38, weight: FontWeight.w900, height: 1.05)),
              const SizedBox(height: 28),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _C.or.withValues(alpha: 0.3)),
                ),
                child: Column(
                  children: [
                    Text(
                      'Avant de reconstruire la cité, brisons les murs invisibles qui emprisonnent nos esprits :',
                      textAlign: TextAlign.center,
                      style: _serif(18, color: _C.orClair, weight: FontWeight.w600, height: 1.4),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Ces croyances fatalistes « Ici, rien ne changera »\nCes réflexes centrés sur le moi, au détriment du nous\nCes peurs qui figent les potentiels, individuels et collectifs.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white70, height: 1.6, fontSize: 15),
                    ),
                    const SizedBox(height: 14),
                    Text('Prendre conscience, c\'est déjà briser la prison intérieure.',
                        textAlign: TextAlign.center,
                        style: _serif(16, color: _C.or, weight: FontWeight.w700, height: 1.3)),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'La Ligue vous offre un chemin de transformation personnelle pour reconstruire des schémas cognitivo-comportementaux positifs, basés sur la coopération, l’intégrité, la confiance et le travail sur votre autonomie — y compris votre autonomie financière par l’intégration économique — pour transformer vos conditions de vie et participer au développement de votre communauté.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white60, height: 1.7, fontSize: 15),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: onStart,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _C.or,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 20),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
                child: const Text('COMMENCER MON CHEMINEMENT →', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 0.5)),
              ),
              const SizedBox(height: 10),
              const Text('Inscription ouverte • Le cheminement complet sur votre tableau de bord',
                  style: TextStyle(color: Colors.white38, fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }
}

// CARTE AFRIQUE - QUI PERMET L'INSCRIPTION
class _MapSection extends StatelessWidget {
  const _MapSection(
      {required this.selectedId, required this.highlightRegion, required this.showOrg, required this.onRegion, required this.onOrg, required this.onCountryTap});
  final String? selectedId;
  final String? highlightRegion;
  final bool showOrg;
  final Function(String?) onRegion;
  final Function(bool) onOrg;
  final Function(CountryShape) onCountryTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _C.nuit3,
      padding: const EdgeInsets.fromLTRB(20, 36, 20, 36),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            children: [
              Text('Rejoignez votre communauté', textAlign: TextAlign.center, style: _serif(30, height: 1.15)),
              const SizedBox(height: 8),
              const Text('Touchez votre pays sur la carte pour commencer.',
                  textAlign: TextAlign.center, style: TextStyle(color: Colors.white60)),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _C.nuit.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _C.or.withValues(alpha: 0.4)),
                ),
                child: Column(
                  children: [
                    Row(children: [
                      const Expanded(child: Text('CARTE DES CITÉS', style: TextStyle(color: _C.or, letterSpacing: 3, fontSize: 12, fontWeight: FontWeight.bold))),
                      const Text('Organigramme', style: TextStyle(color: Colors.white70, fontSize: 12)),
                      Switch(value: showOrg, activeColor: _C.or, onChanged: onOrg),
                    ]),
                    const SizedBox(height: 8),
                    // CARTE PLEIN ÉCRAN MANIPULABLE - 520px
                    SizedBox(
                      height: 520,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: AfricaMap(
                          highlightRegion: highlightRegion,
                          selectedId: selectedId,
                          showOrg: showOrg,
                          onCountryTap: onCountryTap,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(spacing: 8, runSpacing: 8, children: [
                      _chip(null, 'Toutes', highlightRegion, onRegion),
                      for (final r in kRegions.values) _chip(r.code, r.name, highlightRegion, onRegion),
                    ]),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => context.go('/carte'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
                child: const Text('VOIR TOUTES LES CITÉS →', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _chip(String? code, String label, String? selected, Function(String?) onTap) {
    final isSel = selected == code;
    final color = code == null? _C.or : kRegions[code]!.color;
    return ChoiceChip(
      label: Text(label),
      selected: isSel,
      onSelected: (_) => onTap(isSel? null : code),
      selectedColor: color,
      backgroundColor: Colors.white10,
      side: BorderSide(color: color.withValues(alpha: 0.7)),
      labelStyle: TextStyle(color: isSel? Colors.white : Colors.white70, fontSize: 12, fontWeight: FontWeight.w600),
      showCheckmark: false,
    );
  }
}

class _Footer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: _C.nuit,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: const Text('Ligue Panafricaine des Neurocitoyens · Conscience · Intégrité · Autonomie',
          textAlign: TextAlign.center, style: TextStyle(color: Colors.white54, fontSize: 12, letterSpacing: 1)),
    );
  }
}