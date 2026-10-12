import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/ligue_data.dart';
import '../../widgets/app_scaffold.dart';

class InscriptionScreen extends StatefulWidget {
  final String paysId;
  const InscriptionScreen({super.key, required this.paysId});
  @override
  State<InscriptionScreen> createState()=> _InscriptionScreenState();
}
class _InscriptionScreenState extends State<InscriptionScreen> {
  int step=0;
  String email='', password='', nom='', prenom='', phone='', commune='', quartier='', codeParrainUtilise='';
  List<int> polesChoisis=[];
  List<String> interetsElargis=[];

  @override
  void initState(){
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      var qp=GoRouterState.of(context).uri.queryParameters;
      setState(()=> codeParrainUtilise=qp['parrain']??'');
    });
  }

  @override
  Widget build(BuildContext context){
    var cite=LigueData.getCite(widget.paysId);
    return AppScaffold(
      title: cite.flag + ' ' + cite.nom + ' - Inscription',
      child: Center(child: Container(constraints: const BoxConstraints(maxWidth:600), padding: const EdgeInsets.all(20), child: Column(children:[
        LinearProgressIndicator(value: (step+1)/4, color: const Color(0xFFFFC400), backgroundColor: Colors.white10),
        const SizedBox(height:12),
        Text('Etape ' + (step+1).toString() + '/4 - ' + ['Identite','Territoire','Poles & Interets elargis','Recap & Code'][step], style: const TextStyle(color: Colors.white38, fontSize:10)),
        const SizedBox(height:16),
        Expanded(child: SingleChildScrollView(child: _step(cite))),
        SizedBox(width: double.infinity, child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFFC400), foregroundColor: Colors.black, padding: const EdgeInsets.symmetric(vertical:16)), onPressed: () async {
          if(step<3){ setState(()=>step++); return; }
          var prefs=await SharedPreferences.getInstance();
          String nouveauCode=LigueData.genererCodeParrain(cite.id);
          await prefs.setString('code_parrain', nouveauCode);
          await prefs.setString('pays_id', cite.id);
          await prefs.setString('nom', prenom + ' ' + nom);
          await prefs.setStringList('poles', polesChoisis.map((e)=>e.toString()).toList());
          await prefs.setStringList('interets_elargis', interetsElargis);
          await prefs.setString('parrain_de', codeParrainUtilise);
          if(mounted) context.go('/dashboard');
        }, child: Text(step<3?'Continuer':'Creer compte & Dashboard avec QR'))),
      ]))),
    );
  }

  Widget _step(Cite cite){
    if(step==0) return Column(crossAxisAlignment: CrossAxisAlignment.start, children:[
      if(codeParrainUtilise.isNotEmpty) Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.green.withOpacity(0.15), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.green)), child: Text('Parrain : ' + codeParrainUtilise, style: const TextStyle(color: Colors.green, fontSize:11))),
      const SizedBox(height:8),
      const Text('Identite - Aspirant', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize:16)),
      const SizedBox(height:10),
      _f('Prenom', (v)=>prenom=v), _f('Nom', (v)=>nom=v), _f('Email', (v)=>email=v), _f('Phone (pour SMS auto)', (v)=>phone=v), _f('Mot de passe', (v)=>password=v, obscure:true),
    ]);
    if(step==1) return Column(crossAxisAlignment: CrossAxisAlignment.start, children:[
      const Text('Territoire', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize:16)),
      const SizedBox(height:10),
      _f('Commune / Deme', (v)=>commune=v), _f('Quartier / Village / Agora', (v)=>quartier=v),
      const Text('Tu rejoindras Agora mensuelle quartier', style: TextStyle(color: Colors.white38, fontSize:10)),
    ]);
    if(step==2) return Column(crossAxisAlignment: CrossAxisAlignment.start, children:[
      const Text('Poles & Interets elargis (au-dela 21)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize:14)),
      const SizedBox(height:6),
      const Text('Choisis 1-2 poles + ajoute interets non listes (ex: apiculture, drone) on repartit dans thematique proche', style: TextStyle(color: Colors.white54, fontSize:10)),
      const SizedBox(height:10),
      Wrap(spacing:6, runSpacing:6, children: LigueData.poles.map((p){
        bool sel=polesChoisis.contains(p.numero);
        return FilterChip(label: Text(p.numero.toString() + '. ' + p.nom, style: TextStyle(color: sel? Colors.black: Colors.white70, fontSize:9)), selected: sel, selectedColor: const Color(0xFFFFC400), backgroundColor: Colors.white.withOpacity(0.06), onSelected: (v){ setState((){ if(v){ if(polesChoisis.length<2) polesChoisis.add(p.numero); } else polesChoisis.remove(p.numero); });});
      }).toList()),
      const SizedBox(height:12),
      TextField(style: const TextStyle(color: Colors.white, fontSize:11), decoration: InputDecoration(hintText: 'Interets elargis ex: apiculture, podcast, drone... (separes par virgule)', hintStyle: const TextStyle(color: Colors.white38, fontSize:9), filled:true, fillColor: Colors.white.withOpacity(0.06), border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none)), onChanged: (v){ setState(()=> interetsElargis=v.split(',').map((e)=>e.trim()).where((e)=>e.isNotEmpty).toList()); }),
    ]);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children:[
      const Text('Recapitulatif', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize:14)),
      const SizedBox(height:8),
      Text('Nom: ' + prenom + ' ' + nom + '\nEmail: ' + email + '\nPhone: ' + phone + '\nCite: ' + cite.nom + '\nDeme: ' + commune + ' Agora: ' + quartier + '\nPoles: ' + polesChoisis.toString() + '\nInterets elargis: ' + interetsElargis.join(', '), style: const TextStyle(color: Colors.white70, fontSize:11)),
      const SizedBox(height:10),
      Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: const Color(0xFFFFC400).withOpacity(0.15), borderRadius: BorderRadius.circular(8)), child: const Text('Apres creation : code parrain auto genere + QR + compte bancaire BCN auto + SMS avec identifiants + lien dashboard niveau + arbre cooptation vide pret a partager.', style: TextStyle(color: Color(0xFFFFC400), fontSize:10))),
    ]);
  }
  Widget _f(String l, Function(String) onC, {bool obscure=false})=> Padding(padding: const EdgeInsets.only(bottom:8), child: TextField(onChanged: onC, obscureText: obscure, style: const TextStyle(color: Colors.white, fontSize:12), decoration: InputDecoration(labelText:l, labelStyle: const TextStyle(color: Colors.white38, fontSize:11), filled:true, fillColor: Colors.white.withOpacity(0.06), border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none))));
}
