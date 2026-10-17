import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/config_service.dart';
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
    {Color color = Colors.white, FontWeight weight = FontWeight.w700}) {
  return TextStyle(
    fontFamily: 'Georgia',
    fontFamilyFallback: const ['Times New Roman', 'serif'],
    fontSize: size,
    color: color,
    fontWeight: weight,
  );
}

class MonCheminementScreen extends StatefulWidget {
  const MonCheminementScreen({super.key});
  @override
  State<MonCheminementScreen> createState() => _MonCheminementScreenState();
}

class _MonCheminementScreenState extends State<MonCheminementScreen> {
  bool _loading = true;
  List<Map<String, dynamic>> _etapes = [];
  Map<int, int> _etapesValidees = {};
  Map<String, String> _config = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      _config = await ConfigService.loadAll(force: true);

      final res = await Supabase.instance.client
          .from('etapes_parcours')
          .select()
          .order('numero');
      _etapes = List<Map<String, dynamic>>.from(res);

      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id');
      if (userId != null) {
        try {
          final prog = await Supabase.instance.client
              .from('user_progress')
              .select('etape_numero, statut')
              .eq('user_id', userId);
          for (final row in prog) {
            final num = row['etape_numero'] as int?;
            if (num != null) {
              _etapesValidees[num] = _statutVersInt(row['statut'] as String?);
            }
          }
        } catch (_) {}
      }
    } catch (_) {}
    setState(() => _loading = false);
  }

  int _statutVersInt(String? statut) {
    switch (statut) {
      case 'certifie':
      case 'termine':
        return 3;
      case 'en_cours':
        return 2;
      case 'non_commence':
        return 1;
      default:
        return 0;
    }
  }

  int _statutEtape(int numero) {
    final saved = _etapesValidees[numero] ?? 0;
    if (saved > 0) return saved;
    if (numero == 1) return 1;
    final etape = _etapes.firstWhere(
      (e) => e['numero'] == numero,
      orElse: () => <String, dynamic>{},
    );
    final prerequis = etape['prerequis'] as int?;
    if (prerequis != null) {
      final statutPrerequis = _etapesValidees[prerequis] ?? 0;
      if (statutPrerequis < 3) return 0;
    }
    return 1;
  }

  int get _etapesCompletees =>
      _etapesValidees.values.where((s) => s >= 3).length;
  double get _progression => _etapesCompletees / 7;

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Mon Cheminement',
      child: _loading
          ? const Center(child: CircularProgressIndicator(color: _C.or))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _header(),
                const SizedBox(height: 20),
                _progressionCard(),
                const SizedBox(height: 24),
                _parcoursTitle(),
                const SizedBox(height: 12),
                ..._etapes.map(_etapeCard),
                const SizedBox(height: 24),
                _avantagesCard(),
                const SizedBox(height: 24),
                _paiementCard(),
                const SizedBox(height: 24),
                _footerCard(),
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
            'MON CHEMINEMENT NEUROCITOYEN',
            style: TextStyle(
              color: Colors.black54,
              fontSize: 11,
              letterSpacing: 2,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Text('7 étapes vers la transformation',
              style: _serif(26, color: Colors.black, weight: FontWeight.w900)),
          const SizedBox(height: 6),
          const Text(
            'Un parcours progressif : de la conscience de soi à l\'autonomie économique.',
            style: TextStyle(color: Colors.black87, fontSize: 13, height: 1.5),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // PROGRESSION
  // ===========================================================================
  Widget _progressionCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _C.nuit3,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _C.or.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.trending_up, color: _C.or, size: 20),
              const SizedBox(width: 8),
              Text('Ma progression', style: _serif(16)),
              const Spacer(),
              Text('$_etapesCompletees / 7', style: _serif(20, color: _C.or)),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: _progression,
              minHeight: 10,
              backgroundColor: Colors.white10,
              valueColor: const AlwaysStoppedAnimation(_C.or),
            ),
          ),
          const SizedBox(height: 8),
          Text('${(_progression * 100).round()}% du parcours complété',
              style: const TextStyle(color: Colors.white54, fontSize: 11)),
        ],
      ),
    );
  }

  // ===========================================================================
  // TITRE PARCOURS
  // ===========================================================================
  Widget _parcoursTitle() {
    return Row(
      children: [
        const Icon(Icons.route, color: _C.or, size: 20),
        const SizedBox(width: 8),
        Text('Les 7 étapes', style: _serif(20)),
      ],
    );
  }

  // ===========================================================================
  // CARTE ÉTAPE
  // ===========================================================================
  Widget _etapeCard(Map<String, dynamic> e) {
    final numero = e['numero'] as int;
    final titre = e['titre'] as String? ?? 'Étape $numero';
    final sousTitre = e['sous_titre'] as String? ?? '';
    final description = e['description'] as String? ?? '';
    final prix = (e['prix_fcfa'] as num?)?.toInt() ?? 0;
    final gratuit = e['gratuit'] == true || prix == 0;
    final prerequisDesc = e['prerequis_description'] as String? ?? '';
    final objectifs = e['objectifs'] as List?;
    final contenu = e['contenu_complet'] as Map?;
    final couleur = _couleurFromString(e['couleur'] as String?);

    final statut = _statutEtape(numero);
    final estVerrouille = statut == 0;
    final estEnCours = statut == 2;
    final estValide = statut >= 3;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: _C.nuit3,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: estValide
              ? _C.vert.withOpacity(0.6)
              : estEnCours
                  ? _C.or.withOpacity(0.6)
                  : estVerrouille
                      ? Colors.white12
                      : couleur.withOpacity(0.5),
          width: estValide || estEnCours ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: estVerrouille
                        ? Colors.white10
                        : (estValide ? _C.vert : couleur),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: estVerrouille
                        ? const Icon(Icons.lock, color: Colors.white54, size: 20)
                        : estValide
                            ? const Icon(Icons.check, color: Colors.white, size: 24)
                            : Text('$numero',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Étape $numero',
                          style: TextStyle(
                              color: estVerrouille ? Colors.white38 : _C.or,
                              fontSize: 10,
                              letterSpacing: 2,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(height: 2),
                      Text(titre,
                          style: TextStyle(
                              color: estVerrouille ? Colors.white54 : Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700)),
                      if (sousTitre.isNotEmpty)
                        Text(sousTitre,
                            style: const TextStyle(
                                color: Colors.white54, fontSize: 11)),
                    ],
                  ),
                ),
                if (estValide)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _C.vert.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: _C.vert),
                    ),
                    child: const Text('VALIDÉ',
                        style: TextStyle(
                            color: _C.vert,
                            fontSize: 10,
                            fontWeight: FontWeight.bold)),
                  )
                else if (estEnCours)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _C.or.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: _C.or),
                    ),
                    child: const Text('EN COURS',
                        style: TextStyle(
                            color: _C.or,
                            fontSize: 10,
                            fontWeight: FontWeight.bold)),
                  ),
              ],
            ),
          ),
          if (description.isNotEmpty && !estVerrouille)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(description,
                  style: const TextStyle(
                      color: Colors.white70, fontSize: 12, height: 1.5)),
            ),
          if (estVerrouille && prerequisDesc.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline,
                        color: Colors.white54, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text('Pour débloquer : $prerequisDesc',
                          style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 11,
                              height: 1.4)),
                    ),
                  ],
                ),
              ),
            ),
          if (!estVerrouille && contenu != null) ...[
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  if (contenu['duree_semaines'] != null)
                    _pill(Icons.schedule, '${contenu['duree_semaines']} sem.'),
                  if (contenu['coach_ia'] == true)
                    _pill(Icons.smart_toy, 'Coach IA'),
                  if (contenu['certificat'] != null)
                    _pill(Icons.workspace_premium,
                        contenu['certificat'].toString()),
                ],
              ),
            ),
          ],
          if (!estVerrouille) ...[
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: gratuit
                          ? _C.vert.withOpacity(0.15)
                          : _C.or.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: gratuit ? _C.vert : _C.or, width: 1),
                    ),
                    child: Text(
                      gratuit ? 'GRATUIT' : ConfigService.formatPrix(prix),
                      style: TextStyle(
                          color: gratuit ? _C.vert : _C.or,
                          fontSize: 12,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                  const Spacer(),
                  ElevatedButton(
                    onPressed: () => _onEtapeTap(numero),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: estValide
                          ? Colors.white10
                          : (estEnCours ? _C.orClair : _C.or),
                      foregroundColor:
                          estValide ? Colors.white : Colors.black,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 10),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24)),
                    ),
                    child: Text(
                      estValide
                          ? 'REVOIR'
                          : estEnCours
                              ? 'CONTINUER'
                              : 'COMMENCER',
                      style: const TextStyle(
                          fontWeight: FontWeight.w900, fontSize: 11),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _pill(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: _C.orClair, size: 11),
          const SizedBox(width: 4),
          Text(label,
              style: const TextStyle(color: Colors.white70, fontSize: 10)),
        ],
      ),
    );
  }

  Color _couleurFromString(String? hex) {
    if (hex == null || hex.isEmpty) return _C.or;
    final cleaned = hex.replaceAll('#', '');
    try {
      return Color(int.parse('FF$cleaned', radix: 16));
    } catch (_) {
      return _C.or;
    }
  }

  void _onEtapeTap(int numero) {
    context.go('/universite');
  }

  // ===========================================================================
  // AVANTAGES DU MEMBRE
  // ===========================================================================
  Widget _avantagesCard() {
    final avantages = <String>[
      '🪪 Carte dès la première tranche de 500 FCFA, avec accès immédiat au prix de gros',
      '🏷 Tarif membre sur toutes les formations et tous les services',
      '💸 Ristourne en fin d\'année, selon tes achats ou ton travail',
      '🗳 Une voix à l\'assemblée, statut de membre fondateur au Forum constituant',
      '↩ Ta part sociale reste à toi, remboursable si tu pars',
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _C.nuit3,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _C.or.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.star, color: _C.or, size: 20),
              const SizedBox(width: 8),
              Text('Les avantages du membre', style: _serif(18)),
            ],
          ),
          const SizedBox(height: 4),
          const Text('Ce que tu obtiens dès l\'adhésion',
              style: TextStyle(color: Colors.white54, fontSize: 11)),
          const SizedBox(height: 14),
          ...avantages.map((a) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(a,
                    style: const TextStyle(
                        color: Colors.white70, fontSize: 12, height: 1.5)),
              )),
        ],
      ),
    );
  }

  // ===========================================================================
  // PAIEMENT
  // ===========================================================================
  Widget _paiementCard() {
    final prixPart = int.tryParse(_config['part_sociale'] ?? '5000') ?? 5000;
    final prixCarte =
        int.tryParse(_config['carte_membre_premiere_tranche'] ?? '500') ?? 500;
    final tranchesMax =
        int.tryParse(_config['paiement_graduel_max_tranches'] ?? '3') ?? 3;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _C.nuit2,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _C.orClair.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.payment, color: _C.or, size: 20),
              const SizedBox(width: 8),
              Text('Comment payer', style: _serif(18)),
            ],
          ),
          const SizedBox(height: 16),
          _paiementLigne(
            'Part sociale',
            ConfigService.formatPrix(prixPart),
            'Remboursable à la sortie',
          ),
          const SizedBox(height: 10),
          _paiementLigne(
            '1ère tranche carte membre',
            ConfigService.formatPrix(prixCarte),
            'Pour recevoir ta carte',
          ),
          const SizedBox(height: 10),
          _paiementLigne(
            'Paiement graduel',
            'Jusqu\'à $tranchesMax tranches',
            'Échelonne ton paiement',
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _C.or.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _C.or.withOpacity(0.4)),
            ),
            child: const Text(
              'Modes de paiement acceptés : MTN MoMo, Moov Money, Celtiis Cash, virement bancaire, espèces.',
              style: TextStyle(color: _C.orClair, fontSize: 11, height: 1.5),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _showPaiementModal(),
              style: ElevatedButton.styleFrom(
                backgroundColor: _C.or,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30)),
              ),
              child: const Text('PAYER MA PART SOCIALE',
                  style: TextStyle(
                      fontWeight: FontWeight.w900, fontSize: 13)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _paiementLigne(String label, String montant, String sousLabel) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              Text(sousLabel,
                  style: const TextStyle(color: Colors.white54, fontSize: 11)),
            ],
          ),
        ),
        Text(montant,
            style: const TextStyle(
                color: _C.or, fontSize: 14, fontWeight: FontWeight.bold)),
      ],
    );
  }

  void _showPaiementModal() {
    final prixPart = int.tryParse(_config['part_sociale'] ?? '5000') ?? 5000;
    final modes = [
      {'nom': 'MTN Mobile Money', 'icone': Icons.phone_android},
      {'nom': 'Moov Money', 'icone': Icons.phone_android},
      {'nom': 'Celtiis Cash', 'icone': Icons.phone_android},
      {'nom': 'Virement bancaire', 'icone': Icons.account_balance},
      {'nom': 'Espèces', 'icone': Icons.payments},
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: _C.nuit2,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Payer ma part sociale', style: _serif(20)),
            const SizedBox(height: 6),
            Text('Montant : ${ConfigService.formatPrix(prixPart)}',
                style: const TextStyle(color: _C.orClair, fontSize: 13)),
            const SizedBox(height: 16),
            const Text('Choisis ton mode de paiement :',
                style: TextStyle(color: Colors.white70, fontSize: 12)),
            const SizedBox(height: 12),
            ...modes.map((m) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: Icon(m['icone'] as IconData, color: _C.or),
                    title: Text(m['nom'] as String,
                        style: const TextStyle(color: Colors.white)),
                    trailing:
                        const Icon(Icons.chevron_right, color: _C.or),
                    onTap: () {
                      Navigator.pop(ctx);
                      _toast('Paiement via ${m['nom']} bientôt disponible');
                    },
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: const BorderSide(color: Colors.white12)),
                    tileColor: _C.nuit3,
                  ),
                )),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // FOOTER
  // ===========================================================================
  Widget _footerCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _C.nuit3,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: const Column(
        children: [
          Icon(Icons.info_outline, color: _C.or, size: 24),
          SizedBox(height: 10),
          Text(
            'Aucune rémunération pour avoir invité quelqu\'un.\nTa part sociale est remboursable à la sortie.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.5),
          ),
          SizedBox(height: 8),
          Text(
            'Les montants sont en FCFA et seront adaptés dans les pays hors zone CFA.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white38, fontSize: 10, height: 1.5),
          ),
        ],
      ),
    );
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      backgroundColor: _C.nuit2,
      content: Text(msg, style: const TextStyle(color: _C.or, fontSize: 12)),
    ));
  }
}
