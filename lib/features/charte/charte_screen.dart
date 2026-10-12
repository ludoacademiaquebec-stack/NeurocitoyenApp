import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../widgets/app_scaffold.dart';

class CharteScreen extends StatelessWidget {
  const CharteScreen({super.key});
  @override
  Widget build(BuildContext context){
    return AppScaffold(
      title: 'Charte - Texte Fondateur',
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children:[
          Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: const Color(0xFF101845), borderRadius: BorderRadius.circular(12)), child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children:[
            Text('Charte de la Ligue Panafricaine des Neurocitoyens', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize:14)),
            SizedBox(height:4),
            Text('Version 1.0 Octobre 2026 - 47 articles, 10 engagements ethiques', style: TextStyle(color: Color(0xFFFFC400), fontSize:11)),
            SizedBox(height:8),
            Text('Preambule : federation de Cites au service dignite, tradition africaine charte et concertation (Kouroukan Fouga), institutions deliberation sans exclusions. Education, integrite, solidarite fondement action.', style: TextStyle(color: Colors.white70, fontSize:11)),
          ])),
          const SizedBox(height:12),
          _article('Titre I - Dispositions generales','Article 1 Nature : Ligue = federation Cites non lucratif\nArt 2 Valeurs : Conscience, Competence, Engagement, Impact\nArt 3 Missions : forme, certifie, ethique, initiative locale\nArt 4 Neutralite : independant partis, titres internes\nArt 5 Federation et autonomie : chaque Cite gere affaires cadre Charte\nArt 6 Langues et emblemes'),
          _article('Titre II - Membres','Art 7 Qualite : toute personne majeure adherant Charte, grades 7\nArt 8 Droits : parole egale, vote, eligibilite selon grade, formation\nArt 9 Devoirs : respecte Charte, participe Agora, cotisation, confidentialite\nArt 10 Membre actif : a jour cotisation, 2/3 assemblees Agora, 1 action/an\nArt 11 Absences, Art 12 Perte qualite par demission/radiation Heliee'),
          _article('Titre III - Institutions','Art 13 Architecture 6 niveaux\nArt 14 Forum assemblee pleniere\nArt 15 Synedrion delegues + Boule Bouleutes\nArt 16 College Epimeletes executif, Epistate coordonne, chaque Epimelete rend compte trimestre\nArt 17 Areopage gardien Charte\nArt 18 Heliee tribunal ethique tire au sort Cadre+\nArt 19 Logistes audit impact independants\nArt 20 Dirigeants mandats : Mansa 1 an non renouvelable rotation regions, Ola 2 ans, Mwalimu 3 ans, Nomarque/Demarque 2 ans, Agoranome tirage au sort 1 an\nArt 21 Eligibilite limites, Art 22 Vacance revocation 1/5 motion 2/3'),
          _article('Titre IV - Fonctionnement','Art 23 Deliberation isegoria parole egale, consensus puis vote\nArt 24 Quorum moitie actifs, majorite simple, Charte 2/3\nArt 25 Roles seance tires au sort Porte-parole, Gardien preuve/temps, Contradicteur\nArt 26 Transparence Grammate actes 15j\nArt 27 Redevabilite euthyna devant Areopage'),
          _article('Titre V - Ethique et discipline','Art 28 Code ethique 10 engagements annexe B\nArt 29 Sanctions graduees rappel, avertissement, suspension 12 mois, radiation\nArt 30 Procedure equitable contradictoire\nArt 31 Conflits interets\nArt 32 Alerte protection\nArt 33 Protection personnes harcelement interdit\nArt 34 Egalite inclusion 40% chaque sexe'),
          _article('Titre VI - Principes financiers','Art 35 But non lucratif\nArt 36 Interdiction remuneration au recrutement\nArt 37 Service rendu tarif publie\nArt 38 Prix publics + tarif solidaire\nArt 39 Transparence financiere Tamias double signature\nArt 40 Dons et partenariats charte acceptation\nArt 41 Fonds mutualises redevance 8% Ligue + 5% solidarite + 4% initiatives'),
          _article('Annexe B - 10 engagements','1 Dire vrai\n2 Respecter chaque personne\n3 Servir avant se servir\n4 Tenir engagements\n5 Rendre compte\n6 Transmettre ce qu on recoit\n7 Refuser corruption\n8 Proteger plus fragiles\n9 Declarer conflits interets\n10 Ne jamais monnayer influence'),
          const SizedBox(height:12),
          SizedBox(width: double.infinity, child: ElevatedButton.icon(icon: const Icon(Icons.smart_toy, size:16), label: const Text('Comprendre Charte avec IA Guide'), style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFFC400), foregroundColor: Colors.black), onPressed: ()=>context.go('/ia-guide'))),
        ]),
      ),
    );
  }
  Widget _article(String titre, String contenu)=> Container(margin: const EdgeInsets.only(bottom:10), padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(10)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children:[Text(titre, style: const TextStyle(color: Color(0xFFFFC400), fontWeight: FontWeight.bold, fontSize:12)), const SizedBox(height:6), Text(contenu, style: const TextStyle(color: Colors.white70, fontSize:11))]));
}
