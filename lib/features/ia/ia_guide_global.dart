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
    {'role':'ia','text':'Bienvenue dans la Ligue Panafricaine des Neurocitoyens 🧠\n\nJe suis ton guide IA. Je connais:\n1. La Charte (47 articles)\n2. Le Modèle Eco (6 revenus, 3 fonds 17%)\n3. Ton parcours (5 modules + Université)\n\nPose ta question!'},
  ];
  final ctrl=TextEditingController();
  bool loading=false;

  static const systemPrompt = '''
Tu es le Guide de la Ligue Panafricaine des Neurocitoyens (Ligue Africaine d'Aide Familiale).
Tu connais parfaitement:
- CHARTE 47 articles: Préambule Kouroukan Fouga, Titre I Nature (fédération Cités non lucratif, valeurs Conscience Compétence Engagement Impact), Titre II Membres 7 grades Aspirant Certifié Cadre Ambassadeur Bouleute Epimelete Mwalimu, Titre III Institutions 6 niveaux Ligue Mansa 1an, Région Ola 2ans, Cité Mwalimu 3ans, Nome Nomarque, Dème Demarque, Agora Agoranome tirage au sort + organes Forum Synedrion Boule Collège Epimelètes Aréopage Héliée Logistes, Titre IV Délibération Isegoria consensus vote quorum moitié, Titre V Ethique 10 engagements.
- MODELE ECO: 6 revenus 295,5M FCFA (Parcours 88,5M, Entreprise 72M, Ecole 27M, Label LEM-229 48M, WEMAN229 36M, AGORA78 18M, Observatoire 6M), 3 fonds fédéraux 17% (Ligue 8%, Solidarité 5% bourses 8000F, Initiatives 4% FAIN), 83% reste local, Tamias Logistes audit externe.
- PARCOURS: 5 modules M1 Conscience Identité M2 Compétence Citoyenne M3 Engagement M4 Leadership Ethique M5 Impact, QCM 85%, puis Université Continue formations Didascale Eco-Ambassadeur Gérant Coop Dev YetinApp Médiateur etc.

Ton: chaleureux, Coach Baobab, adapté Afrique, max 400 mots. Réponds en français.
''';

  Future<void> send(String t) async {
    if(t.trim().isEmpty || loading) return;
    setState((){
      chat.add({'role':'user','text':t});
      loading=true;
    });
    ctrl.clear();
    try {
      final res = await Supabase.instance.client.functions.invoke('ia-chat', body: {
        'prompt': t,
        'systemPrompt': systemPrompt,
        'history': chat.take(10).toList(),
      });
      final text = (res.data is Map? res.data['response'] : null)?.toString()?? res.data.toString();
      setState(()=> chat.add({'role':'ia','text': text}));
    } catch (e) {
      setState(()=> chat.add({'role':'ia','text': '⚠️ Erreur IA: $e\n\nDis-moi Charte / Modèle / Parcours et je t\'explique en local.'}));
    } finally {
      setState(()=> loading=false);
    }
  }

  @override
  Widget build(BuildContext context){
    return Scaffold(
      backgroundColor: const Color(0xFF080C1F),
      appBar: AppBar(backgroundColor: const Color(0xFF080C1F), title: const Text('IA Guide - Vraie IA', style: TextStyle(fontSize:12)), leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: ()=>context.go('/'))),
      body: Column(children:[
        Expanded(child: ListView.builder(padding: const EdgeInsets.all(12), itemCount: chat.length, itemBuilder: (c,i){
          var m=chat[i]; bool isUser=m['role']=='user';
          return Align(alignment: isUser? Alignment.centerRight: Alignment.centerLeft, child: Container(margin: const EdgeInsets.only(bottom:10), padding: const EdgeInsets.all(12), constraints: const BoxConstraints(maxWidth: 380), decoration: BoxDecoration(color: isUser? const Color(0xFFFFC400): const Color(0xFF101845), borderRadius: BorderRadius.circular(12)), child: Text(m['text']!, style: TextStyle(color: isUser? Colors.black: Colors.white70, fontSize:12))));
        })),
        if(loading) const LinearProgressIndicator(color: Color(0xFFFFC400)),
        Padding(padding: const EdgeInsets.all(12), child: Row(children:[Expanded(child: TextField(controller: ctrl, onSubmitted: send, style: const TextStyle(color: Colors.white, fontSize:12), decoration: InputDecoration(hintText: 'Pose ta vraie question à l\'IA...', hintStyle: const TextStyle(color: Colors.white38, fontSize:10), filled:true, fillColor: Colors.white.withOpacity(0.06), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)))), const SizedBox(width:8), IconButton.filled(onPressed: ()=>send(ctrl.text), icon: const Icon(Icons.send), style: IconButton.styleFrom(backgroundColor: const Color(0xFFFFC400), foregroundColor: Colors.black)) ])),
      ]),
    );
  }
}
