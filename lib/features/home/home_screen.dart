import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../widgets/app_scaffold.dart';
class HomeScreen extends StatelessWidget{
  const HomeScreen({super.key});
  @override Widget build(BuildContext context){
    return AppScaffold(title:'LIGUE • NEUROCITOYENS', child: ListView(children:[
      Container(width: double.infinity, padding: const EdgeInsets.fromLTRB(20,50,20,50), decoration: const BoxDecoration(gradient: LinearGradient(colors:[Color(0xFF0B2B2F), Color(0xFF0E3A3D)])), child: Column(children:[
        Container(width:160,height:160,decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Color(0xFFE0A82E), width:3), color: Color(0xFF0A102E)), child: const Icon(Icons.public, size:90, color: Color(0xFFE0A82E))),
        const SizedBox(height:20),
        const Text('LIGUE PANAFRICAINE', style: TextStyle(color: Color(0xFFE0A82E), letterSpacing:4, fontSize:12, fontWeight: FontWeight.bold)),
        const Text('DES NEUROCITOYENS', style: TextStyle(color: Colors.white, fontSize:32, fontWeight: FontWeight.w900)),
        const SizedBox(height:12),
        const Text('55 Cités • 9 Pôles • 1 Membre = 1 Voix', textAlign: TextAlign.center, style: TextStyle(color: Colors.white70)),
        const SizedBox(height:28),
        ElevatedButton(onPressed: ()=> context.go('/inscription'), style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE0A82E), foregroundColor: Colors.black, padding: const EdgeInsets.symmetric(horizontal:40, vertical:20), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))), child: const Text('REJOINDRE LA LIGUE →', style: TextStyle(fontWeight: FontWeight.w900))),
        const SizedBox(height:12),
        OutlinedButton(onPressed: ()=> context.go('/login'), style: OutlinedButton.styleFrom(foregroundColor: Colors.white, side: const BorderSide(color: Colors.white24), padding: const EdgeInsets.symmetric(horizontal:32, vertical:20), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))), child: const Text('SE CONNECTER')),
        const SizedBox(height:12),
        OutlinedButton(onPressed: ()=> context.go('/poles'), child: const Text('VOIR LES 9 PÔLES', style: TextStyle(color: Colors.white60))),
      ])),
      Container(color: const Color(0xFF071D20), padding: const EdgeInsets.all(20), child: const Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children:[Text('55 CITÉS', style: TextStyle(color: Color(0xFFE0A82E))), Text('9 PÔLES', style: TextStyle(color: Color(0xFFE0A82E))), Text('COOP V2.0', style: TextStyle(color: Color(0xFFE0A82E)))])),
    ]));
  }
}
