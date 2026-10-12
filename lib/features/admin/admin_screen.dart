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
    var filleuls=prefs.getStringList('filleuls')?? [];
    setState((){
      users=[
        {'nom': prefs.getString('nom')?? 'Moi', 'email': prefs.getString('email')?? 'moi@example.com', 'pays': prefs.getString('pays_id')?? 'BJ', 'grade': 'Aspirant', 'role': 'citoyen'},
       ...filleuls.map((f)=> {'nom': f, 'email': f.toLowerCase().replaceAll(' ', '') + '@test.com', 'pays': 'BJ', 'grade': 'Aspirant', 'role': 'citoyen'}),
        {'nom': 'Admin Mansa', 'email': 'mansa@ligue.panaf', 'pays': 'continent', 'grade': 'Mwalimu', 'role': 'mansa'},
      ];
    });
  }
  @override
  Widget build(BuildContext context){
    var filtered=users.where((u)=> filtre.isEmpty || u['nom']!.toLowerCase().contains(filtre.toLowerCase())).toList();
    return AppScaffold(
      title: 'Super Admin - Mansa',
      child: Column(children:[
        Padding(padding: const EdgeInsets.all(12), child: TextField(style: const TextStyle(color: Colors.white), decoration: InputDecoration(hintText: 'Rechercher...', filled:true, fillColor: Colors.white10, border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none)), onChanged: (v)=> setState(()=> filtre=v))),
        Expanded(child: ListView.builder(padding: const EdgeInsets.all(12), itemCount: filtered.length, itemBuilder: (c,i){
          var u=filtered[i];
          String paysLabel = u['pays']!;
          if(paysLabel.length==2){ try{ paysLabel = LigueData.getCite(paysLabel).nom + ' ' + LigueData.getCite(paysLabel).flag; }catch(_){} }
          return Card(color: const Color(0xFF101845), child: ListTile(
            leading: CircleAvatar(child: Text(u['nom']![0])),
            title: Text(u['nom']!, style: const TextStyle(color: Colors.white, fontSize:11, fontWeight: FontWeight.bold)),
            subtitle: Text('${u['email']} | $paysLabel | ${u['grade']} | ${u['role']}', style: const TextStyle(color: Colors.white54, fontSize:9)),
          ));
        })),
      ]),
    );
  }
}
