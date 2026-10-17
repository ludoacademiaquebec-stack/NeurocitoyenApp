import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/coop_service.dart';
import '../../widgets/app_scaffold.dart';

class _C {
  static const nuit2 = Color(0xFF0E3A3D);
  static const nuit3 = Color(0xFF071D20);
  static const or = Color(0xFFE0A82E);
  static const orClair = Color(0xFFF0BD4A);
  static const vert = Color(0xFF1D7A52);
  static const rouge = Color(0xFF8B2E2E);
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

class CoopScreen extends StatefulWidget {
  const CoopScreen({super.key});
  @override
  State<CoopScreen> createState() => _CoopScreenState();
}

class _CoopScreenState extends State<CoopScreen> {
  bool _loading = true;
  String? _userId;
  Map<String, dynamic> _statut = {};
  List<Map<String, dynamic>> _mesCoops = [];
  List<Map<String, dynamic>> _projetsOuverts = [];
  String? _monQuartierId;
  List<Map<String, dynamic>> _membres = [];
  Map<String, dynamic>? _coopActive;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      _userId = await CoopService.getCurrentUserId();

      if (_userId == null) {
        setState(() => _loading = false);
        return;
      }

      _statut = await CoopService.getStatutCertification(_userId!);
      _mesCoops = await CoopService.mesCooperatives(_userId!);

