import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart' show TargetPlatform, defaultTargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:go_router/go_router.dart';

/// Une région de l'Union africaine.
class Region {
  const Region(this.code, this.name, this.color);
  final String code;
  final String name;
  final Color color;
}

// Palette « atlas » : tons soutenus mais harmonieux, lisibles sur fond clair
const Map<String, Region> kRegions = {
  'N': Region('N', 'Afrique du Nord', Color(0xFFC08A3E)),
  'W': Region('W', 'Afrique de l’Ouest', Color(0xFF1F7A5C)),
  'C': Region('C', 'Afrique centrale', Color(0xFF6C4A8F)),
  'E': Region('E', 'Afrique de l’Est', Color(0xFFC2503F)),
  'S': Region('S', 'Afrique australe', Color(0xFF2B6AA3)),
};

const Color _gold = Color(0xFFC4952B);
const Color _navy = Color(0xFF0A1330);

/// Un pays : tracé vectoriel déjà projeté (équivalence d'aire de Lambert).
class CountryShape {
  CountryShape({
    required this.id,
    required this.a2,
    required this.name,
    required this.region,
    required this.centroid,
    required this.path,
  }) : bounds = path.getBounds();

  final String id; // code ISO à 3 lettres (BEN)
  final String a2; // code ISO à 2 lettres (BJ), utilisé par /inscription?pays=
  final String name;
  final String region;
  final Offset centroid;
  final Path path;
  final Rect bounds;
}

class AfricaGeo {
  AfricaGeo({
    required this.width,
    required this.height,
    required this.countries,
    required this.anchors,
    required this.mansa,
  });

  final double width;
  final double height;
  final List<CountryShape> countries;
  final Map<String, Offset> anchors;
  final Offset mansa;

  static Future<AfricaGeo>? _cache;

  static Future<AfricaGeo> load([String asset = 'assets/geo/africa_50m.json']) {
    return _cache ??= _load(asset);
  }

  static Future<AfricaGeo> _load(String asset) async {
    final raw = jsonDecode(await rootBundle.loadString(asset)) as Map<String, dynamic>;
    final countries = <CountryShape>[];
    for (final item in (raw['countries'] as List)) {
      final m = item as Map<String, dynamic>;
      final path = Path();
      for (final ring in (m['p'] as List)) {
        final pts = ring as List;
        for (var i = 0; i < pts.length; i++) {
          final pt = pts[i] as List;
          final x = (pt[0] as num).toDouble();
          final y = (pt[1] as num).toDouble();
          if (i == 0) {
            path.moveTo(x, y);
          } else {
            path.lineTo(x, y);
          }
        }
        path.close();
      }
      final c = m['c'] as List;
      countries.add(CountryShape(
        id: m['id'] as String,
        a2: m['a'] as String,
        name: m['n'] as String,
        region: m['r'] as String,
        centroid: Offset((c[0] as num).toDouble(), (c[1] as num).toDouble()),
        path: path,
      ));
    }
    final anchors = <String, Offset>{};
    (raw['anchors'] as Map<String, dynamic>).forEach((k, v) {
      final l = v as List;
      anchors[k] = Offset((l[0] as num).toDouble(), (l[1] as num).toDouble());
    });
    final ma = raw['mansa'] as List;
    return AfricaGeo(
      width: (raw['w'] as num).toDouble(),
      height: (raw['h'] as num).toDouble(),
      countries: countries,
      anchors: anchors,
      mansa: Offset((ma[0] as num).toDouble(), (ma[1] as num).toDouble()),
    );
  }
}

/// Carte interactive : touche ou clic pour ouvrir un pays, survol (ordinateur),
/// boutons + / − / recentrer, pincement sur mobile, filtre par région,
/// organigramme (Mansa, Ola, Cités) en option.
///
/// Sur ordinateur, la molette fait défiler la page (elle ne zoome pas la carte tant
/// qu'on n'a pas zoomé avec les boutons) ; sur mobile, un doigt fait défiler la page
/// et deux doigts zooment la carte.
class AfricaMap extends StatefulWidget {
  const AfricaMap({
    super.key,
    this.highlightRegion,
    this.selectedId,
    this.showOrg = false,
    this.onCountryTap,
  });

  final String? highlightRegion;
  final String? selectedId;
  final bool showOrg;
  final ValueChanged<CountryShape>? onCountryTap;

  @override
  State<AfricaMap> createState() => _AfricaMapState();
}

class _AfricaMapState extends State<AfricaMap> {
  final TransformationController _tc = TransformationController();
  late final Future<AfricaGeo> _future = AfricaGeo.load();
  Size _view = Size.zero;
  bool _zoomed = false;
  CountryShape? _hover;

  bool get _touch =>
      defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS;

