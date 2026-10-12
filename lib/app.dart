import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'features/home/landing_screen.dart';
import 'features/panafricain/carte_afrique_screen.dart';
import 'features/auth/inscription_v2_screen.dart';
import 'features/admin/admin_screen.dart';
import 'features/modules/modules_screen.dart';
import 'features/ia/ia_enseignant_screen.dart';
import 'features/dashboard/dashboard_screen.dart';
import 'features/ia/ia_guide_global.dart';
import 'features/universite/universite_screen.dart';
import 'features/charte/charte_screen.dart';
import 'features/charte/modele_eco_screen.dart';
import 'features/forum/forum_screen.dart';
import 'features/banque/banque_screen.dart';
import 'features/coop/coop_screen.dart';
import 'features/profil/profil_screen.dart';

Future<bool> _isLoggedIn() async {
  var p=await SharedPreferences.getInstance();
  return p.getString('code_parrain')!=null;
}

final router = GoRouter(
  initialLocation: '/',
  redirect: (context, state) async {
    var publicRoutes=['/','/carte','/inscription','/charte','/modele-eco','/ia-guide'];
    var isPublic=publicRoutes.any((r)=> state.matchedLocation.startsWith(r));
    if(isPublic) return null;
    var logged=await _isLoggedIn();
    if(!logged){
      return '/inscription?pays=BJ&redirect=' + Uri.encodeComponent(state.matchedLocation);
    }
    return null;
  },
  routes: [
    GoRoute(path: '/', builder: (c,s)=> const LandingScreen()),
    GoRoute(path: '/carte', builder: (c,s)=> const CarteAfriqueScreen()),
    GoRoute(path: '/inscription', builder: (c,s){ final p = s.uri.queryParameters['pays'] ?? 'BJ'; return InscriptionScreen(paysId: p); }),
    GoRoute(path: '/admin', builder: (c,s)=> const AdminScreen()),
    GoRoute(path: '/modules', builder: (c,s)=> const ModulesScreen()),
    GoRoute(path: '/module/:id', builder: (c,s){ final id = int.tryParse(s.pathParameters['id']??'1')??1; return IAEnseignantScreen(moduleId: id); }),
    GoRoute(path: '/dashboard', builder: (c,s)=> const DashboardScreen()),
    GoRoute(path: '/ia-guide', builder: (c,s)=> const IAGuideGlobal()),
    GoRoute(path: '/universite', builder: (c,s)=> const UniversiteScreen()),
    GoRoute(path: '/charte', builder: (c,s)=> const CharteScreen()),
    GoRoute(path: '/modele-eco', builder: (c,s)=> const ModeleEcoScreen()),
    GoRoute(path: '/forum', builder: (c,s)=> const ForumScreen()),
    GoRoute(path: '/banque', builder: (c,s)=> const BanqueScreen()),
    GoRoute(path: '/coop', builder: (c,s)=> const CoopScreen()),
    GoRoute(path: '/profil', builder: (c,s)=> const ProfilScreen()),
  ]
);

class App extends StatelessWidget { const App({super.key}); @override Widget build(BuildContext context)=> MaterialApp.router(routerConfig: router, theme: ThemeData(scaffoldBackgroundColor: const Color(0xFF080C1F), useMaterial3: true), debugShowCheckedModeBanner: false); }