      if (_mesCoops.isNotEmpty) {
        _coopActive = _mesCoops.first['cooperatives'] as Map<String, dynamic>?;
        final coopId = _coopActive?['id'] as String?;
        if (coopId != null) {
          _membres = await CoopService.membresCooperative(coopId);
        }
      } else {
        // Charger le quartier de l'utilisateur (depuis prefs)
        final prefs = await SharedPreferences.getInstance();
        _monQuartierId = prefs.getString('unite_territoriale_id');
        if (_monQuartierId != null) {
          _projetsOuverts = await CoopService.projetsOuverts(_monQuartierId!);
        }
      }
    } catch (_) {}
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Ma Coopérative',
      child: _loading
          ? const Center(child: CircularProgressIndicator(color: _C.or))
          : RefreshIndicator(
              onRefresh: _load,
              color: _C.or,
              child: _buildBody(),
            ),
    );
  }

  Widget _buildBody() {
    if (_userId == null) return _nonConnecte();
    if (_statut['certifie'] != true) return _nonCertifie();
    if (_coopActive != null) return _dashboard();
    return _pasDeCoop();
  }

  // ===========================================================================
  // ÉTAT 1 : NON CONNECTÉ
  // ===========================================================================
  Widget _nonConnecte() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _cardInfo(
          icon: Icons.lock_outline,
          titre: 'Connecte-toi',
          message:
              'Tu dois être connecté pour rejoindre ou créer une coopérative.',
          bouton: FilledButton(
            style: FilledButton.styleFrom(backgroundColor: _C.or),
            onPressed: () => context.go('/connexion'),
            child: const Text('Se connecter',
                style: TextStyle(color: Colors.black)),
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // ÉTAT 2 : NON CERTIFIÉ
  // ===========================================================================
  Widget _nonCertifie() {
    final neuro = _statut['neurocitoyen'] == true;
    final eecOk = _statut['eec'] == true;
    final eecValides = _statut['eec_valides'] ?? 0;
    final eecTotal = _statut['eec_total'] ?? 0;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: _C.nuit3,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _C.or.withValues(alpha: 0.4)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.info_outline, color: _C.or, size: 22),
                  const SizedBox(width: 8),
                  Text('2 conditions pour fonder une coopérative',
                      style: _serif(15, color: _C.orClair)),
                ],
              ),
              const SizedBox(height: 16),
              _condTile(
                icone: neuro ? Icons.check_circle : Icons.radio_button_unchecked,
                couleur: neuro ? _C.vert : Colors.white38,
                titre: 'Neurocitoyen certifié',
                sousTitre: neuro
                    ? '3 étapes validées'
                    : 'Valide les 3 étapes du parcours',
                action: () => context.go('/mon-cheminement'),
                actionLabel: neuro ? 'Revoir' : 'Commencer',
              ),
              const SizedBox(height: 12),
              _condTile(
                icone: eecOk ? Icons.check_circle : Icons.timelapse,
                couleur: eecOk ? _C.vert : _C.or,
                titre: 'École de l\'Entrepreneuriat Coopératif (EEC)',
                sousTitre: eecTotal > 0
                    ? '$eecValides / $eecTotal modules validés (note ≥ 85%)'
                    : '12 modules à valider',
                action: () => context.go('/universite'),
                actionLabel: eecOk ? 'Revoir' : 'Continuer',
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _C.nuit3,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.white12),
          ),
          child: const Text(
            'Ces 2 conditions garantissent que tu es prêt à fonder et gérer '
            'une coopérative viable, dans le respect des valeurs neurocitoyennes.',
            style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.5),
          ),
        ),
      ],
    );
  }

  Widget _condTile({
    required IconData icone,
    required Color couleur,
    required String titre,
    required String sousTitre,
    required VoidCallback action,
    required String actionLabel,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _C.nuit2,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: couleur.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Icon(icone, color: couleur, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(titre, style: _serif(13, color: _C.orClair)),
                const SizedBox(height: 2),
                Text(sousTitre,
                    style: const TextStyle(
                        color: Colors.white70, fontSize: 11)),
              ],
            ),
          ),
          TextButton(
            onPressed: action,
            child: Text(actionLabel,
                style: TextStyle(color: couleur, fontSize: 11, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // ÉTAT 3 : CERTIFIÉ, SANS COOP
  // ===========================================================================
  Widget _pasDeCoop() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _headerCertifie(),
        const SizedBox(height: 20),
        Text('Initier une coopérative',
            style: _serif(18, color: _C.orClair)),
        const SizedBox(height: 6),
        const Text(
          'Tu es certifié. Tu peux lancer un projet de coopérative de quartier '
          'et inviter 4 autres Neurocitoyens à te rejoindre. Tu as 30 jours.',
          style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.5),
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          style: FilledButton.styleFrom(
            backgroundColor: _C.or,
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
          onPressed: () async {
            await context.push('/coop/creer');
            _load();
          },
          icon: const Icon(Icons.add_circle_outline, color: Colors.black),
          label: const Text('Créer une coopérative',
              style: TextStyle(
                  color: Colors.black, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(height: 24),
        Text('Rejoindre un projet existant',
            style: _serif(18, color: _C.orClair)),
        const SizedBox(height: 6),
        if (_monQuartierId == null)
          _cardInfo(
            icon: Icons.location_off,
            titre: 'Quartier non défini',
            message:
                'Ton quartier n\'est pas encore renseigné. Complète ton profil.',
            bouton: OutlinedButton(
              onPressed: () => context.go('/profil'),
              child: const Text('Compléter mon profil',
                  style: TextStyle(color: _C.or)),
            ),
          )
        else if (_projetsOuverts.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _C.nuit3,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white12),
            ),
            child: const Column(
              children: [
                Icon(Icons.search_off, color: Colors.white38, size: 40),
                SizedBox(height: 10),
                Text('Aucun projet dans ton quartier pour l\'instant.',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                    textAlign: TextAlign.center),
                SizedBox(height: 6),
                Text('Sois le premier à en initier un !',
                    style: TextStyle(color: _C.or, fontSize: 11)),
              ],
            ),
          )
        else
          ..._projetsOuverts.map(_projetTile),
      ],
    );
  }

  Widget _projetTile(Map<String, dynamic> p) {
    final nom = p['nom'] as String? ?? 'Projet';
    final nb = p['nombre_membres'] as int? ?? 0;
    final statut = p['statut'] as String? ?? 'projet';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _C.nuit3,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _C.or.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.handshake, color: _C.or, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(nom, style: _serif(16, color: _C.orClair)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statut == 'comite' ? _C.vert : _C.or,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  statut.toUpperCase(),
                  style: const TextStyle(
                      color: Colors.black,
                      fontSize: 9,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text('$nb / 5 membres fondateurs',
              style: const TextStyle(color: Colors.white70, fontSize: 12)),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: (nb / 5).clamp(0.0, 1.0),
            backgroundColor: Colors.white12,
            valueColor: const AlwaysStoppedAnimation(_C.or),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton(
              style: FilledButton.styleFrom(
                  backgroundColor: _C.or,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8)),
              onPressed: () async {
                try {
                  await CoopService.rejoindreProjet(p['id'] as String);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          backgroundColor: _C.vert,
                          content: Text('Tu as rejoint ce projet !')),
                    );
                  }
                  _load();
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          backgroundColor: _C.rouge,
                          content: Text(e.toString())),
                    );
                  }
                }
              },
              child: const Text('Rejoindre',
                  style: TextStyle(
                      color: Colors.black, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // ÉTAT 4 : DANS UNE COOP — DASHBOARD
  // ===========================================================================
  Widget _dashboard() {
    final coop = _coopActive!;
    final nom = coop['nom'] as String? ?? 'Ma coopérative';
    final statut = coop['statut'] as String? ?? 'projet';
    final nb = coop['nombre_membres'] as int? ?? 0;
    final code = coop['code'] as String? ?? '';

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [_C.or, Color(0xFF8B6914)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.handshake, color: Colors.black54, size: 32),
              const SizedBox(height: 8),
              Text(nom,
                  style: _serif(22, color: Colors.black, weight: FontWeight.w900)),
              const SizedBox(height: 4),
              Text('Code : $code',
                  style: const TextStyle(
                      color: Colors.black87,
                      fontSize: 11,
                      fontFamily: 'monospace')),
              const SizedBox(height: 8),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      statut.toUpperCase(),
                      style: const TextStyle(
                          color: Colors.black,
                          fontSize: 10,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text('$nb / 5 membres',
                      style: const TextStyle(
                          color: Colors.black87, fontSize: 12)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (nb < 5)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _C.nuit3,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _C.or.withValues(alpha: 0.4)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.info_outline, color: _C.or, size: 20),
                    const SizedBox(width: 8),
                    Text('Recrute 4 autres Neurocitoyens certifiés',
                        style: _serif(14, color: _C.orClair)),
                  ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: (nb / 5).clamp(0.0, 1.0),
                  backgroundColor: Colors.white12,
                  valueColor: const AlwaysStoppedAnimation(_C.or),
                  minHeight: 8,
                ),
                const SizedBox(height: 6),
                Text('$nb / 5 — encore ${5 - nb} à recruter',
                    style: const TextStyle(
                        color: Colors.white70, fontSize: 11)),
              ],
            ),
          ),
        const SizedBox(height: 20),
        Text('Membres fondateurs', style: _serif(16, color: _C.orClair)),
        const SizedBox(height: 10),
        if (_membres.isEmpty)
          const Text('Chargement...',
              style: TextStyle(color: Colors.white38, fontSize: 12))
        else
          ..._membres.map(_membreTile),
        const SizedBox(height: 24),
        Text('Outils pré-commerce', style: _serif(16, color: _C.orClair)),
        const SizedBox(height: 6),
        const Text(
          'Avant le démarrage commercial, la coopérative peut déjà travailler : '
          'marketing, inscription des clients, annonces.',
          style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.5),
        ),
        const SizedBox(height: 12),
        _outilTile(
          icon: Icons.person_add,
          titre: 'Inviter un Neurocitoyen',
          sousTitre: 'Partage le code de la coopérative',
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  backgroundColor: _C.nuit2,
                  content: Text('Code à partager : $code',
                      style: const TextStyle(color: _C.or))),
            );
          },
        ),
        _outilTile(
          icon: Icons.store,
          titre: 'Inscrire un client sur AGORA',
          sousTitre: 'Commerçants, écoles, mairies...',
          onTap: () => context.go('/agora'),
        ),
        _outilTile(
          icon: Icons.campaign,
          titre: 'Annoncer une opportunité',
          sousTitre: 'Publier sur AGORA',
          onTap: () => context.go('/agora'),
        ),
        const SizedBox(height: 24),
        if (nb < 5)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _C.nuit3,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white12),
            ),
            child: const Row(
              children: [
                Icon(Icons.lock_outline, color: Colors.white38, size: 20),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Le démarrage commercial est verrouillé tant que les 5 membres ne sont pas réunis.',
                    style: TextStyle(color: Colors.white54, fontSize: 11, height: 1.4),
                  ),
                ),
              ],
            ),
          )
        else
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: _C.vert,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    backgroundColor: _C.vert,
                    content: Text('Démarrage commercial à venir (Sprint 2)')),
              );
            },
            icon: const Icon(Icons.rocket_launch, color: Colors.white),
            label: const Text('Démarrer l\'activité commerciale',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: () async {
            final conf = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                backgroundColor: _C.nuit2,
                title: const Text('Quitter la coopérative ?',
                    style: TextStyle(color: Colors.white)),
                content: const Text(
                    'Si tu quittes, tu ne pourras revenir qu\'en étant réinvité.',
                    style: TextStyle(color: Colors.white70)),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Annuler',
                          style: TextStyle(color: Colors.white70))),
                  FilledButton(
                      style: FilledButton.styleFrom(backgroundColor: _C.rouge),
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Quitter',
                          style: TextStyle(color: Colors.white))),
                ],
              ),
            );
            if (conf == true && _coopActive != null) {
              try {
                await CoopService.quitterProjet(_coopActive!['id'] as String);
                _load();
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        backgroundColor: _C.rouge, content: Text(e.toString())),
                  );
                }
              }
            }
          },
          child: const Text('Quitter la coopérative',
              style: TextStyle(color: Colors.white38, fontSize: 11)),
        ),
      ],
    );
  }

  Widget _membreTile(Map<String, dynamic> m) {
    final role = m['role'] as String? ?? 'membre';
    final user = m['users'] as Map<String, dynamic>?;
    final pseudo = user?['pseudo'] as String? ?? 'Membre';
    final prenoms = user?['prenoms'] as String? ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _C.nuit3,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _C.or.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(Icons.person, color: _C.or, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(pseudo, style: _serif(14, color: _C.orClair)),
                if (prenoms.isNotEmpty)
                  Text(prenoms,
                      style: const TextStyle(
                          color: Colors.white54, fontSize: 11)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: role.startsWith('fondateur') ? _C.or : Colors.white24,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              role == 'fondateur_initiateur'
                  ? 'INITIATEUR'
                  : role.toUpperCase(),
              style: const TextStyle(
                  color: Colors.black,
                  fontSize: 9,
                  fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _outilTile({
    required IconData icon,
    required String titre,
    required String sousTitre,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: _C.nuit3,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white12),
      ),
      child: ListTile(
        leading: Icon(icon, color: _C.or, size: 22),
        title: Text(titre,
            style: const TextStyle(color: Colors.white, fontSize: 13)),
        subtitle: Text(sousTitre,
            style: const TextStyle(color: Colors.white54, fontSize: 11)),
        trailing: const Icon(Icons.chevron_right, color: _C.or, size: 20),
        onTap: onTap,
      ),
    );
  }

  // ===========================================================================
  // WIDGETS COMMUNS
  // ===========================================================================
  Widget _headerCertifie() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_C.or, Color(0xFF8B6914)],
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(Icons.verified, color: Colors.black54, size: 32),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Tu es certifié Neurocitoyen',
                    style: _serif(15, color: Colors.black)),
                const SizedBox(height: 2),
                const Text('Étape 7 validée — tu peux fonder une coopérative',
                    style: TextStyle(color: Colors.black87, fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _cardInfo({
    required IconData icon,
    required String titre,
    required String message,
    required Widget bouton,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _C.nuit3,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        children: [
          Icon(icon, color: _C.or, size: 40),
          const SizedBox(height: 12),
          Text(titre, style: _serif(18, color: _C.orClair)),
          const SizedBox(height: 8),
          Text(message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: Colors.white70, fontSize: 12, height: 1.5)),
          const SizedBox(height: 16),
          bouton,
        ],
      ),
    );
  }
}
