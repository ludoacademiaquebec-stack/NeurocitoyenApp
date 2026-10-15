import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/document_service.dart';
import '../../widgets/africa_map.dart';
import '../../widgets/app_scaffold.dart';

class _C {
  static const nuit = Color(0xFF060A1F);
  static const nuit2 = Color(0xFF121845);
  static const nuit3 = Color(0xFF0B102E);
  static const or = Color(0xFFC4952B);
  static const orClair = Color(0xFFF0D9A0);
  static const vert = Color(0xFF0F7A3D);
  static const violet = Color(0xFF7A4E8C);
  static const rouge = Color(0xFFB4473A);
  static const teal = Color(0xFF2F7D6D);
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

class InstitutionsScreen extends StatefulWidget {
  const InstitutionsScreen({super.key});
  @override
  State<InstitutionsScreen> createState() => _InstitutionsScreenState();
}

class _InstitutionsScreenState extends State<InstitutionsScreen> {
  bool _loading = true;
  List<Map<String, dynamic>> _sections = [];
  List<Map<String, dynamic>> _niveaux = [];
  List<Map<String, dynamic>> _poles = [];
  List<Map<String, dynamic>> _grades = [];
  Map<String, String> _images = {};
  String? _carteRegion;
  bool _carteOrg = true;
  String? _carteSelected;

  final Set<String> _ouverts = {'organigramme'};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final data = await DocumentService.loadInstitutions(force: true);
    setState(() {
      _sections = List<Map<String, dynamic>>.from(data['sections'] ?? []);
      // Réordonner : mettre 'organigramme' en 1ère position
      _sections.sort((a, b) {
        final aIsOrg = a['code'] == 'organigramme';
        final bIsOrg = b['code'] == 'organigramme';
        if (aIsOrg && !bIsOrg) return -1;
        if (!aIsOrg && bIsOrg) return 1;
        final aOrdre = (a['numero_ordre'] as num?)?.toInt() ?? 999;
        final bOrdre = (b['numero_ordre'] as num?)?.toInt() ?? 999;
        return aOrdre.compareTo(bOrdre);
      });
      _niveaux = List<Map<String, dynamic>>.from(data['niveaux'] ?? []);
      _poles = List<Map<String, dynamic>>.from(data['poles'] ?? []);
      _grades = List<Map<String, dynamic>>.from(data['grades'] ?? []);
      _loading = false;
    });
    _loadImages();
  }

