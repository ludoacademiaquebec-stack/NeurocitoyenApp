import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/document_service.dart';
import '../../widgets/app_scaffold.dart';

class _C {
  static const nuit = Color(0xFF0B2B2F);
  static const nuit2 = Color(0xFF0E3A3D);
  static const nuit3 = Color(0xFF071D20);
  static const or = Color(0xFFE0A82E);
  static const orClair = Color(0xFFF0BD4A);
  static const vert = Color(0xFF1D7A52);
  static const violet = Color(0xFF7A4E8C);
  static const rouge = Color(0xFFB4473A);
}

TextStyle _serif(double size,
    {Color color = Colors.white, FontWeight weight = FontWeight.w700, double? height}) {
  return TextStyle(
    fontFamily: 'Georgia',
    fontFamilyFallback: const ['Times New Roman', 'serif'],
    fontSize: size,
    color: color,
    fontWeight: weight,
    height: height,
  );
}

class ModeleEcoScreen extends StatefulWidget {
  const ModeleEcoScreen({super.key});
  @override
  State<ModeleEcoScreen> createState() => _ModeleEcoScreenState();
}

class _ModeleEcoScreenState extends State<ModeleEcoScreen> {
  bool _loading = true;
  List<Map<String, dynamic>> _sections = [];
  List<Map<String, dynamic>> _sources = [];
  List<Map<String, dynamic>> _flux = [];
  List<Map<String, dynamic>> _previsions = [];

