import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/ligue_data.dart';
import '../../widgets/app_scaffold.dart';

class UniversiteScreen extends StatefulWidget {
  const UniversiteScreen({super.key});
  @override
  State<UniversiteScreen> createState()=> _UniversiteScreenState();
}

class _UniversiteScreenState extends State<UniversiteScreen> {
  String filtre='tous';
  String search='';
  @override
  Widget build(BuildContext context){
    var formations=LigueData.formationsContinues.where((f){
      bool matchFiltre=filtre=='tous' || f.poleNumero.toString()==filtre;
      bool matchSearch=search.isEmpty || f.titre.toLowerCase().contains(search.toLowerCase()) || f.description.toLowerCase().contains(search.toLowerCase());
      return matchFiltre && matchSearch;
    }).toList();

    return AppScaffold(
      title: 'Universite Panafricaine - Formations Continues',
      child: Column(children:[
        Padding(padding: const EdgeInsets.all(12), child: Column(children:[
          TextField(style: const TextStyle(color: Colors.white), decoration: InputDecoration(hintText: 'Rechercher formation...', hintStyle: const TextStyle(color: Colors.white38, fontSize:11), prefixIcon: const Icon(Icons.search, color: Colors.white38, size:16), filled:true, fillColor: Colors.white.withOpacity(0.06), border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none)), onChanged: (v)=> setState(()=> search=v)),
          const SizedBox(height:8),
          SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children:[
            _chip('tous','Tous'),
            ...LigueData.poles.map((p)=> _chip(p.numero.toString(), 'Pole ' + p.numero.toString())),
          ])),
          const SizedBox(height:8),
          Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: const Color(0xFFFFC400).withOpacity(0.15), borderRadius: BorderRadius.circular(8)), child: const Row(children:[Icon(Icons.info, size:14, color: Color(0xFFFFC400)), SizedBox(width:6), Expanded(child: Text('Les 5 premiers modules = ossature depart. Apres, formations certifiantes et pro selon interets + interets elargis au-dela 21 (repartis dans 21 thematiques).', style: TextStyle(color: Color(0xFFFFC400), fontSize:10)))])),
        ])),
        Expanded(child: ListView.builder(padding: const EdgeInsets.fromLTRB(12,0,12,12), itemCount: formations.length+1, itemBuilder: (c,i){
          if(i==0){
            return Card(color: const Color(0xFF101845), child: Padding(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children:[
              const Text('Ajouter interet elargi (au-dela 21 poles)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize:12)),
              const SizedBox(height:6),
              const Text('Tu peux proposer interet non dans 21 poles, on le repartit dans thematique la plus proche. Ex: apiculture -> pole 10 agriculture, drone -> pole 6 numerique.', style: TextStyle(color: Colors.white54, fontSize:10)),
              const SizedBox(height:8),
              Row(children:[Expanded(child: TextField(style: const TextStyle(color: Colors.white, fontSize:11), decoration: InputDecoration(hintText: 'Ex: apiculture, drone, podcast...', hintStyle: const TextStyle(color: Colors.white38, fontSize:10), filled:true, fillColor: Colors.white.withOpacity(0.06), border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none)))), const SizedBox(width:6), ElevatedButton(onPressed: (){}, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFFC400), foregroundColor: Colors.black), child: const Text('Ajouter', style: TextStyle(fontSize:10)))]),
            ])));
          }
          var f=formations[i-1];
          var pole=LigueData.poles.firstWhere((p)=>p.numero==f.poleNumero);
          return Card(color: const Color(0xFF101845), margin: const EdgeInsets.only(bottom:8), child: ListTile(
            leading: CircleAvatar(backgroundColor: Colors.white10, child: Icon(pole.icon, size:16, color: const Color(0xFFFFC400))),
            title: Text(f.titre, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize:12)),
            subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children:[
              Text(f.description, style: const TextStyle(color: Colors.white54, fontSize:10)),
              const SizedBox(height:4),
              Wrap(spacing:4, children:[
                Chip(label: Text(f.niveau, style: const TextStyle(fontSize:8)), backgroundColor: Colors.white10, labelStyle: const TextStyle(color: Colors.white70)),
                Chip(label: Text(f.duree, style: const TextStyle(fontSize:8)), backgroundColor: Colors.white10, labelStyle: const TextStyle(color: Colors.white70)),
                Chip(label: Text(f.certification, style: const TextStyle(fontSize:8)), backgroundColor: const Color(0xFFFFC400).withOpacity(0.2), labelStyle: const TextStyle(color: Color(0xFFFFC400))),
                Chip(label: Text('Pole ' + f.poleNumero.toString(), style: const TextStyle(fontSize:8)), backgroundColor: Colors.white10, labelStyle: const TextStyle(color: Colors.white70)),
              ]),
            ]),
            trailing: ElevatedButton(onPressed: ()=>context.go('/module/1'), style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFFC400), foregroundColor: Colors.black, padding: const EdgeInsets.symmetric(horizontal:10, vertical:6)), child: const Text('S inscrire', style: TextStyle(fontSize:9))),
          ));
        })),
      ]),
    );
  }
  Widget _chip(String id, String label){
    bool sel=filtre==id;
    return Padding(padding: const EdgeInsets.only(right:6), child: ChoiceChip(label: Text(label, style: TextStyle(color: sel? Colors.black: Colors.white70, fontSize:10)), selected: sel, selectedColor: const Color(0xFFFFC400), backgroundColor: Colors.white.withOpacity(0.06), onSelected: (_)=> setState(()=> filtre=id)));
  }
}
