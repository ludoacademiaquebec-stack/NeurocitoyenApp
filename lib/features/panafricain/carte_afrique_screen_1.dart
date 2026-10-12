import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/ligue_data.dart';
import '../../widgets/app_scaffold.dart';
class CarteAfriqueScreen extends StatefulWidget {
  const CarteAfriqueScreen({super.key});
  @override
  State<CarteAfriqueScreen> createState()=> _CarteAfriqueScreenState();
}
class _CarteAfriqueScreenState extends State<CarteAfriqueScreen> {
  RegionUA? filtre;
  String search='';
  @override
  Widget build(BuildContext context){
    var cites=LigueData.cites.where((c){ bool fr=filtre==null||c.region==filtre; bool fs=search.isEmpty||c.nom.toLowerCase().contains(search.toLowerCase()); return fr&&fs; }).toList();
    return AppScaffold(
      title: 'Carte 55 Cites',
      child: Column(children:[
        Padding(padding: const EdgeInsets.all(12), child: Column(children:[
          TextField(style: const TextStyle(color: Colors.white), decoration: InputDecoration(hintText: 'Rechercher...', hintStyle: const TextStyle(color: Colors.white38), prefixIcon: const Icon(Icons.search, color: Colors.white38), filled:true, fillColor: Colors.white.withOpacity(0.06), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)), onChanged: (v)=>setState(()=>search=v)),
          const SizedBox(height:8),
          SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children:[ _chip(null,'Tous (55)'), _chip(RegionUA.ouest,'Ouest'), _chip(RegionUA.nord,'Nord'), _chip(RegionUA.centre,'Centre'), _chip(RegionUA.est,'Est'), _chip(RegionUA.australe,'Australe')])),
        ])),
        Expanded(child: GridView.builder(padding: const EdgeInsets.fromLTRB(12,0,12,12), gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount:2, childAspectRatio:1.7, crossAxisSpacing:8, mainAxisSpacing:8), itemCount: cites.length, itemBuilder: (c,i){
          var cite=cites[i]; bool isBenin=cite.id=='BJ';
          return InkWell(onTap: ()=>context.go('/inscription?pays='+cite.id), child: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: isBenin? const Color(0xFFFFC400).withOpacity(0.15): Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(12), border: Border.all(color: isBenin? const Color(0xFFFFC400): Colors.white10)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children:[Row(children:[Text(cite.flag, style: const TextStyle(fontSize:20)), const Spacer(), if(isBenin) Container(padding: const EdgeInsets.symmetric(horizontal:5, vertical:2), decoration: BoxDecoration(color: const Color(0xFFFFC400), borderRadius: BorderRadius.circular(5)), child: const Text('PILOTE', style: TextStyle(fontSize:7, fontWeight: FontWeight.bold)))]), const Spacer(), Text(cite.nom, style: TextStyle(color: isBenin? const Color(0xFFFFC400): Colors.white, fontSize:11, fontWeight: FontWeight.bold), maxLines:1, overflow: TextOverflow.ellipsis), Text(cite.capitale, style: const TextStyle(color: Colors.white38, fontSize:9))])));
        })),
      ]),
    );
  }
  Widget _chip(RegionUA? r, String label){ bool sel=filtre==r; return Padding(padding: const EdgeInsets.only(right:6), child: ChoiceChip(label: Text(label, style: TextStyle(color: sel? Colors.black: Colors.white70, fontSize:10)), selected: sel, selectedColor: const Color(0xFFFFC400), backgroundColor: Colors.white.withOpacity(0.06), onSelected: (_)=>setState(()=>filtre=r))); }
}
