import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});
  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen> {
  bool _logged=false;
  @override
  void initState(){ super.initState(); _check(); }
  Future<void> _check() async {
    final p=await SharedPreferences.getInstance();
    setState(()=> _logged=p.getString('code_parrain')!=null);
  }

  @override
  Widget build(BuildContext context){
    return Scaffold(
      backgroundColor: const Color(0xFF080C1F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF080C1F),
        title: const Text('LIGUE', style: TextStyle(fontSize:14, fontWeight: FontWeight.w900, letterSpacing:2)),
        actions: [
          if(!_logged)
            Padding(
              padding: const EdgeInsets.only(right:12),
              child: FilledButton(
                style: FilledButton.styleFrom(backgroundColor: const Color(0xFFFFC400), foregroundColor: Colors.black),
                onPressed: ()=> context.go('/connexion'),
                child: const Text('Se connecter', style: TextStyle(fontWeight: FontWeight.bold, fontSize:12)),
              ),
            ),
          IconButton(icon: const Icon(Icons.smart_toy, color: Color(0xFFFFC400)), onPressed: ()=> context.go('/ia-guide')),
        ],
      ),
      body: Center(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const SizedBox(height:20),
            const Text('République des Neurocitoyens', style: TextStyle(color: Color(0xFFFFC400), fontSize:12, letterSpacing:3)),
            const SizedBox(height:10),
            const Text('Bâtir une nation\nà partir du cerveau', style: TextStyle(color: Colors.white, fontSize:32, fontWeight: FontWeight.w900, height:1.1)),
            const SizedBox(height:20),
            if(!_logged)
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: const Color(0xFFFFC400), foregroundColor: Colors.black, minimumSize: const Size(double.infinity, 52)),
                onPressed: ()=> context.go('/connexion'),
                child: const Text('Se connecter', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            const SizedBox(height:12),
            OutlinedButton(
              style: OutlinedButton.styleFrom(foregroundColor: Colors.white, side: const BorderSide(color: Colors.white24), minimumSize: const Size(double.infinity, 52)),
              onPressed: ()=> context.go('/inscription?pays=BJ'),
              child: const Text('Créer mon compte'),
            ),
            const SizedBox(height:30),
            _card(context, '🏛 Université', '3 écoles permanentes', '/universite'),
            _card(context, '🗺 Carte', 'Voir les cités', '/carte'),
            _card(context, '📜 Charte', '47 articles', '/charte'),
          ],
        ),
      ),
    );
  }
  Widget _card(BuildContext c, String t, String s, String r)=> Card(
    color: const Color(0xFF101845),
    margin: const EdgeInsets.only(bottom:12),
    child: ListTile(title: Text(t, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)), subtitle: Text(s, style: const TextStyle(color: Colors.white54, fontSize:12)), trailing: const Icon(Icons.arrow_forward_ios, size:14, color: Colors.white54), onTap: ()=> c.go(r)),
  );
}
