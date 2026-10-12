import 'package:flutter/material.dart';

import '../../widgets/africa_map.dart';
import '../../widgets/app_scaffold.dart';

/// Écran « Cités » : carte plein écran, filtre par région, organigramme en option,
/// puis liste des 55 Cités par région.
class CarteAfriqueScreen extends StatefulWidget {
  const CarteAfriqueScreen({super.key});

  @override
  State<CarteAfriqueScreen> createState() => _CarteAfriqueScreenState();
}

class _CarteAfriqueScreenState extends State<CarteAfriqueScreen> {
  String? _region;
  String? _selected;
  bool _org = false;
  late final Future<AfricaGeo> _geo = AfricaGeo.load();

  static const Color _gold = Color(0xFFC4952B);

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'CITÉS DE LA LIGUE',
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
        children: [
          const Text(
            'Choisissez votre Cité',
            style: TextStyle(
              fontFamily: 'Georgia',
              fontFamilyFallback: ['Times New Roman', 'serif'],
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Touchez un pays pour ouvrir sa fiche et rejoindre sa Cité. Pincez pour zoomer.',
            style: TextStyle(color: Colors.white70, height: 1.5),
          ),
          const SizedBox(height: 12),
          Row(children: [
            const Expanded(child: Text('Afficher l’organigramme (Mansa, Ola, Cités)', style: TextStyle(color: Colors.white70, fontSize: 12))),
            Switch(value: _org, activeColor: _gold, onChanged: (v) => setState(() => _org = v)),
          ]),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF0B102E),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: _gold.withOpacity(0.4)),
            ),
            child: AfricaMap(
              highlightRegion: _region,
              selectedId: _selected,
              showOrg: _org,
              onCountryTap: (c) {
                setState(() => _selected = c.id);
                showCountrySheet(context, c);
              },
            ),
          ),
          const SizedBox(height: 14),
          Wrap(spacing: 8, runSpacing: 8, children: [
            _chip(null, 'Toutes', _gold),
            for (final r in kRegions.values) _chip(r.code, r.name, r.color),
          ]),
          const SizedBox(height: 24),
          FutureBuilder<AfricaGeo>(
            future: _geo,
            builder: (context, snap) {
              if (!snap.hasData) return const SizedBox.shrink();
              final list = snap.data!.countries.where((c) => _region == null || c.region == _region).toList()
                ..sort((a, b) => a.name.compareTo(b.name));
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${list.length} Cités', style: const TextStyle(color: _gold, fontWeight: FontWeight.bold, letterSpacing: 2)),
                  const SizedBox(height: 10),
                  Wrap(spacing: 8, runSpacing: 8, children: [
                    for (final c in list)
                      ActionChip(
                        label: Text(c.name),
                        labelStyle: const TextStyle(color: Colors.white, fontSize: 12),
                        backgroundColor: kRegions[c.region]!.color.withOpacity(0.35),
                        side: BorderSide(color: kRegions[c.region]!.color),
                        onPressed: () {
                          setState(() => _selected = c.id);
                          showCountrySheet(context, c);
                        },
                      ),
                  ]),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _chip(String? code, String label, Color color) {
    final selected = _region == code;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      showCheckmark: false,
      selectedColor: color,
      backgroundColor: Colors.white10,
      side: BorderSide(color: color.withOpacity(0.7)),
      labelStyle: TextStyle(color: selected ? Colors.white : Colors.white70, fontSize: 12, fontWeight: FontWeight.w600),
      onSelected: (_) => setState(() => _region = selected ? null : code),
    );
  }
}