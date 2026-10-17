import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/ligue_data.dart';
import '../../widgets/app_scaffold.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});
  @override
  State<AdminScreen> createState()=> _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  List<Map<String,String>> users=[];
  String filtre='';

  @override
  void initState(){ super.initState(); _load(); }

  Future<void> _load() async {
    var prefs=await SharedPreferences.getInstance();
    var filleuls=prefs.getStringList('filleuls') ?? [];
    setState((){
      users=[
        {'nom': prefs.getString('nom') ?? 'Moi', 'email': prefs.getString('email') ?? 'moi@example.com', 'pays': prefs.getString('pays_id') ?? 'BJ', 'grade': 'Aspirant', 'role': 'citoyen'},
        ...filleuls.map((f)=> {'nom': f, 'email': f.toLowerCase().replaceAll(' ', '') + '@test.com', 'pays': 'BJ', 'grade': 'Aspirant', 'role': 'citoyen'}),
        {'nom': 'Admin Mansa', 'email': 'mansa@ligue.panaf', 'pays': 'continent', 'grade': 'Mwalimu', 'role': 'mansa'},
        {'nom': 'Ola Ouest', 'email': 'ola.ouest@ligue.panaf', 'pays': 'ouest', 'grade': 'Mwalimu', 'role': 'ola'},
      ];
    });
  }

  @override
  Widget build(BuildContext context){
    var filtered=users.where((u)=> filtre.isEmpty || u['nom']!.toLowerCase().contains(filtre.toLowerCase()) || u['email']!.toLowerCase().contains(filtre.toLowerCase())).toList();
    return AppScaffold(
      title: 'Super Admin - Mansa / Areopage',
      child: Column(children:[
        Padding(padding: const EdgeInsets.all(12), child: Column(children:[
          TextField(style: const TextStyle(color: Colors.white), decoration: InputDecoration(hintText: 'Rechercher membre...', hintStyle: const TextStyle(color: Colors.white38, fontSize:11), prefixIcon: const Icon(Icons.search, color: Colors.white38, size:16), filled:true, fillColor: Colors.white.withOpacity(0.06), border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none)), onChanged: (v)=> setState(()=> filtre=v)),
          const SizedBox(height:8),
          Row(children:[
            _stat('Total', users.length.toString()),
            const SizedBox(width:8),
            _stat('Cites', '55'),
            const SizedBox(width:8),
            _stat('Actifs', users.length.toString()),
          ]),
          const SizedBox(height:8),
          Wrap(spacing:6, children:[
            ElevatedButton.icon(icon: const Icon(Icons.person_add, size:12), label: const Text('Ajouter membre equipe (CRUD)', style: TextStyle(fontSize:9)), style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE0A82E), foregroundColor: Colors.black), onPressed: (){}),
            ElevatedButton.icon(icon: const Icon(Icons.forum, size:12), label: const Text('Creer Forum Continental', style: TextStyle(fontSize:9)), style: ElevatedButton.styleFrom(backgroundColor: Colors.white10, foregroundColor: Colors.white70), onPressed: (){}),
            ElevatedButton.icon(icon: const Icon(Icons.account_balance, size:12), label: const Text('Voir Tresorerie BCN', style: TextStyle(fontSize:9)), style: ElevatedButton.styleFrom(backgroundColor: Colors.white10, foregroundColor: Colors.white70), onPressed: (){}),
          ]),
        ])),
        Expanded(child: ListView.builder(padding: const EdgeInsets.fromLTRB(12,0,12,12), itemCount: filtered.length, itemBuilder: (c,i){
          var u=filtered[i];
          String paysLabel;
          if(u['pays']=='continent' || u['pays']=='ouest'){
            paysLabel=u['pays']!;
          } else {
            var cite=LigueData.getCite(u['pays']!);
            paysLabel=cite.nom + ' ' + cite.flag;
          }
          return Card(color: const Color(0xFF0E3A3D), margin: const EdgeInsets.only(bottom:6), child: ListTile(
            leading: CircleAvatar(backgroundColor: Colors.white10, child: Text(u['nom']![0], style: const TextStyle(color: Colors.white, fontSize:12))),
            title: Text(u['nom']!, style: const TextStyle(color: Colors.white, fontSize:11, fontWeight: FontWeight.bold)),
            subtitle: Text(u['email']! + ' | ' + paysLabel + ' | Grade: ' + u['grade']! + ' | Role: ' + u['role']!, style: const TextStyle(color: Colors.white54, fontSize:9)),
            trailing: PopupMenuButton(itemBuilder: (c)=>[const PopupMenuItem(value:'edit', child: Text('Modifier grade/role', style: TextStyle(fontSize:11))), const PopupMenuItem(value:'ban', child: Text('Suspendre', style: TextStyle(fontSize:11))), const PopupMenuItem(value:'delete', child: Text('Supprimer', style: TextStyle(fontSize:11)))]),
          ));
        })),
      ]),
    );
  }
  Widget _stat(String label, String value)=> Expanded(child: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.white.withOpacity(0.06), borderRadius: BorderRadius.circular(8)), child: Column(children:[Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize:14)), Text(label, style: const TextStyle(color: Colors.white54, fontSize:9))]))); 
}