  @override
  void initState() {
    super.initState();
    _tc.addListener(() {
      final z = _tc.value.getMaxScaleOnAxis() > 1.05;
      if (z != _zoomed && mounted) setState(() => _zoomed = z);
    });
  }

  @override
  void dispose() {
    _tc.dispose();
    super.dispose();
  }

  CountryShape? _countryAt(AfricaGeo geo, Offset p, double pxPerUnit) {
    for (final c in geo.countries) {
      if (c.bounds.contains(p) && c.path.contains(p)) return c;
    }
    // Tolérance pour les petites îles (Seychelles, Comores, Maurice, etc.).
    final zoom = _tc.value.getMaxScaleOnAxis();
    final radius = 14 / (pxPerUnit * zoom);
    CountryShape? best;
    var bestDist = double.infinity;
    for (final c in geo.countries) {
      if (c.bounds.longestSide > 16) continue;
      final d = (c.centroid - p).distance;
      if (d < radius && d < bestDist) {
        best = c;
        bestDist = d;
      }
    }
    return best;
  }

  void _zoomBy(double factor) {
    if (_view == Size.zero) return;
    final current = _tc.value.getMaxScaleOnAxis();
    final target = (current * factor).clamp(1.0, 10.0).toDouble();
    if (target <= 1.001) {
      _tc.value = Matrix4.identity();
      return;
    }
    final k = target / current;
    final c = Offset(_view.width / 2, _view.height / 2);
    final m = Matrix4.translationValues(c.dx, c.dy, 0) *
        Matrix4.diagonal3Values(k, k, 1) *
        Matrix4.translationValues(-c.dx, -c.dy, 0) *
        _tc.value;
    // Garde la carte dans le cadre
    final s = m.getMaxScaleOnAxis();
    m.storage[12] = m.storage[12].clamp(_view.width - _view.width * s, 0.0).toDouble();
    m.storage[13] = m.storage[13].clamp(_view.height - _view.height * s, 0.0).toDouble();
    _tc.value = m;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AfricaGeo>(
      future: _future,
      builder: (context, snap) {
        if (snap.hasError) {
          return const AspectRatio(
            aspectRatio: 1,
            child: Center(
              child: Text('Carte indisponible', style: TextStyle(color: Colors.black54)),
            ),
          );
        }
        if (!snap.hasData) {
          return const AspectRatio(
            aspectRatio: 1,
            child: Center(child: CircularProgressIndicator(color: _gold)),
          );
        }
        final geo = snap.data!;
        return Semantics(
          label:
              'Carte interactive de l’Afrique : cinq régions et 55 Cités. Touchez un pays pour ouvrir sa fiche.',
          child: AspectRatio(
            aspectRatio: geo.width / geo.height,
            child: Stack(children: [
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: LayoutBuilder(
                    builder: (context, cons) {
                      final scale = cons.maxWidth / geo.width;
                      _view = cons.biggest;
                      return InteractiveViewer(
                        transformationController: _tc,
                        minScale: 1,
                        maxScale: 10,
                        panEnabled: _zoomed,
                        scaleEnabled: _touch || _zoomed,
                        child: MouseRegion(
                          cursor: _hover != null
                              ? SystemMouseCursors.click
                              : SystemMouseCursors.basic,
                          onHover: (e) {
                            final c = _countryAt(geo, e.localPosition / scale, scale);
                            if (c?.id != _hover?.id) setState(() => _hover = c);
                          },
                          onExit: (_) {
                            if (_hover != null) setState(() => _hover = null);
                          },
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTapUp: (d) {
                              final c = _countryAt(geo, d.localPosition / scale, scale);
                              if (c != null) widget.onCountryTap?.call(c);
                            },
                            child: AnimatedBuilder(
                              animation: _tc,
                              builder: (context, _) => CustomPaint(
                                size: cons.biggest,
                                painter: _MapPainter(
                                  geo: geo,
                                  scale: scale,
                                  zoom: _tc.value.getMaxScaleOnAxis(),
                                  region: widget.highlightRegion,
                                  selected: widget.selectedId,
                                  hover: _hover?.id,
                                  showOrg: widget.showOrg,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              // Boutons de zoom
              Positioned(
                top: 8,
                right: 8,
                child: Column(children: [
                  _MapButton(icon: Icons.add, tooltip: 'Zoom avant', onTap: () => _zoomBy(1.6)),
                  const SizedBox(height: 6),
                  _MapButton(
                      icon: Icons.remove, tooltip: 'Zoom arrière', onTap: () => _zoomBy(1 / 1.6)),
                  if (_zoomed) ...[
                    const SizedBox(height: 6),
                    _MapButton(
                      icon: Icons.fit_screen_outlined,
                      tooltip: 'Recentrer',
                      onTap: () => _tc.value = Matrix4.identity(),
                    ),
                  ],
                ]),
              ),
              // Nom du pays survolé (ordinateur)
              if (_hover != null)
                Positioned(
                  left: 8,
                  top: 8,
                  child: IgnorePointer(child: _HoverLabel(country: _hover!)),
                ),
            ]),
          ),
        );
      },
    );
  }
}

class _MapButton extends StatelessWidget {
  const _MapButton({required this.icon, required this.tooltip, required this.onTap});
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Tooltip(
        message: tooltip,
        child: Material(
          color: Colors.white,
          elevation: 2,
          shadowColor: Colors.black26,
          borderRadius: BorderRadius.circular(10),
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: onTap,
            child: SizedBox(width: 36, height: 36, child: Icon(icon, size: 20, color: _navy)),
          ),
        ),
      );
}

class _HoverLabel extends StatelessWidget {
  const _HoverLabel({required this.country});
  final CountryShape country;

  @override
  Widget build(BuildContext context) {
    final region = kRegions[country.region]!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: _navy.withOpacity(0.92),
        borderRadius: BorderRadius.circular(10),
        border: Border(left: BorderSide(color: region.color, width: 4)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(country.name,
              style: const TextStyle(
                  color: Colors.white, fontSize: 13, fontWeight: FontWeight.w800)),
          Text(region.name,
              style: const TextStyle(color: Color(0xFFF0D9A0), fontSize: 11)),
        ],
      ),
    );
  }
}

class _MapPainter extends CustomPainter {
  _MapPainter({
    required this.geo,
    required this.scale,
    required this.zoom,
    required this.region,
    required this.selected,
    required this.hover,
    required this.showOrg,
  });

  final AfricaGeo geo;
  final double scale;
  final double zoom;
  final String? region;
  final String? selected;
  final String? hover;
  final bool showOrg;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(scale);

    final fill = Paint()..style = PaintingStyle.fill;
    final border = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..strokeJoin = StrokeJoin.round
      ..color = Colors.white;

    // Pays
    for (final c in geo.countries) {
      final base = kRegions[c.region]!.color;
      final dim = region != null && c.region != region;
      final isSel = c.id == selected;
      final isHover = c.id == hover && !dim;
      var col = base.withOpacity(isSel ? 1.0 : (dim ? 0.14 : 0.86));
      if (isHover && !isSel) {
        col = Color.lerp(base, Colors.white, 0.22)!.withOpacity(0.95);
      }
      fill.color = col;
      canvas.drawPath(c.path, fill);
      canvas.drawPath(c.path, border);
    }

    // Pays survolé : fin contour marine
    if (hover != null && hover != selected) {
      for (final c in geo.countries.where((c) => c.id == hover)) {
        if (region != null && c.region != region) continue;
        canvas.drawPath(
          c.path,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.6
            ..strokeJoin = StrokeJoin.round
            ..color = _navy.withOpacity(0.8),
        );
      }
    }

    // Pays sélectionné : double contour marine + or
    if (selected != null) {
      for (final c in geo.countries.where((c) => c.id == selected)) {
        canvas.drawPath(
          c.path,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3.6
            ..strokeJoin = StrokeJoin.round
            ..color = _navy,
        );
        canvas.drawPath(
          c.path,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.0
            ..strokeJoin = StrokeJoin.round
            ..color = _gold,
        );
      }
    }

    // Organigramme superposé
    if (showOrg) {
      final line = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8;
      for (final c in geo.countries) {
        if (region != null && c.region != region) continue;
        final a = geo.anchors[c.region];
        if (a == null) continue;
        line.color = kRegions[c.region]!.color.withOpacity(0.7);
        canvas.drawLine(a, c.centroid, line);
      }
      final mansaLine = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8
        ..color = _gold;
      geo.anchors.forEach((code, a) {
        if (region != null && code != region) return;
        _dashed(canvas, geo.mansa, a, mansaLine);
      });
      final dot = Paint()..style = PaintingStyle.fill;
      final dotRing = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = Colors.white;
      for (final c in geo.countries) {
        if (region != null && c.region != region) continue;
        dot.color = kRegions[c.region]!.color;
        canvas.drawCircle(c.centroid, 3.2, dot);
        canvas.drawCircle(c.centroid, 3.2, dotRing);
      }
      geo.anchors.forEach((code, a) {
        final col = kRegions[code]!.color;
        canvas.drawCircle(a, 14, Paint()..color = col);
        canvas.drawCircle(
          a,
          14,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2
            ..color = Colors.white,
        );
        _text(canvas, 'OLA', a, 9, Colors.white, FontWeight.w800);
      });
      _star(canvas, geo.mansa, 24, 10);
      _text(canvas, 'MANSA', geo.mansa + const Offset(0, 40), 12, _gold, FontWeight.w800,
          halo: true);
    }

    // Noms des pays (taille apparente constante)
    final fs = 11 / (scale * zoom);
    for (final c in geo.countries) {
      if (region != null && c.region != region) continue;
      final big = c.bounds.longestSide > 90;
      if (!big && zoom < 2.2) continue;
      _text(canvas, c.name, c.centroid + Offset(0, showOrg ? fs * 1.1 + 4 : 0), fs, _navy,
          FontWeight.w700,
          halo: true);
    }

    canvas.restore();
  }

  void _dashed(Canvas canvas, Offset a, Offset b, Paint p, {double dash = 7, double gap = 5}) {
    final total = (b - a).distance;
    if (total == 0) return;
    final dir = (b - a) / total;
    var d = 0.0;
    while (d < total) {
      final e = math.min(d + dash, total);
      canvas.drawLine(a + dir * d, a + dir * e, p);
      d += dash + gap;
    }
  }

  void _star(Canvas canvas, Offset c, double outer, double inner) {
    final path = Path();
    for (var i = 0; i < 10; i++) {
      final r = i.isEven ? outer : inner;
      final a = i * math.pi / 5;
      final pt = Offset(c.dx + r * math.sin(a), c.dy - r * math.cos(a));
      if (i == 0) {
        path.moveTo(pt.dx, pt.dy);
      } else {
        path.lineTo(pt.dx, pt.dy);
      }
    }
    path.close();
    canvas.drawPath(path, Paint()..color = _gold);
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = _navy,
    );
  }

  void _text(Canvas canvas, String t, Offset center, double fontSize, Color color,
      FontWeight weight,
      {bool halo = false}) {
    if (halo) {
      final h = TextPainter(
        text: TextSpan(
          text: t,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: weight,
            foreground: Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = fontSize * 0.28
              ..strokeJoin = StrokeJoin.round
              ..color = Colors.white.withOpacity(0.92),
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      h.paint(canvas, center - Offset(h.width / 2, h.height / 2));
    }
    final tp = TextPainter(
      text: TextSpan(text: t, style: TextStyle(fontSize: fontSize, fontWeight: weight, color: color)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  bool shouldRepaint(covariant _MapPainter old) =>
      old.scale != scale ||
      old.zoom != zoom ||
      old.region != region ||
      old.selected != selected ||
      old.hover != hover ||
      old.showOrg != showOrg ||
      old.geo != geo;
}

/// Fiche d'un pays, partagée par l'accueil et l'écran « Cités ».
void showCountrySheet(BuildContext context, CountryShape c) {
  final region = kRegions[c.region]!;
  final pilot = c.id == 'BEN';
  const serif = TextStyle(
    fontFamily: 'Georgia',
    fontFamilyFallback: ['Times New Roman', 'serif'],
    fontSize: 28,
    color: Colors.white,
    fontWeight: FontWeight.w700,
  );
  Widget pill(String text, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.25),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color),
        ),
        child: Text(text,
            style: const TextStyle(
                color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
      );
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    useSafeArea: true,
    builder: (ctx) => Container(
      padding: const EdgeInsets.fromLTRB(24, 14, 24, 32),
      decoration: BoxDecoration(
        color: _navy,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: region.color, width: 4)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 18),
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Text(c.name, style: serif),
          const SizedBox(height: 4),
          Text('Cité des Neurocitoyens · ${c.name}',
              style: const TextStyle(color: Color(0xFFF0D9A0))),
          const SizedBox(height: 16),
          Wrap(spacing: 8, runSpacing: 8, children: [
            pill(region.name, region.color),
            pill(pilot ? 'Cité pilote' : 'Cité à constituer', pilot ? _gold : Colors.white38),
          ]),
          const SizedBox(height: 16),
          const Text(
            'Dirigeant de la Cité : le Mwalimu, élu par le Forum de la Cité. Région : un Ola. Ligue : le Mansa.',
            style: TextStyle(color: Colors.white70, height: 1.5),
          ),
          const SizedBox(height: 22),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.of(ctx).pop();
                context.go('/inscription?pays=${c.a2}');
              },
              icon: const Icon(Icons.arrow_forward, size: 18),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD9AE45),
                foregroundColor: _navy,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              label: const Text('REJOINDRE CETTE CITÉ',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, letterSpacing: 1)),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.of(ctx).pop();
                context.go('/connexion');
              },
              icon: const Icon(Icons.login, size: 18),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFD9AE45),
                side: const BorderSide(color: Color(0xFFD9AE45), width: 1.5),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              label: const Text('SE CONNECTER',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, letterSpacing: 1)),
            ),
          ),
        ],
      ),
    ),
  );
}