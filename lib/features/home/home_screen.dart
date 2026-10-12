import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../widgets/app_scaffold.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});
  @override
  Widget build(BuildContext context){
    return AppScaffold(
      title: 'Ligue Panafricaine',
      child: SingleChildScrollView(
        child: Column(children:[
          // HERO
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [Color(0xFF080C1F), Color(0xFF101845)], begin: Alignment.topCenter, end: Alignment.bottomCenter),
            ),
            child: Column(children:[
              Image.asset('assets/images/logo.png', width: 180, height: 180, errorBuilder: (c,e,s)=> const Icon(Icons.public, size:120, color: Color(0xFFc4952b))),
              const SizedBox(height:24),
              const Text('LIGUE PANAFRICAINE', style: TextStyle(color: Color(0xFFc4952b), fontSize:13, letterSpacing:4, fontWeight: FontWeight.bold)),
              const SizedBox(height:12),
              const Text('DES NEUROCITOYENS', style: TextStyle(color: Colors.white, fontSize:28, fontWeight: FontWeight.w900, letterSpacing:1)),
              const SizedBox(height:12),
              Container(width:60, height:3, color: Color(0xFFc4952b)),
              const SizedBox(height:20),
              const Text('1 Membre = 1 Voix\n55 Cités • 1 Continent • Coopérative', textAlign: TextAlign.center, style: TextStyle(color: Colors.white70, fontSize:14, height:1.6)),
              const SizedBox(height:36),
              Wrap(spacing:12, runSpacing:12, alignment: WrapAlignment.center, children:[
                ElevatedButton(onPressed: ()=> context.go('/inscription'), style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFc4952b), foregroundColor: Colors.black, padding: const EdgeInsets.symmetric(horizontal:32, vertical:18), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))), child: const Text('REJOINDRE LA LIGUE', style: TextStyle(fontWeight: FontWeight.bold))),
                OutlinedButton(onPressed: ()=> context.go('/login'), style: OutlinedButton.styleFrom(foregroundColor: Colors.white, side: const BorderSide(color: Colors.white24), padding: const EdgeInsets.symmetric(horizontal:32, vertical:18), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))), child: const Text('SE CONNECTER')),
              ]),
              const SizedBox(height:16),
              const Text('Part sociale 5000F remboursable • Modèle V2.0 Coopératif • Art 36', style: TextStyle(color: Colors.white38, fontSize:10)),
            ]),
          ),
          // STATS
          Container(color: const Color(0xFF0D1230), padding: const EdgeInsets.all(24), child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: const[
            _Stat(v:'55', l:'Cités'),
            _Stat(v:'1M+', l:'Neurocitoyens'),
            _Stat(v:'17%', l:'Flux solidaire'),
            _Stat(v:'9', l:'Sources'),
          ])),
          // POURQUOI
          Padding(padding: const EdgeInsets.all(24), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children:[
            const Text('Pourquoi nous rejoindre ?', style: TextStyle(color: Colors.white, fontSize:18, fontWeight: FontWeight.bold)),
            const SizedBox(height:16),
            const _Why(icon: Icons.how_to_vote, title:'1 Membre = 1 Voix', desc:'Coopérative démocratique, pas de pyramide. Gouvernance partagée.'),
            const _Why(icon: Icons.shield, title:'Art 36 - Protection', desc:'Interdiction de rémunération au recrutement. Ton grade vient de ton impact réel.'),
            const _Why(icon: Icons.account_balance, title:'Économie circulaire', desc:'Ligue 8% + Solidarité 5% + Éducation 4%. Ristourne annuelle aux membres.'),
            const SizedBox(height:24),
            Center(child: ElevatedButton(onPressed: ()=> context.go('/modele-eco'), style: ElevatedButton.styleFrom(backgroundColor: Colors.white10), child: const Text('Voir le modèle économique V2.0', style: TextStyle(color: Colors.white)))),
          ])),
        ]),
      ),
    );
  }
}
class _Stat extends StatelessWidget { final String v,l; const _Stat({required this.v, required this.l}); @override Widget build(BuildContext c)=> Column(children:[Text(v, style: const TextStyle(color: Color(0xFFc4952b), fontSize:22, fontWeight: FontWeight.bold)), Text(l, style: const TextStyle(color: Colors.white54, fontSize:11))]); }
class _Why extends StatelessWidget { final IconData icon; final String title, desc; const _Why({required this.icon, required this.title, required this.desc}); @override Widget build(BuildContext c)=> Padding(padding: const EdgeInsets.only(bottom:16), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children:[Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: const Color(0xFFc4952b).withOpacity(0.15), borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: const Color(0xFFc4952b), size:20)), const SizedBox(width:12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children:[Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize:13)), const SizedBox(height:4), Text(desc, style: const TextStyle(color: Colors.white60, fontSize:11, height:1.4))]))])); }
