import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/auth_service.dart';
import 'admin_charte_tab.dart';
import 'admin_institutions_tab.dart';
import 'admin_eco_tab.dart';
import 'admin_prix_tab.dart';
import 'admin_users_tab.dart';
import 'admin_journal_tab.dart';
import 'admin_universite_tab.dart';

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
    {Color color = Colors.white, FontWeight weight = FontWeight.w700}) {
  return TextStyle(
    fontFamily: 'Georgia',
    fontFamilyFallback: const ['Times New Roman', 'serif'],
    fontSize: size,
    color: color,
    fontWeight: weight,
  );
}

class AdminSuperScreen extends StatefulWidget {
  const AdminSuperScreen({super.key});
  @override
  State<AdminSuperScreen> createState() => _AdminSuperScreenState();
}

class _AdminSuperScreenState extends State<AdminSuperScreen>
    with TickerProviderStateMixin {
  late final TabController _tabCtrl;
  bool _loading = true;
  Map<String, dynamic>? _profile;
  Map<String, dynamic>? _stats;

  @override
  void initState() {
    super.initState();
    // 8 onglets
    _tabCtrl = TabController(length: 9, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final isAdmin = await AuthService.isSuperAdmin();
    if (!isAdmin) {
      if (mounted) context.go('/admin-login');
      return;
    }

    final profile = await AuthService.getAdminProfile();
    Map<String, dynamic>? stats;
    try {
      final res = await Supabase.instance.client
          .from('admin_stats')
          .select()
          .maybeSingle();
      stats = res;
    } catch (_) {}

    if (mounted) {
      setState(() {
        _profile = profile;
        _stats = stats;
        _loading = false;
      });
    }
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _C.nuit2,
        title: const Text('Déconnexion',
            style: TextStyle(color: Colors.white)),
        content: const Text('Veux-tu vraiment te déconnecter ?',
            style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler',
                style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: _C.rouge,
              foregroundColor: Colors.white,
            ),
            child: const Text('Se déconnecter'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await AuthService.logout();
      if (mounted) context.go('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: _C.nuit,
        body: Center(child: CircularProgressIndicator(color: _C.or)),
      );
    }

    return Scaffold(
      backgroundColor: _C.nuit,
      appBar: AppBar(
        backgroundColor: _C.nuit2,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: _C.or.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.admin_panel_settings,
                  color: _C.or, size: 20),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('ADMINISTRATION',
                    style: TextStyle(
                        fontSize: 11,
                        letterSpacing: 2,
                        color: _C.or,
                        fontWeight: FontWeight.bold)),
                Text(
                  _profile?['email'] ?? 'SuperAdmin',
                  style: const TextStyle(
                      fontSize: 10, color: Colors.white54),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.home, color: Colors.white70),
            onPressed: () => context.go('/'),
            tooltip: 'Accueil',
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: _C.rouge),
            onPressed: _logout,
            tooltip: 'Déconnexion',
          ),
          const SizedBox(width: 8),
        ],
        bottom: TabBar(
          controller: _tabCtrl,
          isScrollable: true,
          indicatorColor: _C.or,
          labelColor: _C.or,
          unselectedLabelColor: Colors.white54,
          labelStyle: const TextStyle(
              fontSize: 11, fontWeight: FontWeight.bold),
          tabs: const [
            Tab(icon: Icon(Icons.dashboard, size: 18), text: 'Dashboard'),
            Tab(icon: Icon(Icons.menu_book, size: 18), text: 'Charte'),
            Tab(icon: Icon(Icons.account_balance, size: 18), text: 'Institutionnel'),
            Tab(icon: Icon(Icons.diamond, size: 18), text: 'Économie'),
            Tab(icon: Icon(Icons.school, size: 18), text: 'Université'),
            Tab(icon: Icon(Icons.handshake, size: 18), text: 'Coopératives'),
            Tab(icon: Icon(Icons.tune, size: 18), text: 'Prix & Config'),
            Tab(icon: Icon(Icons.people, size: 18), text: 'Utilisateurs'),
            Tab(icon: Icon(Icons.history, size: 18), text: 'Journal'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          _tabDashboard(),
          const AdminCharteTab(),
          const AdminInstitutionsTab(),
          const AdminEcoTab(),
          const AdminUniversiteTab(),
          const AdminCooperativesTab(),
          const AdminPrixTab(),
          const AdminUsersTab(),
          const AdminJournalTab(),
        ],
      ),
    );
  }

  // ===========================================================================
  // TAB DASHBOARD
  // ===========================================================================
  Widget _tabDashboard() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _bannerAdmin(),
        const SizedBox(height: 20),
        _statsGrid(),
        const SizedBox(height: 20),
        _quickActions(),
        const SizedBox(height: 20),
        _systemInfo(),
      ],
    );
  }

  Widget _bannerAdmin() {
    return Container(
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
          const Text(
            'SUPER ADMIN',
            style: TextStyle(
              color: Colors.black54,
              fontSize: 11,
              letterSpacing: 2,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text('Bonjour, ${_profile?['nom_complet'] ?? 'Admin'}',
              style: _serif(24, color: Colors.black, weight: FontWeight.w900)),
          const SizedBox(height: 4),
          const Text(
            'Bienvenue sur le panneau de contrôle de la Ligue Panafricaine des Neurocitoyens.',
            style: TextStyle(
                color: Colors.black87, fontSize: 12, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _statsGrid() {
    final s = _stats ?? {};
    final cards = [
      _statCard('Utilisateurs', '${s['total_users'] ?? 0}', Icons.people,
          _C.or),
      _statCard('Articles Charte', '${s['total_articles_charte'] ?? 0}',
          Icons.menu_book, _C.violet),
      _statCard('Sections Inst.', '${s['total_sections_inst'] ?? 0}',
          Icons.account_balance, _C.teal),
      _statCard('Pôles', '${s['total_poles'] ?? 0}', Icons.grid_view,
          _C.vert),
      _statCard('Formations', '${s['total_formations'] ?? 0}',
          Icons.school, _C.orClair),
      _statCard('Éditions (7j)', '${s['edits_semaine'] ?? 0}',
          Icons.edit_note, _C.rouge),
    ];

    return LayoutBuilder(builder: (ctx, cons) {
      final large = cons.maxWidth >= 700;
      final crossAxisCount = large ? 3 : 2;
      return GridView.count(
        crossAxisCount: crossAxisCount,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.6,
        children: cards,
      );
    });
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _C.nuit2,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value,
                  style: _serif(24, color: Colors.white,
                      weight: FontWeight.w900)),
              Text(label,
                  style: const TextStyle(
                      color: Colors.white54, fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _quickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('ACTIONS RAPIDES',
            style: TextStyle(
                color: _C.or,
                fontSize: 11,
                letterSpacing: 2,
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _quickAction(Icons.tune, 'Modifier les prix',
                () => _tabCtrl.animateTo(5)),
            _quickAction(Icons.menu_book, 'Éditer la Charte',
                () => _tabCtrl.animateTo(1)),
            _quickAction(Icons.people, 'Voir les utilisateurs',
                () => _tabCtrl.animateTo(6)),
            _quickAction(Icons.history, 'Journal d\'édition',
                () => _tabCtrl.animateTo(7)),
          ],
        ),
      ],
    );
  }

  Widget _quickAction(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: _C.nuit3,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _C.or.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: _C.or, size: 16),
            const SizedBox(width: 8),
            Text(label,
                style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _systemInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _C.nuit2,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline, color: _C.or, size: 16),
              const SizedBox(width: 8),
              Text('Informations',
                  style: _serif(14, color: Colors.white)),
            ],
          ),
          const SizedBox(height: 12),
          _infoLine('Version', '9.2.0'),
          _infoLine('Modèle coopératif', 'V2.0'),
          _infoLine('Email', _profile?['email'] ?? '—'),
          _infoLine('Rôle', _profile?['role'] ?? '—'),
          _infoLine('Base', 'Supabase · wgqwpuccrlpzczmqkpey'),
        ],
      ),
    );
  }

  Widget _infoLine(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(
            width: 140,
            child: Text('$label :',
                style: const TextStyle(
                    color: Colors.white54, fontSize: 11)),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // TAB PLACEHOLDER (sera remplacé dans les Vagues 2-4)
  // ===========================================================================
  Widget _tabPlaceholder(
      String titre, IconData icon, Color color, String description) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                shape: BoxShape.circle,
                border: Border.all(color: color, width: 2),
              ),
              child: Icon(icon, color: color, size: 40),
            ),
            const SizedBox(height: 24),
            Text(titre, style: _serif(24, color: Colors.white)),
            const SizedBox(height: 12),
            Text(
              description,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: Colors.white54, fontSize: 13, height: 1.5),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: _C.nuit2,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: color.withOpacity(0.4)),
              ),
              child: Text(
                'Disponible en Vague 2-4',
                style: TextStyle(
                    color: color,
                    fontSize: 11,
                    fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
