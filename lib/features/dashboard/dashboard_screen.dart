import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../widgets/app_scaffold.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/ligue_data.dart';
import '../../core/auth_service.dart';
import '../../widgets/africa_map.dart';

// =============================================================================
// PALETTE
// =============================================================================
class _C {
  static const nuit = Color(0xFF0B2B2F);
  static const nuit2 = Color(0xFF0E3A3D);
  static const nuit3 = Color(0xFF071D20);
  static const or = Color(0xFFE0A82E);
  static const orClair = Color(0xFFF0BD4A);
  static const ivoire = Color(0xFFFBF8F1);
  static const vert = Color(0xFF1D7A52);
}

TextStyle _serif(double size,
    {Color color = Colors.white,
    FontWeight weight = FontWeight.w700,
    double? height}) {
  return TextStyle(
    fontFamily: 'Georgia',
    fontFamilyFallback: const ['Times New Roman', 'serif'],
    fontSize: size,
    color: color,
    fontWeight: weight,
    height: height,
  );
}

// =============================================================================
// DASHBOARD
// =============================================================================
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // Profil
  String codeParrain = 'BJ-XXXX-0000';
  String nom = 'Neurocitoyen';
  String grade = 'Aspirant';
  String citeAppartenance = 'Bénin - Porto-Novo 🇧🇯';
  String paysId = 'BJ';
  int modulesValides = 0;
  List<String> filleuls = [];
  bool etape1Validee = false;
  bool _isSuperAdmin = false;

  // Progression Supabase
  int etapeEnCours = 1;
  int etapesValidees = 0;

  @override
  void initState() {
    super.initState();
    _load();
    _loadProgress();
    _checkSuperAdmin();
  }

  Future<void> _checkSuperAdmin() async {
    try {
      final isAdmin = await AuthService.isSuperAdmin();
      if (mounted) setState(() => _isSuperAdmin = isAdmin);
    } catch (_) {}
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      codeParrain = prefs.getString('code_parrain') ?? 'BJ-XXXX-0000';
      final pseudo = prefs.getString('pseudo');
      final storedNom = prefs.getString('nom');
      nom = pseudo ?? storedNom ?? 'Neurocitoyen';
      paysId = prefs.getString('pays_id') ?? 'BJ';
      final cite = LigueData.getCite(paysId);
      citeAppartenance = '${cite.nom} - ${cite.capitale} ${cite.flag}';
      modulesValides = [1, 2, 3, 4, 5]
          .where((i) => prefs.getInt('module_${i}_valide') == 1)
          .length;
      grade = LigueData.grades[modulesValides.clamp(0, 6)].titre;
      filleuls = prefs.getStringList('filleuls') ?? [];
    });
  }

  Future<void> _loadProgress() async {
    try {
      final userId = (await SharedPreferences.getInstance()).getString('user_id');
      if (userId == null) return;
      final res = await Supabase.instance.client
          .from('user_progress')
          .select()
          .eq('user_id', userId);
      final list = List<Map<String, dynamic>>.from(res);
      final valides = list.where((e) => e['statut'] == 'certifie' || e['statut'] == 'termine').length;
      setState(() {
        etapesValidees = valides;
        etapeEnCours = valides + 1;
        etape1Validee = list.any((e) => e['etape_numero'] == 1 && (e['statut'] == 'certifie' || e['statut'] == 'termine'));
      });
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Tableau de bord',
      child: ListView(
        children: [
          _welcomeHeader(),
          _cheminementBanner(),
          _progressionBanner(),
          _navigationList(),
          _footer(),
        ],
      ),
    );
  }

  // ===========================================================================
  // HEADER PERSONNALISÉ
  // ===========================================================================
  Widget _welcomeHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      color: _C.nuit2,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: _C.or.withOpacity(0.15),
                      shape: BoxShape.circle,
                      border: Border.all(color: _C.or, width: 2),
                    ),
                    child: const Icon(Icons.person, color: _C.or, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Bienvenue, $nom',
                            style: _serif(22, color: Colors.white)),
                        const SizedBox(height: 4),
                        Text('$grade · $citeAppartenance',
                            style: const TextStyle(
                                color: Colors.white60, fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _C.nuit3,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _C.or.withOpacity(0.4)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: QrImageView(
                        data: codeParrain,
                        size: 80,
                        backgroundColor: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('MON CODE DE COOPTATION',
                              style: TextStyle(
                                  color: _C.or,
                                  fontSize: 10,
                                  letterSpacing: 2,
                                  fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text(codeParrain,
                              style: _serif(20, color: Colors.white)),
                          const SizedBox(height: 8),
                          Text('${filleuls.length} filleul(s) coopté(s)',
                              style: const TextStyle(
                                  color: Colors.white60, fontSize: 11)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // BANNIÈRE MON CHEMINEMENT (7 étapes)
  // ===========================================================================
  Widget _cheminementBanner() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1D7A52), Color(0xFF0F4A2F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Color(0xFF1D7A52).withOpacity(0.3), blurRadius: 15)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.route, color: Colors.white, size: 24),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'MON CHEMINEMENT NEUROCITOYEN',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            '7 étapes vers la transformation. De la conscience de soi à l\'autonomie économique.',
            style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.4),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => context.go('/mon-cheminement'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF1D7A52),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
              child: const Text(
                'VOIR MON CHEMINEMENT →',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // BANNIÈRE PROGRESSION — pousse vers l'Université
  // ===========================================================================
  Widget _progressionBanner() {
    final pct = (etapesValidees / 7 * 100).round();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      color: _C.nuit,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [_C.or.withOpacity(0.15), _C.or.withOpacity(0.05)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _C.or.withOpacity(0.6), width: 2),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: _C.or,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.school, color: Colors.black, size: 24),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            etape1Validee
                                ? 'Étape $etapeEnCours sur 7'
                                : 'Commence ton parcours',
                            style: _serif(20, color: Colors.white),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            etape1Validee
                                ? 'Université Baobab — progression $pct%'
                                : 'L\'Université Baobab t\'attend',
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: etapesValidees / 7,
                    minHeight: 8,
                    backgroundColor: Colors.white10,
                    valueColor: const AlwaysStoppedAnimation(_C.or),
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => context.go('/universite'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _C.or,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30)),
                    ),
                    child: Text(
                      etape1Validee
                          ? 'CONTINUER MON PARCOURS →'
                          : 'COMMENCER MON CHEMINEMENT →',
                      style: const TextStyle(
                          fontWeight: FontWeight.w900, fontSize: 14),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // NAVIGATION VERTICALE
  // ===========================================================================
  Widget _navigationList() {
    return Container(
      color: _C.nuit,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // PARCOURS
              _sectionTitle('🎯 Parcours Neurocitoyen'),
              _navCard(
                icon: Icons.school,
                title: 'Université Baobab',
                subtitle: '7 étapes · 2 écoles · Formations certifiantes',
                route: '/universite',
                highlight: true,
              ),
              _navCard(
                icon: Icons.card_membership,
                title: 'Mon Passeport',
                subtitle: '$etapesValidees / 7 étapes validées',
                route: '/universite',
              ),
              _navCard(
                icon: Icons.account_tree,
                title: 'Mon Arbre de Cooptation',
                subtitle: '${filleuls.length} filleul(s)',
                route: '/cooptation',
              ),
              _navCard(
                icon: Icons.workspace_premium,
                title: 'Mes Certificats',
                subtitle: 'Diplômes et attestations',
                route: '/certificats',
              ),

              const SizedBox(height: 20),

              // ÉCONOMIE
              _sectionTitle('💰 Économie personnelle'),
              _navCard(
                icon: Icons.account_balance_wallet,
                title: 'Mon Portefeuille',
                subtitle: '100 neuro-dollars de bienvenue',
                route: '/portefeuille',
              ),
              _navCard(
                icon: Icons.account_balance,
                title: 'Banque de la Ligue',
                subtitle: 'Prêts, garanties, soumission de projet',
                route: '/banque',
              ),
              _navCard(
                icon: Icons.shopping_cart,
                title: 'Centrale d\'achat',
                subtitle: 'Achats groupés et ristournes',
                route: '/centrale-achat',
              ),

              const SizedBox(height: 20),

              // COMMUNAUTÉ
              _sectionTitle('🤝 Coopération'),
              _navCard(
                icon: Icons.groups,
                title: 'Coopératives',
                subtitle: etape1Validee
                    ? 'Rejoindre ou créer une coopérative'
                    : '🔒 Valide l\'étape 1 pour débloquer',
                route: '/coop',
                locked: !etape1Validee,
              ),
              _navCard(
                icon: Icons.forum,
                title: 'Forum',
                subtitle: etape1Validee
                    ? 'Discussions et entraide'
                    : '🔒 Valide l\'étape 1 pour débloquer',
                route: '/forum',
                locked: !etape1Validee,
              ),
              _navCard(
                icon: Icons.location_city,
                title: 'Mon Agora',
                subtitle: 'Plateforme communale de $paysId',
                route: '/agora',
              ),
              _navCard(
                icon: Icons.map,
                title: 'Ma Cité — Carte des 54 Cités',
                subtitle: 'Découvre les autres Cités de la Ligue',
                route: '/carte',
              ),
              _navCard(
                icon: Icons.flag,
                title: 'Les 21 Pôles',
                subtitle: 'Domaines d\'action de la Ligue',
                route: '/poles',
              ),

              const SizedBox(height: 20),

              // INSTITUTIONNEL
              _sectionTitle('📖 Institutionnel'),
              _navCard(
                icon: Icons.menu_book,
                title: 'La Charte fondamentale',
                subtitle: '89 articles · 5 annexes · Version 2.0',
                route: '/charte',
              ),
              _navCard(
                icon: Icons.account_balance,
                title: 'Document institutionnel',
                subtitle: '6 niveaux · 21 pôles · 7 grades',
                route: '/institutions',
              ),
              _navCard(
                icon: Icons.diamond,
                title: 'Modèle économique',
                subtitle: '7 sources de revenus · 3 fonds',
                route: '/modele-eco',
              ),

              const SizedBox(height: 20),

              // PERSONNEL
              _sectionTitle('👤 Personnel'),
              _navCard(
                icon: Icons.person,
                title: 'Mon Profil',
                subtitle: 'Identité, QR, préférences',
                route: '/profil',
              ),
              _navCard(
                icon: Icons.library_books,
                title: 'Mes Modules',
                subtitle: 'Historique et progression',
                route: '/modules',
              ),
              if (_isSuperAdmin)
                _navCard(
                  icon: Icons.admin_panel_settings,
                  title: 'Administration',
                  subtitle: 'Panneau Super Admin de la Ligue',
                  route: '/admin-super',
                  highlight: true,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12, top: 4),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
            color: _C.or, fontSize: 11, letterSpacing: 3, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _navCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required String route,
    bool highlight = false,
    bool locked = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: () => context.go(route),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: highlight
                ? _C.or.withOpacity(0.12)
                : Colors.white.withOpacity(0.04),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: highlight
                  ? _C.or.withOpacity(0.6)
                  : Colors.white12,
              width: highlight ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _C.or.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  locked ? Icons.lock : icon,
                  color: locked ? Colors.white38 : _C.or,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: locked ? Colors.white54 : Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: const TextStyle(
                          color: Colors.white54, fontSize: 11),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: locked ? Colors.white24 : _C.or,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _footer() {
    return Container(
      width: double.infinity,
      color: _C.nuit2,
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: const Text(
        'Ligue Panafricaine des Neurocitoyens · Conscience · Intégrité · Autonomie',
        textAlign: TextAlign.center,
        style: TextStyle(color: Colors.white54, fontSize: 11),
      ),
    );
  }
}