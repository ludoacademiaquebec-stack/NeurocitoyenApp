import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/ligue_data.dart';
import '../../widgets/app_scaffold.dart';

class ProfilScreen extends StatefulWidget {
  const ProfilScreen({super.key});
  @override
  State<ProfilScreen> createState()=> _ProfilScreenState();
}

class _ProfilScreenState extends State<ProfilScreen> {
  String nom='', prenom='', email='', phone='', commune='', quartier='', paysId='BJ', codeParrain='', grade='Aspirant';
  List<String> poles=[];
  List<String> interets=[];
  String avatarUrl='';
  bool editMode=false;

  @override
  void initState(){ super.initState(); _load(); }

  Future<void> _load() async {
    var p=await SharedPreferences.getInstance();
    setState((){
      nom=p.getString('nom')?.split(' ').last ?? '';
      prenom=p.getString('nom')?.split(' ').first ?? '';
      email=p.getString('email') ?? '';
      phone=p.getString('phone') ?? '';
      commune=p.getString('commune') ?? '';
      quartier=p.getString('quartier') ?? '';
      paysId=p.getString('pays_id') ?? 'BJ';
      codeParrain=p.getString('code_parrain') ?? LigueData.genererCodeParrain(paysId);
      var mods=[1,2,3,4,5].where((i)=> p.getInt('module_' + i.toString() + '_valide')==1).length;
      grade=LigueData.grades[mods.clamp(0,6)].titre + ' (Grade ' + (mods+1).toString() + ')';
      poles=p.getStringList('poles') ?? [];
      interets=p.getStringList('interets_elargis') ?? [];
      avatarUrl=p.getString('avatar_url') ?? '';
    });
  }

  Future<void> _save() async {
    var p=await SharedPreferences.getInstance();
    await p.setString('nom', prenom + ' ' + nom);
    await p.setString('email', email);
    await p.setString('phone', phone);
    await p.setString('commune', commune);
    await p.setString('quartier', quartier);
    await p.setString('pays_id', paysId);
    await p.setStringList('poles', poles);
    await p.setStringList('interets_elargis', interets);
    await p.setString('avatar_url', avatarUrl);
    if(mounted){
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profil mis a jour - CRUD OK. Si demenagement, cite/commune modifiee.')));
      setState(()=> editMode=false);
    }
  }

