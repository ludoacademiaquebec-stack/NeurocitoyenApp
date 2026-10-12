import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/ligue_data.dart';
import '../../widgets/app_scaffold.dart';

class ModulesScreen extends StatefulWidget {
  const ModulesScreen({super.key});
  @override
  State<ModulesScreen> createState()=> _ModulesScreenState();
}

class _ModulesScreenState extends State<ModulesScreen> {
  Map<int,bool> valides={};
  @override
  void initState(){ super.initState(); _load(); }
  Future<void> _load() async {
    var p=await SharedPreferences.getInstance();
    setState((){
      for(var m in LigueData.modules){ valides[m.numero]=p.getInt('module_' + m.numero.toString() + '_valide')==1; }
    });
  }
  @override
  Widget build(BuildContext context){
    return AppScaffold(
      title: '5 Modules - Verrouillage',
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: LigueData.modules.length,
        itemBuilder: (c,i){
          var m=LigueData.modules[i];
          bool valide=valides[m.numero]??false;
          bool precedentValide = m.numero==1 || (valides[m.numero-1]??false);
          bool bloque = !precedentValide;
          return Card(
            color: valide? Colors.green.withOpacity(0.15): bloque? Colors.white.withOpacity(0.03): const Color(0xFF101845),
            margin: const EdgeInsets.only(bottom:12),
            child: ListTile(
              leading: CircleAvatar(backgroundColor: valide? Colors.green: bloque? Colors.white10: const Color(0xFFFFC400), child: Text(m.numero.toString(), style: TextStyle(color: valide||bloque? Colors.white: Colors.black, fontWeight: FontWeight.bold))),
              title: Text(m.titre, style: TextStyle(color: bloque? Colors.white24: Colors.white, fontWeight: FontWeight.bold, fontSize:13)),
              subtitle: Text(m.objectif + (bloque? ' (Bloque - valide Module ' + (m.numero-1).toString() + ')' : ''), style: const TextStyle(color: Colors.white54, fontSize:11)),
              trailing: valide? const Icon(Icons.check_circle, color: Colors.green): bloque? const Icon(Icons.lock, color: Colors.white24): ElevatedButton(onPressed: ()=>context.go('/module/' + m.numero.toString()), style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFFC400), foregroundColor: Colors.black), child: const Text('Commencer', style: TextStyle(fontSize:10))),
            ),
          );
        },
      ),
    );
  }
}
