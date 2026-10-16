import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'features/home/landing_screen.dart';
import 'features/panafricain/carte_afrique_screen.dart';
import 'features/auth/inscription_v2_screen.dart';
import 'features/admin/admin_screen.dart';
import 'features/admin/login_admin_screen.dart';
import 'features/auth/login_user_screen.dart';
import 'features/admin/admin_super_screen.dart';
import 'features/modules/modules_screen.dart';
import 'features/ia/ia_enseignant_screen.dart';
import 'features/dashboard/dashboard_screen.dart';
import 'features/ia/ia_guide_global.dart';
import 'features/universite/universite_screen.dart';
import 'features/charte/charte_screen.dart';
import 'features/charte/modele_eco_screen.dart';
import 'features/charte/institutions_screen.dart';
import 'features/forum/forum_screen.dart';
import 'features/banque/banque_screen.dart';
import 'features/coop/coop_screen.dart';
import 'features/profil/profil_screen.dart';
import 'features/poles/poles_screen.dart';
import 'features/portefeuille/portefeuille_screen.dart';
import 'features/agora/agora_screen.dart';
import 'features/cooptation/cooptation_screen.dart';
import 'features/certificats/certificats_screen.dart';
import 'features/centrale_achat/centrale_achat_screen.dart';
import 'features/cheminement/mon_cheminement_screen.dart';

Future<bool> _isLoggedIn() async {
  var p=await SharedPreferences.getInstance();
  return p.getString('code_parrain')!=null;
}

final router = GoRouter(
  initialLocation: '/',
  redirect: (context, state) async {
    final loc = state.matchedLocation;

    // 1. Routes publiques (toujours accessibles)
    const publicRoutes = [
      '/', '/carte', '/inscription', '/charte', '/modele-eco',
      '/institutions', '/ia-guide', '/poles', '/admin-login',
      '/connexion', '/login', '/universite'
    ];
    if (publicRoutes.contains(loc)) return null;

    // 2. Routes admin : Supabase Auth requis
    if (loc.startsWith('/admin')) {
      final supaUserAdmin = Supabase.instance.client.auth.currentUser;
      if (supaUserAdmin == null) {
        return '/admin-login';
      }
      return null;
    }

    // 3. Si Supabase Auth connecte, on laisse passer
    final supaUser = Supabase.instance.client.auth.currentUser;
    if (supaUser != null) return null;

    // 4. Sinon verifier inscription normale (code_parrain)
    final logged = await _isLoggedIn();
    if (!logged) {
      return '/inscription?pays=BJ&redirect=' + Uri.encodeComponent(loc);
    }
    return null;
  },
  routes: [
    GoRoute(path: '/', builder: (c,s)=> const LandingScreen()),
    GoRoute(path: '/carte', builder: (c,s)=> const CarteAfriqueScreen()),
    GoRoute(path: '/inscription', builder: (c,s){ final p = s.uri.queryParameters['pays'] ?? 'BJ'; return InscriptionScreen(paysId: p); }),
    GoRoute(path: '/admin', builder: (c,s)=> const AdminScreen()),
    GoRoute(path: '/admin-login', builder: (c,s)=> const LoginAdminScreen()),
 GoRoute(path: '/connexion', builder: (c,s)=> const LoginUserScreen()),
 GoRoute(path: '/login', builder: (c,s)=> const LoginUserScreen()),
 GoRoute(path: '/connexion-citoyen', builder: (c,s){ final red = s.uri.queryParameters['redirect']; return InscriptionScreen(paysId: 'BJ'); }),
    GoRoute(path: '/admin-super', builder: (c,s)=> const AdminSuperScreen()),
    GoRoute(path: '/modules', builder: (c,s)=> const ModulesScreen()),
    GoRoute(path: '/module/:id', builder: (c,s){ final id = int.tryParse(s.pathParameters['id']??'1')??1; return IAEnseignantScreen(moduleId: id); }),
    GoRoute(path: '/dashboard', builder: (c,s)=> const DashboardScreen()),
    GoRoute(path: '/mon-cheminement', builder: (c,s)=> const MonCheminementScreen()),
    GoRoute(path: '/ia-guide', builder: (c,s)=> const IAGuideGlobal()),
    GoRoute(path: '/universite', builder: (c,s)=> const UniversiteScreen()),
    GoRoute(path: '/charte', builder: (c,s)=> const CharteScreen()),
    GoRoute(path: '/modele-eco', builder: (c,s)=> const ModeleEcoScreen()),
    GoRoute(path: '/institutions', builder: (c,s)=> const InstitutionsScreen()),
    GoRoute(path: '/forum', builder: (c,s)=> const ForumScreen()),
    GoRoute(path: '/banque', builder: (c,s)=> const BanqueScreen()),
    GoRoute(path: '/coop', builder: (c,s)=> const CoopScreen()),
    GoRoute(path: '/profil', builder: (c,s)=> const ProfilScreen()),
    GoRoute(path: '/poles', builder: (c,s)=> const PolesScreen()),
    GoRoute(path: '/portefeuille', builder: (c,s) => const PortefeuilleScreen()),
GoRoute(path: '/agora', builder: (c,s) => const AgoraScreen()),
GoRoute(path: '/cooptation', builder: (c,s) => const CooptationScreen()),
GoRoute(path: '/certificats', builder: (c,s) => const CertificatsScreen()),
GoRoute(path: '/centrale-achat', builder: (c,s) => const CentraleAchatScreen()),
  ]
);

class App extends StatelessWidget { const App({super.key}); @override Widget build(BuildContext context)=> MaterialApp.router(routerConfig: router, theme: ThemeData(scaffoldBackgroundColor: const Color(0xFF080C1F), useMaterial3: true), debugShowCheckedModeBanner: false); }
