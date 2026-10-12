import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class IAGuideGlobal extends StatefulWidget {
  const IAGuideGlobal({super.key});
  @override
  State<IAGuideGlobal> createState()=> _IAGuideGlobalState();
}

class _IAGuideGlobalState extends State<IAGuideGlobal> {
  List<Map<String,String>> chat=[
    {'role':'ia','text':'Bienvenue dans la Ligue Panafricaine des Neurocitoyens 🧠\n\nJe suis ton guide IA depuis ton acces. Je vais t aider a comprendre :\n1. La Charte (47 articles, federation Cites)\n2. Le Modele Economique (6 revenus, 3 fonds 17%)\n3. Ton parcours : 5 modules puis universite continue\n\nTu veux commencer par quoi ? Dis : Charte, Modele Eco, ou Parcours'},
  ];
  final ctrl=TextEditingController();

  void send(String t){
    if(t.trim().isEmpty) return;
    setState((){
      chat.add({'role':'user','text':t});
      String lower=t.toLowerCase();
      if(lower.contains('charte')){
        chat.add({'role':'ia','text':'📜 CHARTE - Texte fondateur Oct 2026\n\nPreambule : federation de Cites au service dignite, tradition africaine charte et concertation (Kouroukan Fouga), institutions deliberation sans exclusions.\n\nTitre I : Nature - Ligue = federation Cites non lucratif. Valeurs : Conscience, Competence, Engagement, Impact.\n\nTitre II : Membres - 7 grades : Aspirant, Certifie, Cadre, Ambassadeur, Bouleute, Epimelete, Mwalimu. Droits : parole egale, vote, eligibilite selon grade. Devoirs : respecte Charte, participe Agora, cotisation, 1 action/an.\n\nTitre III : Institutions - 6 niveaux : Ligue Mansa (1 an non renouvelable, rotation regions), Region Ola (2 ans), Cite Mwalimu (3 ans), Nome Nomarque, Deme Demarque, Agora Agoranome (tirage au sort). Organes : Forum, Synedrion, Boule, College Epimeletes, Areopage (gardien Charte), Heliee (tribunal ethique tire au sort), Logistes (audit).\n\nTitre IV : Deliberation - Isegoria parole egale, consensus puis vote, quorum moitie actifs, roles seance tires au sort.\n\nTitre V : Ethique - 10 engagements : dire vrai, respecter personne, servir avant se servir, tenir engagements, rendre compte, transmettre, refuser corruption, proteger fragiles, declarer conflits, ne jamais monnayer influence.\n\nVeux-tu que je detaille un article ? Dis numero (ex: Article 20) ou demande Modele Eco'});
      } else if(lower.contains('modele') || lower.contains('economique') || lower.contains('eco')){
        chat.add({'role':'ia','text':'💰 MODELE ECONOMIQUE - Du reseau a la valeur, service rendu\n\n6 SOURCES REVENUS (Cite pilote annee 3) :\n1. Parcours Neurocitoyen : 88,5M FCFA\n2. Entreprise Neurocitoyenne : 72M\n3. Ecole NC Impact Enseignant : 27M\n4. Label LEM-229 : 48M\n5. Coaching WEMAN229 : 36M (2000F/mois)\n6. AGORA78 commissions 2% + vitrine : 18M\n7. Observatoire rapports : 6M\nTotal 295,5M\n\n3 FONDS FEDERAUX 17% recettes :\n- Ligue 8% : plateforme, certification, Logistes\n- Solidarite 5% : bourses, tarif solidaire 8000F\n- Initiatives locales 4% : projets Agoras, garantie prets (FAIN)\n83% reste local\n\nGouvernance financiere : Tamias tient comptes, double signature, Logistes independants, audit externe annuel, charte dons (aucun don achete influence).\n\nTaux autofinancement 38% an1 -> 92% an3, resultat 20,8M reinvesti.\n\nQuestion ? Dis tarif solidaire, fonds, ou Parcours'});
      } else if(lower.contains('parcours') || lower.contains('module')){
        chat.add({'role':'ia','text':'🎓 PARCOURS - Universite Panafricaine Continue\n\nDepart : 5 modules obligatoires pour devenir Neurocitoyen certifie (Aspirant Grade1 -> Certifie Grade2) :\nM1 Conscience & Identite, M2 Competence Citoyenne, M3 Engagement, M4 Leadership Ethique, M5 Impact Certification. QCM 85% pour valider suivant.\n\nApres 5 modules : tu es Grade2, tu vois formations et missions selon tes poles (1-2 choisis + interets elargis au-dela 21, on repartit dans 21 thematiques).\n\nUniversite continue : formations certifiantes et pro :\n- Didascale (formateur), Eco-Ambassadeur, Gerant Cooperative, Dev YetinApp, Mediateur Heliee, etc.\n- Chaque formation a prerequis, duree, certification\n\nVeux-tu commencer Module 1 maintenant ? Dis oui'});
      } else {
        chat.add({'role':'ia','text':'Merci pour ta question : "\$t"\n\nJe t aide avec Charte, Modele Eco, ou Parcours. Pose ta question autrement ou dis Charte / Modele / Parcours. Et n hesite pas a me poser des questions aussi !'});
      }
    });
  }

  @override
  Widget build(BuildContext context){
    return Scaffold(
      backgroundColor: const Color(0xFF080C1F),
      appBar: AppBar(backgroundColor: const Color(0xFF080C1F), title: const Text('IA Guide - Des ton acces, Charte & Modele Eco', style: TextStyle(fontSize:12)), leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: ()=>context.go('/'))),
      body: Column(children:[
        Expanded(child: ListView.builder(padding: const EdgeInsets.all(12), itemCount: chat.length, itemBuilder: (c,i){
          var m=chat[i]; bool isUser=m['role']=='user';
          return Align(alignment: isUser? Alignment.centerRight: Alignment.centerLeft, child: Container(margin: const EdgeInsets.only(bottom:10), padding: const EdgeInsets.all(12), constraints: const BoxConstraints(maxWidth: 380), decoration: BoxDecoration(color: isUser? const Color(0xFFFFC400): const Color(0xFF101845), borderRadius: BorderRadius.circular(12)), child: Text(m['text']!, style: TextStyle(color: isUser? Colors.black: Colors.white70, fontSize:12))));
        })),
        Padding(padding: const EdgeInsets.all(12), child: Row(children:[Expanded(child: TextField(controller: ctrl, onSubmitted: send, style: const TextStyle(color: Colors.white, fontSize:12), decoration: InputDecoration(hintText: 'Dis Charte, Modele Eco, Parcours, ou pose ta question...', hintStyle: const TextStyle(color: Colors.white38, fontSize:10), filled:true, fillColor: Colors.white.withOpacity(0.06), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)))), const SizedBox(width:8), IconButton.filled(onPressed: ()=>send(ctrl.text), icon: const Icon(Icons.send), style: IconButton.styleFrom(backgroundColor: const Color(0xFFFFC400), foregroundColor: Colors.black)) ])),
      ]),
    );
  }
}
