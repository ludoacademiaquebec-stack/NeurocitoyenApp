import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class IAGuideGlobal extends StatefulWidget {
  const IAGuideGlobal({super.key});
  @override
  State<IAGuideGlobal> createState()=> _IAGuideGlobalState();
}

class _IAGuideGlobalState extends State<IAGuideGlobal> {
  List<Map<String,String>> chat=[
    {'role':'ia','text':'Bienvenue 🧠\n\nJe suis ton Guide IA LIVE (Groq). Je connais Charte 47 articles, Modèle Eco 295M, Parcours 5 modules.\n\nPose ta question!'},
  ];
  final ctrl=TextEditingController();
  bool loading=false;

  Future<void> send(String t) async {
    if(t.trim().isEmpty || loading) return;
    setState((){ chat.add({'role':'user','text':t}); loading=true; });
    ctrl.clear();
    try {
      final res = await Supabase.instance.client.functions.invoke('ia-chat', body: {
        'message': t,
        'ia_type': 'GUIDE',
        'prompt': t,
      });
      String text = 'Pas de réponse';
      if(res.data is Map){
        final d = res.data as Map;
        text = (d['response']?? d['reponse']?? d['text']?? d.toString()).toString();
      }
      setState(()=> chat.add({'role':'ia','text': text}));
    } catch (e) {
      setState(()=> chat.add({'role':'ia','text': '⚠️ $e'}));
    } finally {
      setState(()=> loading=false);
    }
  }

  @override
  Widget build(BuildContext context){
    return Scaffold(
      backgroundColor: const Color(0xFF080C1F),
      appBar: AppBar(backgroundColor: const Color(0xFF080C1F), title: const Text('IA Guide - LIVE ✅', style: TextStyle(fontSize:12, color: Colors.white)), leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: ()=>context.go('/'))),
      body: Column(children:[
        Expanded(child: ListView.builder(padding: const EdgeInsets.all(12), itemCount: chat.length, itemBuilder: (c,i){
          var m=chat[i]; bool isUser=m['role']=='user';
          return Align(alignment: isUser? Alignment.centerRight: Alignment.centerLeft, child: Container(margin: const EdgeInsets.only(bottom:10), padding: const EdgeInsets.all(12), constraints: const BoxConstraints(maxWidth: 380), decoration: BoxDecoration(color: isUser? const Color(0xFFFFC400): const Color(0xFF101845), borderRadius: BorderRadius.circular(12)), child: Text(m['text']!, style: TextStyle(color: isUser? Colors.black: Colors.white70, fontSize:12))));
        })),
        if(loading) const LinearProgressIndicator(color: Color(0xFFFFC400)),
        Padding(padding: const EdgeInsets.all(12), child: Row(children:[Expanded(child: TextField(controller: ctrl, onSubmitted: send, style: const TextStyle(color: Colors.white, fontSize:12), decoration: InputDecoration(hintText: 'Pose ta vraie question...', hintStyle: const TextStyle(color: Colors.white38, fontSize:10), filled:true, fillColor: Colors.white.withOpacity(0.06), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)))), const SizedBox(width:8), IconButton.filled(onPressed: ()=>send(ctrl.text), icon: const Icon(Icons.send), style: IconButton.styleFrom(backgroundColor: const Color(0xFFFFC400), foregroundColor: Colors.black)) ])),
      ]),
    );
  }
}
