import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/ligue_data.dart';
import '../../widgets/app_scaffold.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState()=> _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String codeParrain='BJ-XXXX-0000';
  String nom='Bienvenue Neurocitoyen';
  String grade='Aspirant (Grade 1)';
  String citeAppartenance='Benin - Porto-Novo';
  String paysId='BJ';
  int modulesValides=0;
  List<String> filleuls=[];
  List<int> poles=[18,13];
  List<String> interetsPerso=['Ecologie','IA'];

  @override
  void initState(){ super.initState(); _load(); }

  Future<void> _load() async {
    var prefs=await SharedPreferences.getInstance();
    setState((){
      codeParrain=prefs.getString('code_parrain') ?? LigueData.genererCodeParrain('BJ');
      nom=prefs.getString('nom') ?? 'Bienvenue Neurocitoyen';
      paysId=prefs.getString('pays_id') ?? 'BJ';
      var cite=LigueData.getCite(paysId);
      citeAppartenance=cite.nom + ' - ' + cite.capitale + ' ' + cite.flag;
      modulesValides=[1,2,3,4,5].where((i)=> prefs.getInt('module_' + i.toString() + '_valide')==1).length;
      grade=LigueData.grades[modulesValides.clamp(0,6)].titre + ' (Grade ' + (modulesValides+1).toString() + ')';
      var polesStr=prefs.getStringList('poles');
      if(polesStr!=null && polesStr.isNotEmpty){ poles=polesStr.map((e)=> int.tryParse(e)??18).toList(); }
      var filleulsStr=prefs.getStringList('filleuls');
      if(filleulsStr!=null) filleuls=filleulsStr;
    });
  }

  Future<void> _ajouterFilleulTest() async {
    var prefs=await SharedPreferences.getInstance();
    var newFilleul='Filleul-' + (filleuls.length+1).toString() + ' - ' + LigueData.genererCodeParrain(paysId);
    setState(()=> filleuls.add(newFilleul));
    await prefs.setStringList('filleuls', filleuls);
  }

  @override
  Widget build(BuildContext context){
    bool certifie=modulesValides>=5;
    return AppScaffold(
      title: 'Tableau de Bord',
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children:[
          // BIENVENU + NOM + GRADE + CITE
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF101845), Color(0xFF1A237E)]), borderRadius: BorderRadius.circular(16)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children:[
              Text('Bienvenue, ' + nom + ' !', style: const TextStyle(color: Colors.white, fontSize:18, fontWeight: FontWeight.bold)),
              const SizedBox(height:6),
              Wrap(spacing:8, children:[
                Chip(label: Text(grade, style: const TextStyle(fontSize:10)), backgroundColor: const Color(0xFFFFC400)),
                Chip(label: Text(citeAppartenance, style: const TextStyle(fontSize:10, color: Colors.white)), backgroundColor: Colors.white10),
                Chip(label: Text('Modules ' + modulesValides.toString() + '/5', style: const TextStyle(fontSize:10)), backgroundColor: modulesValides>=5? Colors.green: Colors.white10),
              ]),
            ]),
          ),
          const SizedBox(height:16),
          // CODE PARRAIN + QR + ARBRE
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: const Color(0xFF101845), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFFFC400).withOpacity(0.3))),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children:[
              const Text('Ton code parrain a donner a tes filleuls', style: TextStyle(color: Colors.white38, fontSize:10)),
              const SizedBox(height:8),
              Row(children:[
                QrImageView(data: codeParrain + '|' + paysId + '|' + nom, size: 90, backgroundColor: Colors.white),
                const SizedBox(width:16),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children:[
                  Text(codeParrain, style: const TextStyle(color: Color(0xFFFFC400), fontWeight: FontWeight.bold, fontSize:18)),
                  const SizedBox(height:4),
                  const Text('Partage ce code ou QR. Tes filleuls rejoindront ton Agora.', style: TextStyle(color: Colors.white54, fontSize:10)),
                  const SizedBox(height:8),
                  Wrap(spacing:6, children:[
                    ElevatedButton.icon(icon: const Icon(Icons.share, size:14), label: const Text('Partager', style: TextStyle(fontSize:10)), style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFFC400), foregroundColor: Colors.black), onPressed: (){}),
                    OutlinedButton(onPressed: _ajouterFilleulTest, child: const Text('Test +1 filleul (CRUD)', style: TextStyle(fontSize:9))),
                  ]),
                ])),
              ]),
            ]),
          ),
          const SizedBox(height:16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(12)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children:[
              Row(children:[const Text('Arbre de Cooptation', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize:13)), const Spacer(), Text(filleuls.length.toString() + ' filleuls', style: const TextStyle(color: Color(0xFFFFC400), fontSize:11))]),
              const SizedBox(height:8),
              if(filleuls.isEmpty) const Text('Aucun filleul. Partage ton code parrain pour agrandir ton Agora et devenir Cadre (Grade 3 necessite parrainage).', style: TextStyle(color: Colors.white38, fontSize:11))
              else ...filleuls.map((f)=> Card(color: Colors.white.withOpacity(0.06), margin: const EdgeInsets.only(bottom:6), child: ListTile(leading: const Icon(Icons.person, color: Color(0xFFFFC400), size:18), title: Text(f, style: const TextStyle(color: Colors.white70, fontSize:11)), trailing: IconButton(icon: const Icon(Icons.delete, size:14, color: Colors.white24), onPressed: () async { setState(()=> filleuls.remove(f)); var p=await SharedPreferences.getInstance(); await p.setStringList('filleuls', filleuls); })))) ,
            ]),
          ),
          const SizedBox(height:16),
          const Text('Progression Modules - Verrouillage sequentiel', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          const SizedBox(height:8),
          ...LigueData.modules.map((m){
            return FutureBuilder<SharedPreferences>(
              future: SharedPreferences.getInstance(),
              builder: (c,snap){
                bool valide = snap.data?.getInt('module_' + m.numero.toString() + '_valide')==1;
                bool precedentValide = m.numero==1 || (snap.data?.getInt('module_' + (m.numero-1).toString() + '_valide')==1);
                bool bloque = !precedentValide;
                return Card(
                  color: valide? Colors.green.withOpacity(0.15): bloque? Colors.white.withOpacity(0.03): const Color(0xFF101845),
                  margin: const EdgeInsets.only(bottom:8),
                  child: ListTile(
                    leading: CircleAvatar(backgroundColor: valide? Colors.green: bloque? Colors.white10: const Color(0xFFFFC400), child: Text(m.numero.toString(), style: TextStyle(color: valide||bloque? Colors.white: Colors.black, fontWeight: FontWeight.bold, fontSize:12))),
                    title: Text(m.titre, style: TextStyle(color: bloque? Colors.white24: Colors.white, fontWeight: FontWeight.bold, fontSize:12)),
                    subtitle: Text(m.objectif + (bloque? ' - Bloque, valide Module ' + (m.numero-1).toString(): ''), style: const TextStyle(color: Colors.white54, fontSize:10)),
                    trailing: valide? const Icon(Icons.check_circle, color: Colors.green, size:20): bloque? const Icon(Icons.lock, color: Colors.white24, size:18): ElevatedButton(onPressed: ()=>context.go('/module/' + m.numero.toString()), style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFFC400), foregroundColor: Colors.black, padding: const EdgeInsets.symmetric(horizontal:12, vertical:6)), child: const Text('Commencer', style: TextStyle(fontSize:10))),
                  ),
                );
              }
            );
          }),
          const SizedBox(height:16),
          if(certifie) Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: Colors.green.withOpacity(0.15), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.green)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children:[
              const Text('🎓 Certificat Neurocitoyen Certifie - Grade 2 Obtenu', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
              const SizedBox(height:8),
              Text('Selon tes poles ' + poles.toString() + ' et interets ' + interetsPerso.join(', ') + ', voici formations et missions :', style: const TextStyle(color: Colors.white70, fontSize:11)),
              const SizedBox(height:8),
              ...poles.map((num){
                var p = LigueData.poles.firstWhere((x)=>x.numero==num);
                return Padding(padding: const EdgeInsets.only(bottom:6), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children:[
                  Text('Pole ' + p.numero.toString() + ' - ' + p.nom, style: const TextStyle(color: Colors.white, fontSize:11, fontWeight: FontWeight.bold)),
                  Text('Formations: ' + p.formations.join(', '), style: const TextStyle(color: Colors.white54, fontSize:10)),
                  Text('Missions: ' + p.missions.join(', '), style: const TextStyle(color: Colors.white38, fontSize:10)),
                ]));
              }),
              const SizedBox(height:8),
              ElevatedButton(onPressed: ()=>context.go('/universite'), style: ElevatedButton.styleFrom(backgroundColor: Colors.green), child: const Text('Voir Universite Panafricaine Continue')),
            ]),
          ),
        ]),
      ),
    );
  }
}
