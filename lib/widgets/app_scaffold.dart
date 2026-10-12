import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/l10n.dart';

class AppScaffold extends StatelessWidget {
  final Widget child;
  final String title;
  const AppScaffold({super.key, required this.child, required this.title});

  @override
  Widget build(BuildContext context){
    return Scaffold(
      backgroundColor: const Color(0xFF080C1F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF080C1F),
        title: Text(title, style: const TextStyle(fontSize:13)),
        actions: [
          IconButton(icon: const Icon(Icons.smart_toy, color: Color(0xFFFFC400)), tooltip: 'IA Guide', onPressed: ()=>context.go('/ia-guide')),
          IconButton(icon: const Icon(Icons.person), onPressed: ()=>context.go('/profil')),
        ],
      ),
      drawer: Drawer(
        backgroundColor: const Color(0xFF101845),
        child: ListView(children:[
          DrawerHeader(decoration: const BoxDecoration(color: Color(0xFF080C1F)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children:[const Text('🧠', style: TextStyle(fontSize:30)), const SizedBox(height:8), Text(L10n.t('ligue'), style: const TextStyle(color: Colors.white, fontSize:11, fontWeight: FontWeight.bold)) ])),
          _item(context, Icons.home, 'Accueil', '/'),
          _item(context, Icons.map, L10n.t('carte'), '/carte'),
          _item(context, Icons.dashboard, L10n.t('dashboard'), '/dashboard'),
          _item(context, Icons.school, L10n.t('modules'), '/modules'),
          _item(context, Icons.cast_for_education, L10n.t('universite'), '/universite'),
          _item(context, Icons.forum, L10n.t('forum'), '/forum'),
          _item(context, Icons.account_balance, L10n.t('banque'), '/banque'),
          _item(context, Icons.handshake, L10n.t('coop'), '/coop'),
          _item(context, Icons.person, L10n.t('profil'), '/profil'),
          _item(context, Icons.description, L10n.t('charte'), '/charte'),
          _item(context, Icons.attach_money, L10n.t('modele'), '/modele-eco'),
          _item(context, Icons.admin_panel_settings, L10n.t('admin'), '/admin'),
          const Divider(color: Colors.white10),
          ListTile(leading: const Icon(Icons.smart_toy, color: Color(0xFFFFC400)), title: const Text('IA Guide - Charte & Modele', style: TextStyle(color: Color(0xFFFFC400), fontSize:12)), onTap: ()=>context.go('/ia-guide')),
        ]),
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFF101845),
        selectedItemColor: const Color(0xFFFFC400),
        unselectedItemColor: Colors.white54,
        type: BottomNavigationBarType.fixed,
        onTap: (i){
          var routes=['/','/carte','/dashboard','/modules','/profil'];
          context.go(routes[i]);
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Accueil'),
          BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Cites'),
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Board'),
          BottomNavigationBarItem(icon: Icon(Icons.school), label: 'Modules'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
        ],
      ),
      body: Stack(children:[
        child,
        Positioned(bottom: 80, right: 16, child: FloatingActionButton.small(onPressed: ()=>context.go('/ia-guide'), backgroundColor: const Color(0xFFFFC400), child: const Icon(Icons.smart_toy, color: Colors.black))),
      ]),
    );
  }
  Widget _item(BuildContext c, IconData ic, String label, String route)=> ListTile(leading: Icon(ic, color: Colors.white70, size:18), title: Text(label, style: const TextStyle(color: Colors.white70, fontSize:12)), onTap: ()=>c.go(route));
}