  final Set<String> _ouverts = {'rupture'};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final data = await DocumentService.loadModeleEco(force: true);
    setState(() {
      _sections = List<Map<String, dynamic>>.from(data['sections'] ?? []);
      _sources = List<Map<String, dynamic>>.from(data['sources'] ?? []);
      _flux = List<Map<String, dynamic>>.from(data['flux'] ?? []);
      _previsions = List<Map<String, dynamic>>.from(data['previsions'] ?? []);
      _loading = false;
    });
  }

  void _toggle(String code) {
    setState(() {
      if (_ouverts.contains(code)) {
        _ouverts.remove(code);
      } else {
        _ouverts.add(code);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Modèle économique',
      child: _loading
          ? const Center(child: CircularProgressIndicator(color: _C.or))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _header(),
                const SizedBox(height: 16),
                _actionsRow(),
                const SizedBox(height: 16),
                _sommaire(),
                const SizedBox(height: 16),
                ..._sections.map(_sectionBloc),
                const SizedBox(height: 20),
                _footer(),
              ],
            ),
    );
  }

  // ===========================================================================
  // HEADER
  // ===========================================================================
  Widget _header() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_C.vert, Color(0xFF0F4A2F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'DOCUMENT STRATÉGIQUE · VERSION 1.0 · OCTOBRE 2026',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 10,
              letterSpacing: 2,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Text('Modèle économique',
              style: _serif(28, color: Colors.white, weight: FontWeight.w900)),
          const SizedBox(height: 4),
          const Text('Du réseau à la valeur : un modèle fondé sur le service rendu',
              style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.25),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              '7 sources · 3 fonds · 3 ans de projection',
              style: TextStyle(
                  color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // ACTIONS
  // ===========================================================================
  Widget _actionsRow() {
    return Row(
      children: [
        Expanded(
          child: _actionBtn(
            Icons.download,
            'Télécharger PDF',
            () => _toast('PDF bientôt disponible'),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _actionBtn(
            Icons.account_balance_wallet,
            'Mon portefeuille',
            () => context.go('/portefeuille'),
          ),
        ),
      ],
    );
  }

  Widget _actionBtn(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: _C.nuit3,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _C.vert.withOpacity(0.5)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: _C.vert, size: 18),
            const SizedBox(width: 8),
            Flexible(
              child: Text(label,
                  style: const TextStyle(
                      color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // SOMMAIRE
  // ===========================================================================
  Widget _sommaire() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _C.nuit2,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _C.vert.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.list_alt, color: _C.vert, size: 18),
              const SizedBox(width: 8),
              Text('Sommaire', style: _serif(16)),
            ],
          ),
          const SizedBox(height: 12),
          ..._sections.map((s) {
            final code = (s['code'] ?? '').toString();
            final titre = s['titre'] ?? '';
            return InkWell(
              onTap: () => _toggle(code),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Row(
                  children: [
                    const Icon(Icons.chevron_right, color: _C.vert, size: 14),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(titre,
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 12)),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  // ===========================================================================
  // BLOC D'UNE SECTION
  // ===========================================================================
  Widget _sectionBloc(Map<String, dynamic> s) {
    final code = (s['code'] ?? '').toString();
    final titre = s['titre'] ?? '';
    final sousTitre = s['sous_titre'] ?? '';
    final contenu = (s['contenu'] ?? '').toString();
    final type = (s['type'] ?? 'texte').toString();
    final estOuvert = _ouverts.contains(code);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: _C.nuit3,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: estOuvert ? _C.vert.withOpacity(0.6) : Colors.white12,
          width: estOuvert ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => _toggle(code),
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: estOuvert ? _C.vert : _C.vert.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      _iconeForCode(code),
                      color: estOuvert ? Colors.white : _C.vert,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(titre,
                            style: _serif(15, height: 1.3)),
                        if (sousTitre.isNotEmpty)
                          Text(sousTitre,
                              style: const TextStyle(
                                  color: Colors.white54, fontSize: 11)),
                      ],
                    ),
                  ),
                  Icon(
                    estOuvert ? Icons.expand_less : Icons.expand_more,
                    color: _C.vert,
                  ),
                ],
              ),
            ),
          ),
          if (estOuvert) ...[
            const Divider(color: Colors.white12, height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: _buildContenu(code, contenu, type),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildContenu(String code, String contenu, String type) {
    // Section sources de revenus
    if (code == 'clients_revenus') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (contenu.isNotEmpty)
            Text(contenu,
                style: const TextStyle(
                    color: Colors.white70, fontSize: 12.5, height: 1.6)),
          const SizedBox(height: 12),
          _tableauSources(),
        ],
      );
    }

    // Section flux fédéraux
    if (code == 'flux_federaux') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (contenu.isNotEmpty)
            Text(contenu,
                style: const TextStyle(
                    color: Colors.white70, fontSize: 12.5, height: 1.6)),
          const SizedBox(height: 12),
          _tableauFlux(),
        ],
      );
    }

    // Section 3 ans en chiffres
    if (code == 'trois_ans') {
      return _tableauPrevisions();
    }

    // Section risques
    if (code == 'risques') {
      return _tableauRisques(contenu);
    }

    // Section feuille de route
    if (code == 'feuille_route') {
      return _timelineFeuilleRoute(contenu);
    }

    // Liste
    if (type == 'liste') {
      return _listeContenu(contenu);
    }

    return Text(contenu,
        style: const TextStyle(color: Colors.white70, fontSize: 12.5, height: 1.6));
  }

  // ===========================================================================
  // TABLEAUX SPÉCIALISÉS
  // ===========================================================================
  Widget _tableauSources() {
    return Column(
      children: _sources.map((s) => Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _C.nuit2,
              borderRadius: BorderRadius.circular(10),
              border: Border(left: BorderSide(color: _C.or, width: 4)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: const BoxDecoration(
                          color: _C.or, shape: BoxShape.circle),
                      child: Center(
                        child: Text('${s['numero']}',
                            style: const TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.w900,
                                fontSize: 11)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text('${s['produit']}',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _ligne('Qui paie', '${s['qui_paie'] ?? ""}'),
                _ligne('Prix de référence', '${s['prix_reference'] ?? ""}'),
                _ligne('Ce qui est livré', '${s['ce_qui_est_livre'] ?? ""}'),
              ],
            ),
          )).toList(),
    );
  }

  Widget _tableauFlux() {
    return Column(
      children: _flux.map((f) {
        final pct = f['pourcentage'];
        final nom = f['nom'] ?? '';
        final usage = f['usage'] ?? '';
        final couleur = _parseColor(f['couleur'] as String?);

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _C.nuit2,
            borderRadius: BorderRadius.circular(10),
            border: Border(left: BorderSide(color: couleur, width: 4)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: couleur,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('$pct %',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w900)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(nom,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text(usage,
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 11, height: 1.4)),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _tableauPrevisions() {
    // En-tête
    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: _C.vert,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
          ),
          child: const Row(
            children: [
              Expanded(
                  flex: 3,
                  child: Text('Poste (M FCFA)',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold))),
              Expanded(
                  flex: 1,
                  child: Text('An 1',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold))),
              Expanded(
                  flex: 1,
                  child: Text('An 2',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold))),
              Expanded(
                  flex: 1,
                  child: Text('An 3',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold))),
            ],
          ),
        ),
        // Lignes
        ..._previsions.map((p) {
          final type = (p['type'] ?? '').toString();
          final isTotal = type == 'total';
          final isCharge = type == 'charge';
          final isRatio = type == 'ratio';

          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: isTotal
                  ? _C.or.withOpacity(0.15)
                  : _C.nuit2.withOpacity(0.5),
              border: const Border(
                  bottom: BorderSide(color: Colors.white10, width: 0.5)),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text(
                    '${p['poste']}',
                    style: TextStyle(
                      color: isTotal
                          ? _C.or
                          : (isCharge ? Colors.white60 : Colors.white),
                      fontSize: 11,
                      fontWeight: isTotal ? FontWeight.w900 : FontWeight.w500,
                    ),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Text(
                    _formatNum(p['annee_1'], isRatio),
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      color: _colorNum(p['annee_1']),
                      fontSize: 11,
                      fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Text(
                    _formatNum(p['annee_2'], isRatio),
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      color: _colorNum(p['annee_2']),
                      fontSize: 11,
                      fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Text(
                    _formatNum(p['annee_3'], isRatio),
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      color: _colorNum(p['annee_3']),
                      fontSize: 11,
                      fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  String _formatNum(dynamic v, bool isRatio) {
    if (v == null) return '—';
    final n = (v as num).toDouble();
    if (isRatio) return '${n.toStringAsFixed(0)} %';
    if (n == 0) return '0';
    return n.toStringAsFixed(1);
  }

  Color _colorNum(dynamic v) {
    if (v == null) return Colors.white54;
    final n = (v as num).toDouble();
    if (n < 0) return _C.rouge;
    if (n > 0) return _C.vert;
    return Colors.white70;
  }

  Widget _tableauRisques(String contenu) {
    final lignes = contenu.split('\n\n');
    return Column(
      children: lignes.map((l) {
        final parts = l.split(' → ');
        if (parts.length >= 2) {
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _C.nuit2,
              borderRadius: BorderRadius.circular(10),
              border: Border(left: BorderSide(color: _C.rouge, width: 4)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(parts[0],
                    style: const TextStyle(
                        color: _C.rouge,
                        fontSize: 12,
                        fontWeight: FontWeight.w900)),
                const SizedBox(height: 4),
                Text(parts.sublist(1).join(' → '),
                    style: const TextStyle(
                        color: Colors.white70, fontSize: 11.5, height: 1.5)),
              ],
            ),
          );
        }
        return const SizedBox.shrink();
      }).toList(),
    );
  }

  Widget _timelineFeuilleRoute(String contenu) {
    final etapes = contenu.split('\n\n');
    return Column(
      children: etapes.map((e) {
        final parts = e.split(' : ');
        if (parts.length >= 2) {
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _C.nuit2,
              borderRadius: BorderRadius.circular(10),
              border: Border(left: BorderSide(color: _C.vert, width: 4)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(parts[0],
                    style: const TextStyle(
                        color: _C.vert,
                        fontSize: 12,
                        fontWeight: FontWeight.w900)),
                const SizedBox(height: 4),
                Text(parts.sublist(1).join(' : '),
                    style: const TextStyle(
                        color: Colors.white70, fontSize: 11.5, height: 1.5)),
              ],
            ),
          );
        }
        return const SizedBox.shrink();
      }).toList(),
    );
  }

  Widget _listeContenu(String contenu) {
    final lignes = contenu.split('\n\n');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: lignes.map((l) {
        if (l.isEmpty) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.circle, color: _C.vert, size: 6),
              const SizedBox(width: 8),
              Expanded(
                child: Text(l,
                    style: const TextStyle(
                        color: Colors.white70, fontSize: 12, height: 1.5)),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _ligne(String label, String valeur) {
    if (valeur.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text('$label :',
                style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 11,
                    fontWeight: FontWeight.w600)),
          ),
          Expanded(
            child: Text(valeur,
                style: const TextStyle(
                    color: Colors.white70, fontSize: 11, height: 1.4)),
          ),
        ],
      ),
    );
  }

  Color _parseColor(String? hex) {
    if (hex == null || hex.isEmpty) return _C.vert;
    final c = hex.replaceAll('#', '');
    try {
      return Color(int.parse('FF$c', radix: 16));
    } catch (_) {
      return _C.vert;
    }
  }

  IconData _iconeForCode(String code) {
    switch (code) {
      case 'rupture':
        return Icons.bolt;
      case 'changements':
        return Icons.compare_arrows;
      case 'clients_revenus':
        return Icons.attach_money;
      case 'flux_federaux':
        return Icons.account_balance;
      case 'trois_ans':
        return Icons.trending_up;
      case 'indicateurs':
        return Icons.insights;
      case 'risques':
        return Icons.warning_amber;
      case 'feuille_route':
        return Icons.route;
      default:
        return Icons.article;
    }
  }

  // ===========================================================================
  // FOOTER
  // ===========================================================================
  Widget _footer() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _C.nuit3,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        children: [
          const Icon(Icons.verified, color: _C.vert, size: 24),
          const SizedBox(height: 10),
          Text('Adoption',
              style: _serif(14, color: _C.orClair)),
          const SizedBox(height: 6),
          const Text(
            'Modèle économique adopté par le Forum Panafricain constituant.\nLe Mansa · Le Tamias · Le Président de séance',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.5),
          ),
          const SizedBox(height: 12),
          Text(
            'Version 1.0 · Octobre 2026',
            style: const TextStyle(color: Colors.white38, fontSize: 10),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // TOAST
  // ===========================================================================
  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      backgroundColor: _C.nuit2,
      content: Text(msg, style: const TextStyle(color: _C.or, fontSize: 12)),
    ));
  }
}