  Future<void> _loadImages() async {
    try {
      final res = await DocumentService.loadInstitutionImages();
      final map = <String, String>{};
      for (final img in res) {
        if (img['url_image'] != null && (img['url_image'] as String).isNotEmpty) {
          map[img['code'] as String] = img['url_image'] as String;
        }
      }
      if (mounted) setState(() => _images = map);
    } catch (_) {}
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

  Color _parseColor(String? hex) {
    if (hex == null || hex.isEmpty) return _C.or;
    final c = hex.replaceAll('#', '');
    try {
      return Color(int.parse('FF$c', radix: 16));
    } catch (_) {
      return _C.or;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Document institutionnel',
      child: _loading
          ? const Center(child: CircularProgressIndicator(color: _C.or))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _header(),
                const SizedBox(height: 16),
                _actionsRow(),
                const SizedBox(height: 20),
                _carteLigue(),
                const SizedBox(height: 20),
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
          colors: [Color(0xFF7A4E8C), Color(0xFF4A2E5C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'DOCUMENT INSTITUTIONNEL · VERSION 1.0 · OCTOBRE 2026',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 10,
              letterSpacing: 2,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Text('Architecture institutionnelle',
              style: _serif(28, color: Colors.white, weight: FontWeight.w900)),
          const SizedBox(height: 4),
          const Text('De la Ligue jusqu\'au quartier',
              style: TextStyle(color: Colors.white70, fontSize: 14, height: 1.4)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.25),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              '6 niveaux · 5 régions · 21 pôles · 7 grades',
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
            Icons.menu_book,
            'Voir la Charte',
            () => context.go('/charte'),
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
          border: Border.all(color: _C.violet.withOpacity(0.5)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: _C.violet, size: 18),
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
        border: Border.all(color: _C.violet.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.list_alt, color: _C.violet, size: 18),
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
                    const Icon(Icons.chevron_right,
                        color: _C.violet, size: 14),
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
    final contenu = s['contenu'] ?? '';
    final type = (s['type'] ?? 'texte').toString();
    final estOuvert = _ouverts.contains(code);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: _C.nuit3,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: estOuvert ? _C.violet.withOpacity(0.6) : Colors.white12,
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
                      color: estOuvert ? _C.violet : _C.violet.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      _iconeForCode(code),
                      color: estOuvert ? Colors.white : _C.violet,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(titre,
                            style: _serif(15)),
                        if (sousTitre.isNotEmpty)
                          Text(sousTitre,
                              style: const TextStyle(
                                  color: Colors.white54, fontSize: 11)),
                      ],
                    ),
                  ),
                  Icon(
                    estOuvert ? Icons.expand_less : Icons.expand_more,
                    color: _C.violet,
                  ),
                ],
              ),
            ),
          ),
          if (estOuvert) ...[
            const Divider(color: Colors.white12, height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: _buildContenu(code, contenu.toString(), type),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildContenu(String code, String contenu, String type) {
    // Section spéciale : les 6 niveaux (tableau)
    if (code == 'organigramme' || code == 'fonctions') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (contenu.isNotEmpty)
            Text(contenu,
                style: const TextStyle(
                    color: Colors.white70, fontSize: 12.5, height: 1.6)),
          const SizedBox(height: 12),
          if (code == 'organigramme') _organigrammeVisuel(),
          if (code == 'fonctions') _tableauFonctions(),
        ],
      );
    }

    // Section pôles
    if (code == 'poles') {
      return _tableauPoles();
    }

    // Section grades
    if (code == 'grades') {
      return _tableauGrades();
    }

    // Section calendrier
    if (code == 'calendrier') {
      return _tableauCalendrier(contenu);
    }

    // Section déploiement
    if (code == 'deploiement') {
      return _listePhases(contenu);
    }

    // Par défaut : liste ou texte
    if (type == 'liste') {
      return _listeContenu(contenu);
    }

    return Text(contenu,
        style: const TextStyle(color: Colors.white70, fontSize: 12.5, height: 1.6));
  }

  // ===========================================================================
  // TABLEAUX SPÉCIALISÉS
  // ===========================================================================
  Widget _tableauNiveaux() {
    return Column(
      children: _niveaux.map((n) {
        final num = n['numero'];
        final territoire = n['territoire'] ?? '';
        final instance = n['instance'] ?? '';
        final titre = n['titre'] ?? '';
        final forme = n['forme_descriptive'] ?? '';
        final couleur = _parseColor(n['couleur'] as String?);

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _C.nuit2,
            borderRadius: BorderRadius.circular(10),
            border: Border(left: BorderSide(color: couleur, width: 4)),
          ),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: couleur,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text('$num',
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 13)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('$territoire · $instance',
                        style: const TextStyle(
                            color: Colors.white54, fontSize: 10)),
                    const SizedBox(height: 2),
                    Text(titre,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w700)),
                    if (forme.isNotEmpty)
                      Text(forme,
                          style: const TextStyle(
                              color: _C.orClair, fontSize: 11)),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _tableauFonctions() {
    final fonctions = [
      {'titre': 'Mansa', 'attribution': 'Préside le Forum Panafricain et la Prytanie', 'mandat': '1 an, non renouvelable', 'designation': 'Élu par le Forum Panafricain parmi les Mwalimu'},
      {'titre': 'Ola', 'attribution': 'Préside le Forum régional, médiation entre Cités', 'mandat': '2 ans, renouvelable 1 fois', 'designation': 'Élu par le Synédrion régional parmi les Mwalimu'},
      {'titre': 'Mwalimu', 'attribution': 'Autorité morale et pédagogique de la Cité', 'mandat': '3 ans, renouvelable 1 fois', 'designation': 'Élu par le Forum de la Cité parmi les Épimélètes'},
      {'titre': 'Nomarque', 'attribution': 'Représente la Cité dans le Nome', 'mandat': '2 ans', 'designation': 'Élu par le Forum du Nome'},
      {'titre': 'Démarque', 'attribution': 'Responsable du Dème', 'mandat': '2 ans', 'designation': 'Élu par le Forum du Dème'},
      {'titre': 'Agoranome', 'attribution': 'Veille à la vie de l\'Agora', 'mandat': '1 an', 'designation': 'Tiré au sort parmi les volontaires qualifiés'},
    ];
    return Column(
      children: fonctions.map((f) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _C.nuit2,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(f['titre'] as String,
                    style: const TextStyle(
                        color: _C.or, fontSize: 14, fontWeight: FontWeight.w900)),
                const SizedBox(height: 4),
                Text(f['attribution'] as String,
                    style: const TextStyle(
                        color: Colors.white70, fontSize: 12, height: 1.4)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.schedule, color: _C.orClair, size: 12),
                    const SizedBox(width: 4),
                    Text(f['mandat'] as String,
                        style: const TextStyle(
                            color: _C.orClair, fontSize: 10)),
                    const Spacer(),
                    Text(f['designation'] as String,
                        style: const TextStyle(
                            color: Colors.white54, fontSize: 10)),
                  ],
                ),
              ],
            ),
          )).toList(),
    );
  }

  Widget _tableauPoles() {
    return Column(
      children: _poles.map((p) => Container(
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _C.nuit2,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white10),
            ),
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: const BoxDecoration(
                      color: _C.or, shape: BoxShape.circle),
                  child: Center(
                    child: Text('${p['numero']}',
                        style: const TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.w900,
                            fontSize: 11)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${p['nom']}',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600)),
                      if (p['institutions_rattachees'] != null &&
                          (p['institutions_rattachees'] as String).isNotEmpty)
                        Text('${p['institutions_rattachees']}',
                            style: const TextStyle(
                                color: Colors.white54, fontSize: 10)),
                    ],
                  ),
                ),
              ],
            ),
          )).toList(),
    );
  }

  Widget _tableauGrades() {
    return Column(
      children: _grades.map((g) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _C.nuit2,
              borderRadius: BorderRadius.circular(10),
              border: Border(left: BorderSide(color: _C.vert, width: 4)),
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(
                      color: _C.vert, shape: BoxShape.circle),
                  child: Center(
                    child: Text('${g['numero']}',
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 13)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${g['grade']}',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w700)),
                      const SizedBox(height: 2),
                      Text('${g['etape_parcours'] ?? ""}',
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 11)),
                      if (g['fonctions_accessibles'] != null)
                        Text('Fonctions : ${g['fonctions_accessibles']}',
                            style: const TextStyle(
                                color: _C.orClair, fontSize: 10)),
                    ],
                  ),
                ),
              ],
            ),
          )).toList(),
    );
  }

  Widget _tableauCalendrier(String contenu) {
    // Le contenu est déjà formaté en "Instance — Fréquence — Objet"
    final lignes = contenu.split('\n\n');
    return Column(
      children: lignes.map((l) {
        final parts = l.split(' — ');
        if (parts.length >= 3) {
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _C.nuit2,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(parts[0],
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: _C.or.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(parts[1],
                          style: const TextStyle(
                              color: _C.or, fontSize: 10,
                              fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(parts[2],
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 11)),
                    ),
                  ],
                ),
              ],
            ),
          );
        }
        return Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Text(l,
              style: const TextStyle(
                  color: Colors.white70, fontSize: 12, height: 1.5)),
        );
      }).toList(),
    );
  }

  Widget _listePhases(String contenu) {
    final phases = contenu.split('\n\n');
    return Column(
      children: phases.map((p) {
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _C.nuit2,
            borderRadius: BorderRadius.circular(10),
            border: Border(left: BorderSide(color: _C.teal, width: 4)),
          ),
          child: Text(p,
              style: const TextStyle(
                  color: Colors.white70, fontSize: 12, height: 1.6)),
        );
      }).toList(),
    );
  }

  Widget _listeContenu(String contenu) {
    final lignes = contenu.split('\n\n');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: lignes.map((l) {
        if (l.isEmpty) return const SizedBox.shrink();
        final parts = l.split(' : ');
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.circle, color: _C.or, size: 6),
              const SizedBox(width: 8),
              Expanded(
                child: parts.length >= 2
                    ? RichText(
                        text: TextSpan(
                          style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                              height: 1.5),
                          children: [
                            TextSpan(
                                text: '${parts[0]} : ',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700)),
                            TextSpan(text: parts.sublist(1).join(' : ')),
                          ],
                        ),
                      )
                    : Text(l,
                        style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            height: 1.5)),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  IconData _iconeForCode(String code) {
    switch (code) {
      case 'intro':
        return Icons.info;
      case 'chiffres':
        return Icons.numbers;
      case 'principes':
        return Icons.star;
      case 'titres':
        return Icons.badge;
      case 'organigramme':
        return Icons.account_tree;
      case 'fonctions':
        return Icons.assignment_ind;
      case 'instances':
        return Icons.support_agent;
      case 'organes':
        return Icons.account_balance;
      case 'separation':
        return Icons.balance;
      case 'poles':
        return Icons.grid_view;
      case 'grades':
        return Icons.military_tech;
      case 'roles_seance':
        return Icons.gavel;
      case 'regions':
        return Icons.public;
      case 'calendrier':
        return Icons.calendar_month;
      case 'deliberation':
        return Icons.forum;
      case 'equivalences':
        return Icons.translate;
      case 'statut':
        return Icons.verified_user;
      case 'deploiement':
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
          const Icon(Icons.verified, color: _C.violet, size: 24),
          const SizedBox(height: 10),
          Text('Adoption',
              style: _serif(14, color: _C.orClair)),
          const SizedBox(height: 6),
          const Text(
            'Document adopté par le Forum constituant.\nLe Mansa · Le Grammate · Le Président de séance',
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

  // ===========================================================================
  // ORGANIGRAMME VISUEL
  // ===========================================================================
  Widget _organigrammeVisuel() {
    // Si une image est disponible, on l'affiche
    if (_images.containsKey('organigramme')) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: _C.nuit2,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _C.violet.withOpacity(0.4)),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.network(
                _images['organigramme']!,
                fit: BoxFit.contain,
                loadingBuilder: (c, child, progress) {
                  if (progress == null) return child;
                  return const Padding(
                    padding: EdgeInsets.all(40),
                    child: Center(
                      child: CircularProgressIndicator(color: _C.or),
                    ),
                  );
                },
                errorBuilder: (c, e, s) => _organigrammeFallback(),
              ),
            ),
          ),
          const SizedBox(height: 10),
          _boutonTelecharger('organigramme'),
        ],
      );
    }

    // Sinon, widget visuel interactif
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _organigrammeFallback(),
        const SizedBox(height: 10),
        _boutonUploaderPNG(),
      ],
    );
  }

  // ===========================================================================
  // BOUTON TÉLÉCHARGER (si image existe)
  // ===========================================================================
  Widget _boutonTelecharger(String code) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () => _toast('Téléchargement lancé'),
        icon: const Icon(Icons.download, color: _C.violet, size: 16),
        label: const Text(
          'Télécharger l\'organigramme (PNG)',
          style: TextStyle(
            color: _C.violet,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: _C.violet.withOpacity(0.5)),
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // BOUTON UPLOAD (si image manquante)
  // ===========================================================================
  Widget _boutonUploaderPNG() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _C.nuit2,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        children: [
          const Icon(Icons.image, color: _C.or, size: 18),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Image haute résolution bientôt disponible. Le schéma ci-dessus est interactif.',
              style: TextStyle(
                  color: Colors.white54, fontSize: 11, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // FALLBACK — Widget visuel reproduisant l'organigramme
  // ===========================================================================
  Widget _organigrammeFallback() {
    if (_niveaux.isEmpty) return const SizedBox.shrink();

    return LayoutBuilder(builder: (context, cons) {
      final large = cons.maxWidth >= 700;
      return Column(
        children: [
          for (int i = 0; i < _niveaux.length; i++) ...[
            _niveauBloc(_niveaux[i], large),
            if (i < _niveaux.length - 1) _flecheDescendante(),
          ],
        ],
      );
    });
  }

  // ===========================================================================
  // UN BLOC DE NIVEAU
  // ===========================================================================
  Widget _niveauBloc(Map<String, dynamic> n, bool large) {
    final numero = n['numero'];
    final territoire = n['territoire'] ?? '';
    final instance = n['instance'] ?? '';
    final titre = n['titre'] ?? '';
    final forme = n['forme_descriptive'] ?? '';
    final couleur = _parseColor(n['couleur'] as String?);

    return Container(
      decoration: BoxDecoration(
        color: _C.nuit3,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: couleur.withOpacity(0.5), width: 2),
        boxShadow: [
          BoxShadow(
            color: couleur.withOpacity(0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Bloc principal
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: couleur.withOpacity(0.15),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              border: Border(
                bottom: BorderSide(color: couleur.withOpacity(0.3), width: 1),
              ),
            ),
            child: Row(
              children: [
                // Numéro dans cercle
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: couleur,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: couleur.withOpacity(0.5),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      '$numero',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$territoire · $instance',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 10,
                          letterSpacing: 1.2,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        titre,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                      if (forme.isNotEmpty)
                        Text(
                          forme,
                          style: TextStyle(
                            color: couleur,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Instances d'appui
          Padding(
            padding: const EdgeInsets.all(12),
            child: large
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.subdirectory_arrow_right,
                          color: Colors.white38, size: 16),
                      const SizedBox(width: 8),
                      Expanded(child: _instancesDuNiveau(numero)),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.subdirectory_arrow_right,
                              color: Colors.white38, size: 14),
                          SizedBox(width: 6),
                          Text(
                            'INSTANCES',
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: 9,
                              letterSpacing: 1.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      _instancesDuNiveau(numero),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // FLÈCHE DESCENDANTE
  // ===========================================================================
  Widget _flecheDescendante() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          Container(
            width: 2,
            height: 18,
            color: _C.violet.withOpacity(0.6),
          ),
          Icon(
            Icons.arrow_drop_down,
            color: _C.violet.withOpacity(0.9),
            size: 22,
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // INSTANCES D'UN NIVEAU (badges)
  // ===========================================================================
  Widget _instancesDuNiveau(dynamic numero) {
    final instances = {
      1: [
        'Forum Panafricain',
        'Synédrion des Cités',
        'Collège des Épimélètes',
        'Aréopage',
        'Hélieé'
      ],
      2: [
        'Forum régional',
        'Synédrion régional',
        'Délégués des Cités de la région'
      ],
      3: [
        'Forum de la Cité',
        'Boulé',
        'Épimélètes',
        'Aréopage',
        'Hélieé',
        'Logistes',
        'Tamias'
      ],
      4: ['Forum du Nome', 'Délégués des dèmes du département'],
      5: ['Forum du Dème', 'Délégués des Agoras de la commune'],
      6: ['Assemblée de l\'Agora', 'Tous les membres du quartier'],
    };

    final list = instances[numero] ?? [];

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: list
          .map((inst) => Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.white12),
                ),
                child: Text(
                  inst,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ))
          .toList(),
    );
  }

  // ===========================================================================
  // CARTE DE LA LIGUE (en haut de page)
  // ===========================================================================
  Widget _carteLigue() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _C.nuit2,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _C.violet.withOpacity(0.5), width: 2),
        boxShadow: [
          BoxShadow(
            color: _C.violet.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // TITRE
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _C.violet,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.public, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Carte de la Ligue',
                        style: _serif(20)),
                    const SizedBox(height: 2),
                    const Text(
                      '5 régions · 55 Cités · Organigramme sur le continent',
                      style: TextStyle(
                          color: Colors.white54, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // TOGGLE ORGANIGRAMME
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: _C.nuit3,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white12),
            ),
            child: Row(
              children: [
                const Icon(Icons.account_tree, color: _C.or, size: 18),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Afficher l\'organigramme',
                    style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w600),
                  ),
                ),
                Switch(
                  value: _carteOrg,
                  activeColor: _C.or,
                  onChanged: (v) => setState(() => _carteOrg = v),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // FILTRES PAR RÉGION
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _carteChip(null, 'Toutes'),
              for (final r in kRegions.values)
                _carteChip(r.code, r.name),
            ],
          ),

          const SizedBox(height: 16),

          // CARTE + LÉGENDE (2 colonnes sur desktop)
          LayoutBuilder(builder: (ctx, cons) {
            final large = cons.maxWidth >= 800;

            final carteWidget = SizedBox(
              height: 500,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: AfricaMap(
                  highlightRegion: _carteRegion,
                  selectedId: _carteSelected,
                  showOrg: _carteOrg,
                  onCountryTap: (c) {
                    setState(() => _carteSelected = c.id);
                    _showOrganeSheet(context, c);
                  },
                ),
              ),
            );

            if (large) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 3, child: carteWidget),
                  const SizedBox(width: 16),
                  Expanded(flex: 2, child: _legendeCarte()),
                ],
              );
            }

            return Column(
              children: [
                carteWidget,
                const SizedBox(height: 16),
                _legendeCarte(),
              ],
            );
          }),
        ],
      ),
    );
  }

  // ===========================================================================
  // CHIP DE FILTRE
  // ===========================================================================
  Widget _carteChip(String? code, String label) {
    final sel = _carteRegion == code;
    final color = code == null ? _C.or : kRegions[code]!.color;
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          color: sel ? Colors.white : Colors.white70,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
      selected: sel,
      onSelected: (_) =>
          setState(() => _carteRegion = sel ? null : code),
      selectedColor: color,
      backgroundColor: Colors.white10,
      side: BorderSide(color: color.withOpacity(0.7)),
      showCheckmark: false,
    );
  }

  // ===========================================================================
  // LÉGENDE COMPLÈTE (reproduit la légende du PDF)
  // ===========================================================================
  Widget _legendeCarte() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _C.nuit3,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _C.or.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // TITRE
          const Text(
            'LÉGENDE',
            style: TextStyle(
              color: _C.or,
              fontSize: 11,
              letterSpacing: 3,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 14),

          // SECTION ICÔNES
          _legendeIcone(
            icon: Icons.star,
            color: _C.or,
            label: 'Mansa de la Ligue',
            count: '1',
          ),
          _legendeIcone(
            icon: Icons.circle,
            color: const Color(0xFF7A4E8C),
            label: 'Ola de région',
            count: '5',
          ),
          _legendeIcone(
            icon: Icons.circle,
            color: Colors.white,
            label: 'Mwalimu de la Cité',
            count: '1 par pays',
            small: true,
          ),

          const SizedBox(height: 10),

          // LIENS
          _legendeLigne(
            label: 'Lien Ligue – régions',
            painter: _LegendeDashedLine(color: _C.or),
          ),
          _legendeLigne(
            label: 'Lien région – Cités',
            painter: _LegendeSolidLine(color: const Color(0xFF6B7A99)),
          ),

          const SizedBox(height: 18),

          // SECTION RÉGIONS
          const Text(
            'RÉGIONS (Union africaine)',
            style: TextStyle(
              color: _C.or,
              fontSize: 10,
              letterSpacing: 2,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          _legendeRegion('Afrique du Nord', const Color(0xFFB9772E), 7),
          _legendeRegion('Afrique de l\'Ouest', const Color(0xFF2F7D6D), 15),
          _legendeRegion('Afrique centrale', const Color(0xFF7A4E8C), 9),
          _legendeRegion('Afrique de l\'Est', const Color(0xFFB4473A), 14),
          _legendeRegion('Afrique australe', const Color(0xFF2E5E8C), 10),

          const SizedBox(height: 18),

          // SECTION NIVEAUX
          const Text(
            'NIVEAUX',
            style: TextStyle(
              color: _C.or,
              fontSize: 10,
              letterSpacing: 2,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          _legendeNiveau('1', 'Ligue', 'Mansa'),
          _legendeNiveau('2', 'Région', 'Ola'),
          _legendeNiveau('3', 'Cité (pays)', 'Mwalimu'),
          _legendeNiveau('4', 'Nome', 'Nomarque'),
          _legendeNiveau('5', 'Dème', 'Démarque'),
          _legendeNiveau('6', 'Agora', 'Agoranome'),
        ],
      ),
    );
  }

  // Ligne d'icône (Mansa/Ola/Mwalimu)
  Widget _legendeIcone({
    required IconData icon,
    required Color color,
    required String label,
    required String count,
    bool small = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 24,
            child: Icon(icon, color: color, size: small ? 10 : 18),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 11.5,
              ),
            ),
          ),
          Text(
            '($count)',
            style: TextStyle(
              color: Colors.white38,
              fontSize: 10.5,
            ),
          ),
        ],
      ),
    );
  }

  // Ligne de lien (dashed/solid)
  Widget _legendeLigne({
    required String label,
    required CustomPainter painter,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(
            width: 24,
            height: 12,
            child: CustomPaint(painter: painter),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Ligne région (couleur + nb Cités)
  Widget _legendeRegion(String nom, Color couleur, int nbCites) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: couleur,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              nom,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 11.5,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              '$nbCites Cités',
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Ligne niveau (N → Titre)
  Widget _legendeNiveau(String num, String nom, String titre) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          SizedBox(
            width: 16,
            child: Text(
              '$num.',
              style: const TextStyle(
                color: _C.or,
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 11,
                ),
                children: [
                  TextSpan(text: nom),
                  const TextSpan(
                    text: ' → ',
                    style: TextStyle(color: Colors.white38),
                  ),
                  TextSpan(
                    text: titre,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }


  // ===========================================================================
  // FICHE INSTITUTIONNELLE (au lieu de "Rejoindre la Cité")
  // ===========================================================================
  void _showOrganeSheet(BuildContext context, CountryShape c) {
    final region = kRegions[c.region]!;

    // Trouver le niveau 3 (Mwalimu) comme référence
    final niveau3 = _niveaux.firstWhere(
      (n) => n['numero'] == 3,
      orElse: () => <String, dynamic>{},
    );

    // Informations sur la Cité (niveau 3 = Pays)
    final titre = niveau3['titre'] ?? 'Mwalimu';
    final forme = niveau3['forme_descriptive'] ?? 'Président de la Cité';
    final instance = niveau3['instance'] ?? 'Forum de la Cité';

    // Instances locales d'une Cité
    const instancesCite = [
      'Forum de la Cité',
      'Boulé',
      'Épimélètes',
      'Aréopage',
      'Hélieé',
      'Logistes',
      'Tamias',
    ];

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(ctx).size.height * 0.85,
        ),
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
        decoration: BoxDecoration(
          color: _C.nuit3,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(top: BorderSide(color: region.color, width: 4)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Poignée de drag
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Titre
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: region.color,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '3',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          c.name,
                          style: _serif(22, color: Colors.white),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Cité des Neurocitoyens',
                          style: TextStyle(
                            color: _C.orClair,
                            fontSize: 12,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Région
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: region.color.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: region.color),
                    ),
                    child: Text(
                      region.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _C.violet.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: _C.violet),
                    ),
                    child: Text(
                      'Niveau 3 · $titre',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Description
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _C.nuit2,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _C.violet.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'DÉFINITION',
                      style: TextStyle(
                        color: _C.violet,
                        fontSize: 10,
                        letterSpacing: 2,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Autorité morale et pédagogique de la Cité. '
                      'Préside le Forum de la Cité, désigne l\'Épistate, '
                      'promulgue les Résolutions et représente la Cité. '
                      'Rend compte chaque année à l\'Aréopage.',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12.5,
                        height: 1.6,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // Mandat
              _infoRow('Mandat', '3 ans, renouvelable une fois'),
              _infoRow('Désignation',
                  'Élu par le Forum de la Cité parmi les Épimélètes'),
              _infoRow('Instance', instance),

              const SizedBox(height: 20),

              // Déclinaison locale
              const Text(
                'INSTANCES LOCALES DE LA CITÉ',
                style: TextStyle(
                  color: _C.or,
                  fontSize: 10,
                  letterSpacing: 2,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: instancesCite
                    .map((inst) => Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.06),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.white12),
                          ),
                          child: Text(
                            inst,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                            ),
                          ),
                        ))
                    .toList(),
              ),

              const SizedBox(height: 20),

              // Info complémentaire
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _C.violet.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _C.violet.withOpacity(0.4)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline,
                        color: _C.violet, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Chaque Cité reproduit l\'architecture complète de la Ligue '
                        '(Mansa → Ola → Mwalimu) avec en plus la Boulé, les Logistes et le Tamias.',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Bouton fermer uniquement
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                      side: BorderSide(color: Colors.white24),
                    ),
                  ),
                  child: const Text(
                    'Fermer',
                    style: TextStyle(
                      color: Colors.white70,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              '$label :',
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 11.5,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// PAINTERS POUR LA LÉGENDE
// =============================================================================
class _LegendeDashedLine extends CustomPainter {
  _LegendeDashedLine({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    const dashWidth = 4.0;
    const gapWidth = 3.0;
    double x = 0;
    while (x < size.width) {
      canvas.drawLine(
        Offset(x, size.height / 2),
        Offset(x + dashWidth, size.height / 2),
        paint,
      );
      x += dashWidth + gapWidth;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _LegendeSolidLine extends CustomPainter {
  _LegendeSolidLine({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5;

    canvas.drawLine(
      Offset(0, size.height / 2),
      Offset(size.width, size.height / 2),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

