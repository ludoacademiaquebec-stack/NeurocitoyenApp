import 'dart:convert';
import 'dart:math' as math;

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

const Map<String, Region> kRegions = {
  'N': Region('N', 'Afrique du Nord', Color(0xFFB9772E)),
  'W': Region('W', 'Afrique de l’Ouest', Color(0xFF2F7D6D)),
  'C': Region('C', 'Afrique centrale', Color(0xFF7A4E8C)),
  'E': Region('E', 'Afrique de l’Est', Color(0xFFB4473A)),
  'S': Region('S', 'Afrique australe', Color(0xFF2E5E8C)),
};

const Color _gold = Color(0xFFC4952B);

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

/// Carte interactive : zoom par pincement, sélection d'un pays, filtre par région,
/// organigramme (Mansa, Ola, Cités) superposé en option.
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

  @override
  void dispose() {
    _tc.dispose();
    super.dispose();
  }

  void _hit(AfricaGeo geo, Offset p, double pxPerUnit) {
    for (final c in geo.countries) {
      if (c.bounds.contains(p) && c.path.contains(p)) {
        widget.onCountryTap?.call(c);
        return;
      }
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
    if (best != null) widget.onCountryTap?.call(best);
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
              child: Text('Carte indisponible', style: TextStyle(color: Colors.white70)),
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
          label: 'Carte interactive de l’Afrique : cinq régions et 55 Cités. Touchez un pays pour ouvrir sa fiche.',
          child: AspectRatio(
            aspectRatio: geo.width / geo.height,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: InteractiveViewer(
                transformationController: _tc,
                minScale: 1,
                maxScale: 10,
                child: LayoutBuilder(
                  builder: (context, cons) {
                    final scale = cons.maxWidth / geo.width;
                    return GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTapUp: (d) => _hit(geo, d.localPosition / scale, scale),
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
                            showOrg: widget.showOrg,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        );
      },
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
    required this.showOrg,
  });

  final AfricaGeo geo;
  final double scale;
  final double zoom;
  final String? region;
  final String? selected;
  final bool showOrg;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(scale);

    final fill = Paint()..style = PaintingStyle.fill;
    final border = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.9
      ..strokeJoin = StrokeJoin.round
      ..color = Colors.white.withOpacity(0.85);

    // Pays
    for (final c in geo.countries) {
      final base = kRegions[c.region]!.color;
      final dim = region != null && c.region != region;
      final isSel = c.id == selected;
      fill.color = base.withOpacity(isSel ? 0.95 : (dim ? 0.12 : 0.58));
      canvas.drawPath(c.path, fill);
      canvas.drawPath(c.path, border);
    }

    // Pays sélectionné : contour or par-dessus
    if (selected != null) {
      final sel = geo.countries.where((c) => c.id == selected);
      for (final c in sel) {
        canvas.drawPath(
          c.path,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.2
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
        line.color = kRegions[c.region]!.color.withOpacity(0.65);
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
      _text(canvas, 'MANSA', geo.mansa + const Offset(0, 40), 12, _gold, FontWeight.w800, halo: true);
    }

    // Noms des pays (taille apparente constante)
    final fs = 11 / (scale * zoom);
    for (final c in geo.countries) {
      if (region != null && c.region != region) continue;
      final big = c.bounds.longestSide > 90;
      if (!big && zoom < 2.2) continue;
      _text(canvas, c.name, c.centroid + Offset(0, showOrg ? fs * 1.1 + 4 : 0), fs, const Color(0xFF0A102E), FontWeight.w600, halo: true);
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
        ..color = const Color(0xFF060A1F),
    );
  }

  void _text(Canvas canvas, String t, Offset center, double fontSize, Color color, FontWeight weight,
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
        child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
      );
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (ctx) => Container(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
      decoration: BoxDecoration(
        color: const Color(0xFF0B102E),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: region.color, width: 4)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(c.name, style: serif),
          const SizedBox(height: 4),
          Text('Cité des Neurocitoyens · ${c.name}', style: const TextStyle(color: Color(0xFFF0D9A0))),
          const SizedBox(height: 16),
          Wrap(spacing: 8, runSpacing: 8, children: [
            pill(region.name, region.color),
            pill(pilot ? 'Cité pilote' : 'Cité à constituer', pilot ? _gold : Colors.white24),
          ]),
          const SizedBox(height: 16),
          const Text(
            'Dirigeant de la Cité : le Mwalimu, élu par le Forum de la Cité. Région : un Ola. Ligue : le Mansa.',
            style: TextStyle(color: Colors.white70, height: 1.5),
          ),
          const SizedBox(height: 20),
          Row(children: [
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  context.go('/inscription?pays=${c.a2}');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _gold,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
                child: const Text('REJOINDRE CETTE CITÉ', style: TextStyle(fontWeight: FontWeight.w900)),
              ),
            ),
            const SizedBox(width: 12),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Fermer', style: TextStyle(color: Colors.white70)),
            ),
          ]),
        ],
      ),
    ),
  );
}
