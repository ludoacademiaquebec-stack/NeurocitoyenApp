import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/ligue_data.dart';
import '../../core/l10n.dart';
class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});
  @override
  State<LandingScreen> createState()=> _LandingScreenState();
}
class _LandingScreenState extends State<LandingScreen> {
  @override
  void initState(){
    super.initState();
    Future.delayed(const Duration(seconds:1), (){
      if(mounted){
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          backgroundColor: const Color(0xFF101845),
          content: const Text('IA Guide : Bienvenue ! Je suis ton guide depuis ton acces. Clique sur le robot pour comprendre Charte & Modele Eco', style: TextStyle(color: Color(0xFFFFC400), fontSize:11)),
          action: SnackBarAction(label: 'Ouvrir IA', textColor: const Color(0xFFFFC400), onPressed: ()=>context.go('/ia-guide')),
          duration: const Duration(seconds:5),
        ));
      }
    });
  }
  @override
  Widget build(BuildContext context){
    return Scaffold(
      backgroundColor: const Color(0xFF080C1F),
      appBar: AppBar(backgroundColor: const Color(0xFF080C1F), title: Row(children:[Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(10)), child: const Text('🧠', style: TextStyle(fontSize:20))), const SizedBox(width:10), Text(L10n.t('ligue'), style: const TextStyle(fontSize:10, fontWeight: FontWeight.bold, color: Colors.white70))]), actions:[
        DropdownButton<String>(value: L10n.lang, dropdownColor: const Color(0xFF101845), underline: const SizedBox(), style: const TextStyle(color: Colors.white, fontSize:12), items: const [DropdownMenuItem(value:'fr', child: Text('FR')), DropdownMenuItem(value:'en', child: Text('EN'))], onChanged: (v){ setState(()=> L10n.setLang(v!)); }),
        IconButton(icon: const Icon(Icons.smart_toy, color: Color(0xFFFFC400)), onPressed: ()=>context.go('/ia-guide')),
        const SizedBox(width:8),
      ]),
      drawer: Drawer(backgroundColor: const Color(0xFF101845), child: ListView(children:[
        const DrawerHeader(decoration: BoxDecoration(color: Color(0xFF080C1F)), child: Text('Ligue Panafricaine', style: TextStyle(color: Colors.white))),
        ListTile(leading: const Icon(Icons.home, color: Colors.white70), title: const Text('Accueil', style: TextStyle(color: Colors.white70)), onTap: ()=>context.go('/')),
        ListTile(leading: const Icon(Icons.dashboard, color: Colors.white70), title: const Text('Dashboard', style: TextStyle(color: Colors.white70)), onTap: ()=>context.go('/dashboard')),
        ListTile(leading: const Icon(Icons.school, color: Colors.white70), title: const Text('Modules', style: TextStyle(color: Colors.white70)), onTap: ()=>context.go('/modules')),
        ListTile(leading: const Icon(Icons.cast_for_education, color: Colors.white70), title: const Text('Universite', style: TextStyle(color: Colors.white70)), onTap: ()=>context.go('/universite')),
      ])),
      bottomNavigationBar: BottomNavigationBar(backgroundColor: const Color(0xFF101845), selectedItemColor: const Color(0xFFFFC400), unselectedItemColor: Colors.white54, type: BottomNavigationBarType.fixed, onTap: (i){ var routes=['/','/carte','/dashboard','/modules','/profil']; context.go(routes[i]); }, items: const [BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Accueil'), BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Cites'), BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Board'), BottomNavigationBarItem(icon: Icon(Icons.school), label: 'Modules'), BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil')]),
      body: SingleChildScrollView(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children:[
        Container(width: double.infinity, padding: const EdgeInsets.fromLTRB(24,40,24,40), decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFF101845), Color(0xFF080C1F)], begin: Alignment.topCenter, end: Alignment.bottomCenter)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children:[
          Container(padding: const EdgeInsets.symmetric(horizontal:12, vertical:6), decoration: BoxDecoration(color: const Color(0xFFFFC400).withOpacity(0.15), borderRadius: BorderRadius.circular(20)), child: const Text('55 CITES • 5 REGIONS • 6 NIVEAUX • 21 POLES • 7 GRADES + INTERETS ELARGIS', style: TextStyle(color: Color(0xFFFFC400), fontSize:9, fontWeight: FontWeight.bold))),
          const SizedBox(height:20),
          Text(L10n.t('hero'), style: const TextStyle(color: Colors.white, fontSize:40, fontWeight: FontWeight.w900, height:1.1)),
          const SizedBox(height:12),
          const Text('Federation Cites autonomes, coherence Ligue. Charte Kouroukan Fouga + Modele Eco service rendu. IA guide des ton acces.', style: TextStyle(color: Colors.white70, fontSize:13)),
          const SizedBox(height:20),
          Wrap(spacing:10, children:[
            ElevatedButton(onPressed: ()=>context.go('/carte'), style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFFC400), foregroundColor: Colors.black, padding: const EdgeInsets.symmetric(horizontal:24, vertical:16)), child: Text(L10n.t('rejoindre'))),
            OutlinedButton(onPressed: ()=>context.go('/ia-guide'), style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFFFFC400), side: const BorderSide(color: Color(0xFFFFC400))), child: const Text('IA GUIDE CHARTE & MODELE')),
            OutlinedButton(onPressed: ()=>context.go('/universite'), style: OutlinedButton.styleFrom(foregroundColor: Colors.white, side: const BorderSide(color: Colors.white24)), child: const Text('UNIVERSITE')),
          ]),
        ])),
        Padding(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children:[
          const Text('6 Niveaux + Dashboards', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          const SizedBox(height:10),
          Wrap(spacing:8, runSpacing:8, children:[
            _dashCard(context, '1 Ligue', 'Mansa', '/dashboard'),
            _dashCard(context, '2 Region', 'Ola', '/dashboard'),
            _dashCard(context, '3 Cite', 'Mwalimu', '/dashboard'),
            _dashCard(context, '6 Agora', 'Agoranome', '/dashboard'),
          ]),
        ])),
      ])),
      floatingActionButton: FloatingActionButton.extended(onPressed: ()=>context.go('/ia-guide'), backgroundColor: const Color(0xFFFFC400), icon: const Icon(Icons.smart_toy, color: Colors.black), label: const Text('IA Guide', style: TextStyle(color: Colors.black, fontSize:11))),
    );
  }
  Widget _dashCard(BuildContext c, String niv, String titre, String route)=> InkWell(onTap: ()=>c.go(route), child: Container(width:140, padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: const Color(0xFF101845), borderRadius: BorderRadius.circular(12)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children:[Text(niv, style: const TextStyle(color: Color(0xFFFFC400), fontSize:10, fontWeight: FontWeight.bold)), Text(titre, style: const TextStyle(color: Colors.white, fontSize:12, fontWeight: FontWeight.bold)) ])));
}
