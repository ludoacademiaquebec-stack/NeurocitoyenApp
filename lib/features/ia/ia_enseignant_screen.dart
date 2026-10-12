import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/ligue_data.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../widgets/app_scaffold.dart';

class IAEnseignantScreen extends StatefulWidget {
  final int moduleId;
  const IAEnseignantScreen({super.key, required this.moduleId});
  @override
  State<IAEnseignantScreen> createState()=> _IAEnseignantScreenState();
}

class _IAEnseignantScreenState extends State<IAEnseignantScreen> {
  int leconIndex=0;
  int questionIndex=0;
  bool modeQCM=false;
  int scoreQCM=0;
  int qcmIndex=0;
  List<Map<String,String>> chat=[];
  final ctrl=TextEditingController();
  late ModuleFormation module;

  @override
  void initState(){
    super.initState();
    module=LigueData.modules.firstWhere((m)=>m.numero==widget.moduleId);
    _startLecon();
  }

  void _startLecon(){
    var lecon=module.lecons[leconIndex];
    setState((){
      chat.add({'role':'ia','text':'Module ' + module.numero.toString() + ' - ' + module.titre + '\nLecon ' + (leconIndex+1).toString() + '/' + module.lecons.length.toString() + ' : ' + lecon.titre + '\n\n' + lecon.contenuIA + '\n\n---\n' + lecon.questionsIA[questionIndex]});
    });
  }

  void _nextStep(){
    var lecon=module.lecons[leconIndex];
    if(questionIndex < lecon.questionsIA.length-1){
      setState((){
        questionIndex++;
        chat.add({'role':'ia','text': lecon.questionsIA[questionIndex]});
      });
    } else {
      if(leconIndex < module.lecons.length-1){
        setState((){
          leconIndex++; questionIndex=0;
        });
        _startLecon();
      } else {
        setState((){
          modeQCM=true;
          chat.add({'role':'ia','text':'Nous sommes venus a la fin du ' + module.titre + ' ! Bravo.\n\nQCM validation - minimum 85% pour passer suivant.\n\nQuestion 1 : ' + module.qcm[0]['q'].toString()});
        });
      }
    }
  }

  void _handleUser(String text){
    if(text.trim().isEmpty) return;
    setState((){
      chat.add({'role':'user','text':text});
      if(text.toLowerCase().contains('je ne sais pas') || text.toLowerCase().contains('aide')){
        chat.add({'role':'ia','text':'Pas de souci, je t aide.\n\n' + module.lecons[leconIndex].contenuIA + '\n\nAlors, que repondrais-tu a : ' + module.lecons[leconIndex].questionsIA[questionIndex] + ' ? Pose aussi ta question !'});
      } else {
        chat.add({'role':'ia','text':'Merci : "' + text + '"\n\nTres bonne reflexion ! Fais lien avec ton vecu Agora.\n\nQuestion avant continuer ? Sinon dis continue.'});
      }
    });
    ctrl.clear();
  }

  void _repondreQCM(int choix){
    var q=module.qcm[qcmIndex];
    bool bonne=choix==q['bonne'];
    if(bonne) scoreQCM++;
    setState((){
      chat.add({'role':'user','text': q['options'][choix].toString()});
      chat.add({'role':'ia','text': bonne? 'Bonne reponse !' : 'Pas tout a fait. Bonne : ' + q['options'][q['bonne']].toString()});
      qcmIndex++;
      if(qcmIndex < module.qcm.length){
        chat.add({'role':'ia','text':'Question ' + (qcmIndex+1).toString() + ' : ' + module.qcm[qcmIndex]['q'].toString() + '\nOptions : ' + (module.qcm[qcmIndex]['options'] as List).join(' / ')});
      } else {
        double pct=(scoreQCM / module.qcm.length)*100;
        if(pct>=85){
          chat.add({'role':'ia','text':'FELICITATIONS ! Tu as ' + pct.toStringAsFixed(0) + '% (' + scoreQCM.toString() + '/' + module.qcm.length.toString() + ').\n\nTu valides ' + module.titre + ' !\n\n' + (module.numero<5? 'Passe Module ' + (module.numero+1).toString(): '5 modules termines ! Certificat genere. Formations et missions selon poles.')});
          _save();
        } else {
          chat.add({'role':'ia','text':'Tu as ' + pct.toStringAsFixed(0) + '%. Il faut 85%. On recommence ?'});
          qcmIndex=0; scoreQCM=0;
        }
      }
    });
  }

  Future<void> _save() async {
    var prefs=await SharedPreferences.getInstance();
    await prefs.setInt('module_' + module.numero.toString() + '_valide', 1);
  }

  @override
  Widget build(BuildContext context){
    return AppScaffold(
      title: 'Module ' + module.numero.toString() + ' - IA Enseignante',
      child: Column(children:[
        LinearProgressIndicator(value: modeQCM? 1 : (leconIndex+1)/module.lecons.length, color: const Color(0xFFFFC400), backgroundColor: Colors.white10),
        Padding(padding: const EdgeInsets.all(8), child: Text(modeQCM? 'QCM ' + (qcmIndex+1).toString() + '/' + module.qcm.length.toString() + ' Score: ' + scoreQCM.toString(): 'Lecon ' + (leconIndex+1).toString() + '/' + module.lecons.length.toString(), style: const TextStyle(color: Colors.white38, fontSize:10))),
        Expanded(child: ListView.builder(padding: const EdgeInsets.all(12), itemCount: chat.length, itemBuilder: (c,i){
          var m=chat[i]; bool isUser=m['role']=='user';
          return Align(alignment: isUser? Alignment.centerRight: Alignment.centerLeft, child: Container(margin: const EdgeInsets.only(bottom:10), padding: const EdgeInsets.all(12), constraints: const BoxConstraints(maxWidth: 380), decoration: BoxDecoration(color: isUser? const Color(0xFFFFC400): const Color(0xFF101845), borderRadius: BorderRadius.circular(12)), child: Text(m['text']!, style: TextStyle(color: isUser? Colors.black: Colors.white70, fontSize:12))));
        })),
        if(modeQCM && qcmIndex < module.qcm.length) Padding(padding: const EdgeInsets.all(8), child: Wrap(spacing:6, children: (module.qcm[qcmIndex]['options'] as List).asMap().entries.map((e)=> ElevatedButton(onPressed: ()=>_repondreQCM(e.key), style: ElevatedButton.styleFrom(backgroundColor: Colors.white10, foregroundColor: Colors.white), child: Text(e.value.toString(), style: const TextStyle(fontSize:11)))).toList())),
        if(!modeQCM) Padding(padding: const EdgeInsets.all(12), child: Row(children:[Expanded(child: TextField(controller: ctrl, onSubmitted: _handleUser, style: const TextStyle(color: Colors.white, fontSize:12), decoration: InputDecoration(hintText: 'Ta reponse ou question... (je ne sais pas si bloque)', hintStyle: const TextStyle(color: Colors.white38, fontSize:10), filled:true, fillColor: Colors.white.withOpacity(0.06), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)))), const SizedBox(width:8), IconButton.filled(onPressed: ()=>_handleUser(ctrl.text), icon: const Icon(Icons.send), style: IconButton.styleFrom(backgroundColor: const Color(0xFFFFC400), foregroundColor: Colors.black)), const SizedBox(width:4), OutlinedButton(onPressed: _nextStep, child: const Text('Continuer', style: TextStyle(fontSize:10)))])),
      ]),
    );
  }
}
