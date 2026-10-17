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

class CharteScreen extends StatefulWidget {
  const CharteScreen({super.key});
  @override
  State<CharteScreen> createState() => _CharteScreenState();
}

class _CharteScreenState extends State<CharteScreen> {
  bool _loading = true;
  List<Map<String, dynamic>> _titres = [];
  List<Map<String, dynamic>> _articles = [];
  List<Map<String, dynamic>> _annexes = [];
  List<Map<String, dynamic>> _historique = [];

  // Titres ouverts
  final Set<String> _ouverts = {'0'}; // Préambule ouvert par défaut

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final data = await DocumentService.loadCharte(force: true);
    setState(() {
      _titres = List<Map<String, dynamic>>.from(data['titres'] ?? []);
      _articles = List<Map<String, dynamic>>.from(data['articles'] ?? []);
      _annexes = List<Map<String, dynamic>>.from(data['annexes'] ?? []);
      _historique = List<Map<String, dynamic>>.from(data['historique'] ?? []);
      _loading = false;
    });
  }

  void _toggleTitre(String code) {
    setState(() {
      if (_ouverts.contains(code)) {
        _ouverts.remove(code);
      } else {
        _ouverts.add(code);
      }
    });
  }

  List<Map<String, dynamic>> _articlesDuTitre(String titreId) {
    return _articles.where((a) => a['titre_id'] == titreId).toList();
  }

  void _scrollTo(int numero) {
    // Simple : on ouvre tous les titres et on notifie
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      backgroundColor: _C.nuit2,
      content: Text('Voir Article $numero',
          style: const TextStyle(color: _C.or, fontSize: 12)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Charte fondamentale',
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
                ..._titres.map(_titreBloc),
                const SizedBox(height: 20),
                _annexesSection(),
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
          colors: [_C.or, Color(0xFF8B6914)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'TEXTE FONDATEUR · VERSION 2.0 · OCTOBRE 2026',
            style: TextStyle(
              color: Colors.black54,
              fontSize: 10,
              letterSpacing: 2,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Text('Charte fondamentale',
              style: _serif(28, color: Colors.black, weight: FontWeight.w900)),
          const SizedBox(height: 4),
          const Text('de la Ligue Panafricaine des Neurocitoyens',
              style: TextStyle(color: Colors.black87, fontSize: 14, height: 1.4)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              '14 titres · 89 articles · 5 annexes',
              style: TextStyle(
                  color: Colors.black87, fontSize: 11, fontWeight: FontWeight.bold),
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
            Icons.account_balance,
            'Document institutionnel',
            () => context.go('/institutions'),
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
          border: Border.all(color: _C.or.withOpacity(0.4)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: _C.or, size: 18),
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
        border: Border.all(color: _C.or.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.list_alt, color: _C.or, size: 18),
              const SizedBox(width: 8),
              Text('Sommaire', style: _serif(16)),
            ],
          ),
          const SizedBox(height: 12),
          ..._titres.map((t) {
            final code = t['numero_romain'] ?? '';
            final titre = t['titre'] ?? '';
            final st = t['sous_titre'] ?? '';
            return InkWell(
              onTap: () => _toggleTitre(code),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    SizedBox(
                      width: 30,
                      child: Text(code == '0' ? '—' : code,
                          style: const TextStyle(
                              color: _C.or, fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                    Expanded(
                      child: Text('$titre${st.isNotEmpty ? " · $st" : ""}',
                          style: const TextStyle(color: Colors.white70, fontSize: 12)),
                    ),
                    Icon(
                      _ouverts.contains(code)
                          ? Icons.expand_less
                          : Icons.expand_more,
                      color: _C.or,
                      size: 16,
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
  // BLOC D'UN TITRE (avec articles en accordéon)
  // ===========================================================================
  Widget _titreBloc(Map<String, dynamic> t) {
    final code = (t['numero_romain'] ?? '').toString();
    final titre = t['titre'] ?? '';
    final sousTitre = t['sous_titre'] ?? '';
    final chapeau = t['chapeau'] ?? '';
    final estOuvert = _ouverts.contains(code);
    final articles = _articlesDuTitre(t['id']?.toString() ?? '');

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: _C.nuit3,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: estOuvert ? _C.or.withOpacity(0.6) : Colors.white12,
          width: estOuvert ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // HEADER DU TITRE
          InkWell(
            onTap: () => _toggleTitre(code),
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: estOuvert ? _C.or : _C.or.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        code == '0' ? '§' : code,
                        style: TextStyle(
                          color: estOuvert ? Colors.black : _C.or,
                          fontWeight: FontWeight.w900,
                          fontSize: code.length > 2 ? 11 : 15,
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
                          code == '0' ? 'PRÉAMBULE' : 'TITRE $code',
                          style: const TextStyle(
                            color: _C.or,
                            fontSize: 10,
                            letterSpacing: 2,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(titre,
                            style: _serif(16)),
                        if (sousTitre.isNotEmpty)
                          Text(sousTitre,
                              style: const TextStyle(
                                  color: Colors.white54, fontSize: 11)),
                      ],
                    ),
                  ),
                  Icon(
                    estOuvert ? Icons.expand_less : Icons.expand_more,
                    color: _C.or,
                  ),
                ],
              ),
            ),
          ),

          // CONTENU (chapeau + articles)
          if (estOuvert) ...[
            const Divider(color: Colors.white12, height: 1),
            if (chapeau.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text(chapeau,
                    style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        height: 1.6,
                        fontStyle: FontStyle.italic)),
              ),
            ...articles.map(_articleBloc),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }

  // ===========================================================================
  // BLOC D'UN ARTICLE
  // ===========================================================================
  Widget _articleBloc(Map<String, dynamic> a) {
    final numero = a['numero'];
    final numeroAffiche = a['numero_affiche'] ?? 'Article $numero';
    final contenu = a['contenu'] ?? '';

    // Séparer titre et corps (avant le 1er point)
    final parts = contenu.toString().split('. ');
    final titreArt = parts.isNotEmpty ? parts.first : '';
    final corps = parts.length > 1 ? parts.sublist(1).join('. ') : '';

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(10),
        border: Border(left: BorderSide(color: _C.or.withOpacity(0.6), width: 3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(numeroAffiche,
                  style: const TextStyle(
                      color: _C.or,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1)),
              const Spacer(),
              InkWell(
                onTap: () => _scrollTo(numero is int ? numero : 0),
                child: const Icon(Icons.share, color: Colors.white38, size: 14),
              ),
            ],
          ),
          const SizedBox(height: 6),
          if (titreArt.isNotEmpty)
            Text(titreArt,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    height: 1.3)),
          if (corps.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(corps,
                style: const TextStyle(
                    color: Colors.white70, fontSize: 12.5, height: 1.6)),
          ],
        ],
      ),
    );
  }

  // ===========================================================================
  // ANNEXES
  // ===========================================================================
  Widget _annexesSection() {
    if (_annexes.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _C.nuit2,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _C.or.withOpacity(0.5), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.attachment, color: _C.or, size: 20),
              const SizedBox(width: 8),
              Text('Annexes', style: _serif(18)),
            ],
          ),
          const SizedBox(height: 4),
          Text('${_annexes.length} annexe(s)',
              style: const TextStyle(color: Colors.white54, fontSize: 11)),
          const SizedBox(height: 14),
          ..._annexes.map((a) => Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _C.nuit3,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 30,
                          height: 30,
                          decoration: const BoxDecoration(
                              color: _C.or, shape: BoxShape.circle),
                          child: Center(
                            child: Text(
                              '${a['lettre']}',
                              style: const TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 14),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text('${a['titre']}',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text('${a['contenu']}',
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 12, height: 1.6)),
                  ],
                ),
              )),
        ],
      ),
    );
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
          const Icon(Icons.gavel, color: _C.or, size: 24),
          const SizedBox(height: 10),
          Text('Adoption',
              style: _serif(14, color: _C.orClair)),
          const SizedBox(height: 6),
          const Text(
            'Charte adoptée par le Forum constituant.\nLe Mansa · Le Grammate · Le Président de séance',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.5),
          ),
          if (_historique.isNotEmpty) ...[
            const SizedBox(height: 14),
            const Divider(color: Colors.white12),
            const SizedBox(height: 8),
            const Text('Historique des versions',
                style: TextStyle(
                    color: Colors.white54,
                    fontSize: 10,
                    letterSpacing: 1,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ..._historique.map((h) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: h['actif'] == true ? _C.vert : Colors.white38,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'v${h['version']} · ${h['date_adoption']?.toString().substring(0, 10) ?? ""}',
                        style: TextStyle(
                            color: h['actif'] == true ? Colors.white : Colors.white54,
                            fontSize: 11),
                      ),
                    ],
                  ),
                )),
          ],
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