  @override
  Widget build(BuildContext context){
    var cite=LigueData.getCite(paysId);
    return AppScaffold(
      title: 'Profil - CRUD Complet',
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children:[
          // Avatar + bienvenue
          Row(children:[
            Stack(children:[
              CircleAvatar(radius:40, backgroundColor: const Color(0xFF0E3A3D), backgroundImage: avatarUrl.isNotEmpty? NetworkImage(avatarUrl): null, child: avatarUrl.isEmpty? Text(prenom.isNotEmpty? prenom[0]: 'N', style: const TextStyle(color: Colors.white, fontSize:24)): null),
              Positioned(bottom:0, right:0, child: InkWell(onTap: () async { var p=await SharedPreferences.getInstance(); setState(()=> avatarUrl='https://i.pravatar.cc/150?u=' + email); await p.setString('avatar_url', avatarUrl); }, child: Container(padding: const EdgeInsets.all(4), decoration: const BoxDecoration(color: Color(0xFFE0A82E), shape: BoxShape.circle), child: const Icon(Icons.camera_alt, size:12, color: Colors.black)))),
            ]),
            const SizedBox(width:16),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children:[
              Text('Bienvenue, ' + prenom + ' ' + nom + ' !', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize:16)),
              const SizedBox(height:4),
              Text(grade + ' | ' + cite.nom + ' ' + cite.flag + ' | ' + cite.capitale, style: const TextStyle(color: Colors.white70, fontSize:11)),
              Text('Code parrain: ' + codeParrain, style: const TextStyle(color: Color(0xFFE0A82E), fontSize:11, fontWeight: FontWeight.bold)),
            ])),
          ]),
          const SizedBox(height:16),
          Row(children:[
            ElevatedButton.icon(icon: Icon(editMode? Icons.save: Icons.edit, size:14), label: Text(editMode? 'Sauvegarder':'Modifier profil', style: const TextStyle(fontSize:11)), style: ElevatedButton.styleFrom(backgroundColor: editMode? Colors.green: const Color(0xFFE0A82E), foregroundColor: editMode? Colors.white: Colors.black), onPressed: (){ if(editMode) _save(); else setState(()=> editMode=true); }),
            const SizedBox(width:8),
            if(editMode) OutlinedButton(onPressed: ()=> setState(()=> editMode=false), child: const Text('Annuler', style: TextStyle(fontSize:11, color: Colors.white54))),
          ]),
          const SizedBox(height:16),
          const Text('Identite (CRUD)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize:12)),
          const SizedBox(height:8),
          Row(children:[Expanded(child: _field('Prenom', prenom, (v)=>prenom=v, enabled: editMode)), const SizedBox(width:8), Expanded(child: _field('Nom', nom, (v)=>nom=v, enabled: editMode))]),
          _field('Email (modifiable)', email, (v)=>email=v, enabled: editMode),
          _field('Telephone (pour SMS auto)', phone, (v)=>phone=v, enabled: editMode),
          _field('Photo URL (avatar)', avatarUrl, (v)=>avatarUrl=v, enabled: editMode),
          const SizedBox(height:12),
          const Text('Territoire (modifiable si demenagement)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize:12)),
          const SizedBox(height:8),
          DropdownButtonFormField<String>(value: paysId, dropdownColor: const Color(0xFF0E3A3D), style: const TextStyle(color: Colors.white, fontSize:12), decoration: InputDecoration(labelText: 'Cite / Pays', labelStyle: const TextStyle(color: Colors.white38, fontSize:10), filled:true, fillColor: Colors.white.withOpacity(0.06), border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none)), items: LigueData.cites.map((c)=> DropdownMenuItem(value: c.id, child: Text(c.flag + ' ' + c.nom, style: const TextStyle(fontSize:11)))).toList(), onChanged: editMode? (v){ setState(()=> paysId=v!); }: null),
          const SizedBox(height:8),
          Row(children:[Expanded(child: _field('Commune / Deme', commune, (v)=>commune=v, enabled: editMode)), const SizedBox(width:8), Expanded(child: _field('Quartier / Agora', quartier, (v)=>quartier=v, enabled: editMode))]),
          const SizedBox(height:12),
          const Text('Poles & Interets', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize:12)),
          const SizedBox(height:8),
          Wrap(spacing:6, runSpacing:6, children: LigueData.poles.map((p){
            bool sel=poles.contains(p.numero.toString());
            return FilterChip(label: Text(p.numero.toString() + '. ' + p.nom, style: TextStyle(color: sel? Colors.black: Colors.white70, fontSize:9)), selected: sel, selectedColor: const Color(0xFFE0A82E), backgroundColor: Colors.white.withOpacity(0.06), onSelected: editMode? (v){ setState((){ if(v){ if(poles.length<3) poles.add(p.numero.toString()); } else poles.remove(p.numero.toString()); }); }: null);
          }).toList()),
          const SizedBox(height:8),
          _field('Interets elargis (virgule)', interets.join(', '), (v)=> interets=v.split(',').map((e)=>e.trim()).where((e)=>e.isNotEmpty).toList(), enabled: editMode),
          const SizedBox(height:16),
          const Text('Securite', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize:12)),
          const SizedBox(height:8),
          Row(children:[
            Expanded(child: ElevatedButton.icon(icon: const Icon(Icons.lock, size:14), label: const Text('Changer mot de passe', style: TextStyle(fontSize:10)), style: ElevatedButton.styleFrom(backgroundColor: Colors.white10, foregroundColor: Colors.white70), onPressed: (){})),
            const SizedBox(width:8),
            Expanded(child: ElevatedButton.icon(icon: const Icon(Icons.logout, size:14), label: const Text('Deconnexion', style: TextStyle(fontSize:10)), style: ElevatedButton.styleFrom(backgroundColor: Colors.red.withOpacity(0.2), foregroundColor: Colors.red), onPressed: () async { var p=await SharedPreferences.getInstance(); await p.clear(); if(context.mounted) context.go('/'); })),
          ]),
        ]),
      ),
    );
  }

  Widget _field(String label, String value, Function(String) onC, {bool enabled=true})=> Padding(padding: const EdgeInsets.only(bottom:8), child: TextFormField(initialValue: value, enabled: enabled, onChanged: onC, style: const TextStyle(color: Colors.white, fontSize:12), decoration: InputDecoration(labelText: label, labelStyle: const TextStyle(color: Colors.white38, fontSize:10), filled:true, fillColor: enabled? Colors.white.withOpacity(0.06): Colors.white.withOpacity(0.03), border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none))));
}
