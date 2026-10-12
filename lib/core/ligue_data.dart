import 'package:flutter/material.dart';
import 'dart:math';

enum RegionUA { nord, ouest, centre, est, australe }

class Cite {
  final String id, nom, capitale, flag;
  final RegionUA region;
  const Cite({required this.id, required this.nom, required this.capitale, required this.flag, required this.region});
}

class PoleAction {
  final int numero;
  final String nom;
  final String institutions;
  final IconData icon;
  final List<String> formations;
  final List<String> missions;
  final List<String> interetsElargis;
  const PoleAction({required this.numero, required this.nom, required this.institutions, required this.icon, this.formations=const [], this.missions=const [], this.interetsElargis=const []});
}

class Grade {
  final int numero;
  final String titre, etape, fonctions, description;
  const Grade({required this.numero, required this.titre, required this.etape, required this.fonctions, this.description=''});
}

class Lecon {
  final String titre;
  final String contenuIA;
  final List<String> questionsIA;
  const Lecon({required this.titre, required this.contenuIA, required this.questionsIA});
}

class ModuleFormation {
  final int numero;
  final String titre;
  final String objectif;
  final List<Lecon> lecons;
  final List<Map<String,dynamic>> qcm;
  const ModuleFormation({required this.numero, required this.titre, required this.objectif, required this.lecons, required this.qcm});
}

class FormationContinue {
  final String id, titre, description, niveau, duree, certification;
  final int poleNumero;
  final List<String> prerequis;
  const FormationContinue({required this.id, required this.titre, required this.description, required this.niveau, required this.duree, required this.certification, required this.poleNumero, this.prerequis=const []});
}

class LigueData {
  static String genererCodeParrain(String paysId) {
    var rnd = Random();
    var lettres = String.fromCharCodes(List.generate(4, (i)=> rnd.nextInt(26)+65));
    var chiffres = rnd.nextInt(9000)+1000;
    return paysId + '-' + lettres + '-' + chiffres.toString();
  }

  static const List<Cite> cites = [
    Cite(id: 'DZ', nom: 'Algerie', capitale: 'Alger', flag: '🇩🇿', region: RegionUA.nord),
    Cite(id: 'EG', nom: 'Egypte', capitale: 'Le Caire', flag: '🇪🇬', region: RegionUA.nord),
    Cite(id: 'LY', nom: 'Libye', capitale: 'Tripoli', flag: '🇱🇾', region: RegionUA.nord),
    Cite(id: 'MA', nom: 'Maroc', capitale: 'Rabat', flag: '🇲🇦', region: RegionUA.nord),
    Cite(id: 'MR', nom: 'Mauritanie', capitale: 'Nouakchott', flag: '🇲🇷', region: RegionUA.nord),
    Cite(id: 'EH', nom: 'Sahara occidental', capitale: 'Laayoune', flag: '🇪🇭', region: RegionUA.nord),
    Cite(id: 'TN', nom: 'Tunisie', capitale: 'Tunis', flag: '🇹🇳', region: RegionUA.nord),
    Cite(id: 'BJ', nom: 'Benin', capitale: 'Porto-Novo', flag: '🇧🇯', region: RegionUA.ouest),
    Cite(id: 'BF', nom: 'Burkina Faso', capitale: 'Ouagadougou', flag: '🇧🇫', region: RegionUA.ouest),
    Cite(id: 'CV', nom: 'Cabo Verde', capitale: 'Praia', flag: '🇨🇻', region: RegionUA.ouest),
    Cite(id: 'CI', nom: "Cote d'Ivoire", capitale: 'Yamoussoukro', flag: '🇨🇮', region: RegionUA.ouest),
    Cite(id: 'GM', nom: 'Gambie', capitale: 'Banjul', flag: '🇬🇲', region: RegionUA.ouest),
    Cite(id: 'GH', nom: 'Ghana', capitale: 'Accra', flag: '🇬🇭', region: RegionUA.ouest),
    Cite(id: 'GN', nom: 'Guinee', capitale: 'Conakry', flag: '🇬🇳', region: RegionUA.ouest),
    Cite(id: 'GW', nom: 'Guinee-Bissau', capitale: 'Bissau', flag: '🇬🇼', region: RegionUA.ouest),
    Cite(id: 'LR', nom: 'Liberia', capitale: 'Monrovia', flag: '🇱🇷', region: RegionUA.ouest),
    Cite(id: 'ML', nom: 'Mali', capitale: 'Bamako', flag: '🇲🇱', region: RegionUA.ouest),
    Cite(id: 'NE', nom: 'Niger', capitale: 'Niamey', flag: '🇳🇪', region: RegionUA.ouest),
    Cite(id: 'NG', nom: 'Nigeria', capitale: 'Abuja', flag: '🇳🇬', region: RegionUA.ouest),
    Cite(id: 'SN', nom: 'Senegal', capitale: 'Dakar', flag: '🇸🇳', region: RegionUA.ouest),
    Cite(id: 'SL', nom: 'Sierra Leone', capitale: 'Freetown', flag: '🇸🇱', region: RegionUA.ouest),
    Cite(id: 'TG', nom: 'Togo', capitale: 'Lome', flag: '🇹🇬', region: RegionUA.ouest),
    Cite(id: 'BI', nom: 'Burundi', capitale: 'Gitega', flag: '🇧🇮', region: RegionUA.centre),
    Cite(id: 'CM', nom: 'Cameroun', capitale: 'Yaounde', flag: '🇨🇲', region: RegionUA.centre),
    Cite(id: 'CF', nom: 'Centrafrique', capitale: 'Bangui', flag: '🇨🇫', region: RegionUA.centre),
    Cite(id: 'CG', nom: 'Congo', capitale: 'Brazzaville', flag: '🇨🇬', region: RegionUA.centre),
    Cite(id: 'CD', nom: 'RD Congo', capitale: 'Kinshasa', flag: '🇨🇩', region: RegionUA.centre),
    Cite(id: 'GA', nom: 'Gabon', capitale: 'Libreville', flag: '🇬🇦', region: RegionUA.centre),
    Cite(id: 'GQ', nom: 'Guinee equatoriale', capitale: 'Malabo', flag: '🇬🇶', region: RegionUA.centre),
    Cite(id: 'ST', nom: 'Sao Tome', capitale: 'Sao Tome', flag: '🇸🇹', region: RegionUA.centre),
    Cite(id: 'TD', nom: 'Tchad', capitale: 'Ndjamena', flag: '🇹🇩', region: RegionUA.centre),
    Cite(id: 'KM', nom: 'Comores', capitale: 'Moroni', flag: '🇰🇲', region: RegionUA.est),
    Cite(id: 'DJ', nom: 'Djibouti', capitale: 'Djibouti', flag: '🇩🇯', region: RegionUA.est),
    Cite(id: 'ER', nom: 'Erythree', capitale: 'Asmara', flag: '🇪🇷', region: RegionUA.est),
    Cite(id: 'ET', nom: 'Ethiopie', capitale: 'Addis-Abeba', flag: '🇪🇹', region: RegionUA.est),
    Cite(id: 'KE', nom: 'Kenya', capitale: 'Nairobi', flag: '🇰🇪', region: RegionUA.est),
    Cite(id: 'MG', nom: 'Madagascar', capitale: 'Antananarivo', flag: '🇲🇬', region: RegionUA.est),
    Cite(id: 'MU', nom: 'Maurice', capitale: 'Port-Louis', flag: '🇲🇺', region: RegionUA.est),
    Cite(id: 'RW', nom: 'Rwanda', capitale: 'Kigali', flag: '🇷🇼', region: RegionUA.est),
    Cite(id: 'SC', nom: 'Seychelles', capitale: 'Victoria', flag: '🇸🇨', region: RegionUA.est),
    Cite(id: 'SO', nom: 'Somalie', capitale: 'Mogadiscio', flag: '🇸🇴', region: RegionUA.est),
    Cite(id: 'SD', nom: 'Soudan', capitale: 'Khartoum', flag: '🇸🇩', region: RegionUA.est),
    Cite(id: 'SS', nom: 'Soudan du Sud', capitale: 'Djouba', flag: '🇸🇸', region: RegionUA.est),
    Cite(id: 'TZ', nom: 'Tanzanie', capitale: 'Dodoma', flag: '🇹🇿', region: RegionUA.est),
    Cite(id: 'UG', nom: 'Ouganda', capitale: 'Kampala', flag: '🇺🇬', region: RegionUA.est),
    Cite(id: 'AO', nom: 'Angola', capitale: 'Luanda', flag: '🇦🇴', region: RegionUA.australe),
    Cite(id: 'BW', nom: 'Botswana', capitale: 'Gaborone', flag: '🇧🇼', region: RegionUA.australe),
    Cite(id: 'SZ', nom: 'Eswatini', capitale: 'Mbabane', flag: '🇸🇿', region: RegionUA.australe),
    Cite(id: 'LS', nom: 'Lesotho', capitale: 'Maseru', flag: '🇱🇸', region: RegionUA.australe),
    Cite(id: 'MW', nom: 'Malawi', capitale: 'Lilongwe', flag: '🇲🇼', region: RegionUA.australe),
    Cite(id: 'MZ', nom: 'Mozambique', capitale: 'Maputo', flag: '🇲🇿', region: RegionUA.australe),
    Cite(id: 'NA', nom: 'Namibie', capitale: 'Windhoek', flag: '🇳🇦', region: RegionUA.australe),
    Cite(id: 'ZA', nom: 'Afrique du Sud', capitale: 'Pretoria', flag: '🇿🇦', region: RegionUA.australe),
    Cite(id: 'ZM', nom: 'Zambie', capitale: 'Lusaka', flag: '🇿🇲', region: RegionUA.australe),
    Cite(id: 'ZW', nom: 'Zimbabwe', capitale: 'Harare', flag: '🇿🇼', region: RegionUA.australe),
    Cite(id: 'HT', nom: 'Haiti (Diaspora)', capitale: 'Port-au-Prince', flag: '🇭🇹', region: RegionUA.ouest),
  ];

  static const List<PoleAction> poles = [
    PoleAction(numero: 1, nom: 'Formation, certification, sciences neurocitoyennes', institutions: 'ANECI, CNCN, CFN, CLFS, CIRN', icon: Icons.school, formations: ['Devenir Didascale', 'Certification ANECI', 'Mwalimu Pedagogie'], missions: ['Former 10 Aspirants'], interetsElargis: ['Neurosciences', 'Pedagogie Mwalimu']),
    PoleAction(numero: 2, nom: 'Metiers, excellence professionnelle, label', institutions: 'LEM-229, IFPI, ANAPROBAR', icon: Icons.workspace_premium, formations: ['Label Excellence LEM-229'], missions: ['Auditer 5 artisans'], interetsElargis: ['Artisanat', 'Qualite']),
    PoleAction(numero: 3, nom: 'Economie solidaire, cooperatives, entrepreneuriat', institutions: 'FAIN, ININ, RNCEN, ANCDP', icon: Icons.handshake, formations: ['Creer cooperative', 'Entrepreneuriat social'], missions: ['Accompagner 3 porteurs'], interetsElargis: ['Microfinance', 'ESS']),
    PoleAction(numero: 4, nom: 'Finances, budget, planification strategique', institutions: 'BCN, Tamias, Logistes', icon: Icons.account_balance, formations: ['Gestion Tamias', 'Audit Logistes'], missions: ['Audit comptes Cite']),
    PoleAction(numero: 5, nom: 'Culture, arts, cinema, festivals', institutions: 'Festivals, Maison du Cinema', icon: Icons.theater_comedy),
    PoleAction(numero: 6, nom: 'Numerique, innovation, connectivite', institutions: 'ATCN, PNN, NeuroCite, YetinApp', icon: Icons.computer, formations: ['YetinApp Dev', 'NeuroCite'], interetsElargis: ['IA', 'Blockchain', 'Dev Web']),
    PoleAction(numero: 7, nom: 'Mobilisation, communication, medias', institutions: 'ANMN, CLM, ANAReS', icon: Icons.campaign),
    PoleAction(numero: 8, nom: 'Territoires, decentralisation, gouvernance locale', institutions: 'ANSMFC, Forums', icon: Icons.map),
    PoleAction(numero: 9, nom: 'Affaires sociales, famille, bien-etre', institutions: 'PABE, ArtHum', icon: Icons.favorite),
    PoleAction(numero: 10, nom: 'Agriculture, souverainete alimentaire, economie verte', institutions: 'Cantine Apro, Ecole Apro', icon: Icons.agriculture),
    PoleAction(numero: 11, nom: 'Infrastructures, equipements, services collectifs', institutions: 'Modules classe, kiosques', icon: Icons.build),
    PoleAction(numero: 12, nom: 'Jeunesse, sports, olympiades', institutions: 'Nouvel Heritage, Olympiades', icon: Icons.sports_soccer),
    PoleAction(numero: 13, nom: 'Ethique, justice citoyenne, integrite', institutions: 'Heliee, mediateurs, Charte', icon: Icons.balance, formations: ['Heliastes', 'Ethique'], missions: ['Medier conflit']),
    PoleAction(numero: 14, nom: 'Partenariats strategiques, rayonnement international', institutions: 'RPAN, CAN, CIFORCE, Proxenes', icon: Icons.public),
    PoleAction(numero: 15, nom: 'Education nationale, alphabetisation', institutions: 'Programme Ecole NC', icon: Icons.menu_book),
    PoleAction(numero: 16, nom: 'Sante publique, hygiene', institutions: 'Cliniques communautaires', icon: Icons.local_hospital),
    PoleAction(numero: 17, nom: 'Energie, mines, hydrocarbures', institutions: 'Energies renouvelables', icon: Icons.bolt),
    PoleAction(numero: 18, nom: 'Environnement, climat, developpement durable', institutions: 'Climat, Agenda 2030', icon: Icons.eco, formations: ['Eco-Ambassadeur', 'Climat'], missions: ['Planter 100 arbres'], interetsElargis: ['Ecologie', 'Recyclage', 'Permaculture']),
    PoleAction(numero: 19, nom: 'Tourisme, artisanat, loisirs', institutions: 'Circuits touristiques', icon: Icons.luggage),
    PoleAction(numero: 20, nom: 'Fonction publique, travail, protection sociale', institutions: 'Emploi, protection sociale', icon: Icons.work),
    PoleAction(numero: 21, nom: 'Habitat, urbanisme, cadre de vie', institutions: 'Logement social, eco-quartiers', icon: Icons.home_work),
  ];

  static const List<Grade> grades = [
    Grade(numero: 1, titre: 'Aspirant', etape: 'Modules 1 a 5', fonctions: 'Membre Agora', description: 'Debutant, en formation initiale'),
    Grade(numero: 2, titre: 'Neurocitoyen certifie', etape: 'Certification 5 modules', fonctions: 'Agoranome, delegue', description: 'Certifie apres 5 modules, peut tirer au sort'),
    Grade(numero: 3, titre: 'Cadre', etape: '6 mois consolidation', fonctions: 'Demarque, Didascale', description: 'Cadre actif, parrain, projet'),
    Grade(numero: 4, titre: 'Ambassadeur', etape: 'Forme Cadres', fonctions: 'Nomarque, Proxene', description: 'Ambassadeur rayonnement'),
    Grade(numero: 5, titre: 'Bouleute', etape: 'Reconnaissance Cite', fonctions: 'Boule', description: 'Membre Boule'),
    Grade(numero: 6, titre: 'Epimelete', etape: 'Pilote pole', fonctions: 'College Epimeletes', description: 'Ministre pole'),
    Grade(numero: 7, titre: 'Mwalimu', etape: 'Autorite morale', fonctions: 'President Cite, eligible Ola puis Mansa', description: 'President Cite'),
  ];

  static const List<ModuleFormation> modules = [
    ModuleFormation(
      numero: 1,
      titre: 'Module 1 - Conscience & Identite Panafricaine',
      objectif: 'Comprendre histoire, Charte Kouroukan Fouga, 7 principes',
      lecons: [
        Lecon(titre: 'Charte Kouroukan Fouga', contenuIA: 'L Empire du Mali, 1236, Mande, charte orale 44 articles. Valeurs : dignite, solidarite. Questionne utilisateur.', questionsIA: ['Que sais-tu de la Charte de Kouroukan Fouga ?', 'Pourquoi charte orale plus forte qu ecrite ?']),
        Lecon(titre: '7 principes fondateurs', contenuIA: 'Federation, Charte, Subsidiarite, Consensus, Rotation, Redevabilite, Inclusion. Explique chaque.', questionsIA: ['Quel principe te parle le plus ?', 'Subsidiarite dans ton quartier ?']),
        Lecon(titre: 'Republique vs Cite', contenuIA: 'Republique = Etat central. Cite = communaute autonome federee. Ligue = federation Cites.', questionsIA: ['Difference Republique et Cite ?']),
        Lecon(titre: '6 niveaux', contenuIA: 'Ligue Mansa, Region Ola, Cite Mwalimu, Nome Nomarque, Deme Demarque, Agora Agoranome.', questionsIA: ['A quel niveau veux-tu agir ?']),
      ],
      qcm: [
        {'q': 'Charte Kouroukan Fouga vient de quel empire ?', 'options': ['Ghana', 'Mali', 'Songhai'], 'bonne': 1},
        {'q': 'Combien principes fondateurs ?', 'options': ['5', '7', '10'], 'bonne': 1},
        {'q': 'Qui preside Ligue ?', 'options': ['Mwalimu', 'Mansa', 'Nomarque'], 'bonne': 1},
        {'q': 'Agora frequence ?', 'options': ['Hebdo', 'Mensuelle', 'Annuelle'], 'bonne': 1},
        {'q': 'Tirage au sort ?', 'options': ['Isegoria', 'Kleroterion', 'Euthyna'], 'bonne': 1},
      ],
    ),
    ModuleFormation(numero: 2, titre: 'Module 2 - Competence Citoyenne & Droit', objectif: 'Maitriser organes', lecons: [Lecon(titre: '8 organes', contenuIA: 'Forum, Synedrion, Boule, College Epimeletes, Areopage, Heliee, Logistes, Proxenes, Didascales. Details.', questionsIA: ['Cite organe tribunal ?'])], qcm: [{'q':'Forum = ?', 'options':['Executif','Assemblee pleniere','Tresorier'],'bonne':1}]),
    ModuleFormation(numero: 3, titre: 'Module 3 - Engagement Communautaire', objectif: 'Agir Agora', lecons: [Lecon(titre: 'Animer Agora', contenuIA: 'Methode Agoranome, quetes, cartographie besoins.', questionsIA: ['As-tu anime reunion ?'])], qcm: [{'q':'Agoranome comment ?', 'options':['Elu','Tirage au sort','Nomme'],'bonne':1}]),
    ModuleFormation(numero: 4, titre: 'Module 4 - Leadership & Ethique', objectif: 'Devenir Cadre', lecons: [Lecon(titre: 'Grades', contenuIA: 'Parcours 1 a 7, rotation, redevabilite, ethique.', questionsIA: ['Quel grade vises-tu ?'])], qcm: [{'q':'Grade 1 ?', 'options':['Aspirant','Mwalimu','Epimelete'],'bonne':0}]),
    ModuleFormation(numero: 5, titre: 'Module 5 - Impact & Certification', objectif: 'Certification', lecons: [Lecon(titre: 'Certification', contenuIA: 'Epreuves, projet communautaire, Didascale, Bouleute.', questionsIA: ['Pret pour projet ?'])], qcm: [{'q':'Apres 5 modules ?', 'options':['Aspirant','Neurocitoyen certifie','Mansa'],'bonne':1}]),
  ];

  static const List<FormationContinue> formationsContinues = [
    FormationContinue(id: 'F6-01', titre: 'Devenir Didascale - Formateur Neurocitoyen', description: 'Pedagogie Mwalimu, animer modules', niveau: 'Avance', duree: '3 mois', certification: 'Didascale', poleNumero: 1, prerequis: ['Modules 1-5']),
    FormationContinue(id: 'F18-01', titre: 'Eco-Ambassadeur Climat', description: 'Sensibilisation climat, 100 arbres', niveau: 'Intermediaire', duree: '2 mois', certification: 'Eco-Ambassadeur', poleNumero: 18),
    FormationContinue(id: 'F3-01', titre: 'Creer sa Cooperative', description: 'Statuts, FAIN, business model', niveau: 'Avance', duree: '4 mois', certification: 'Gerant Cooperative', poleNumero: 3),
    FormationContinue(id: 'F6-02', titre: 'Developpeur YetinApp', description: 'App mobile Ligue, PNN', niveau: 'Expert', duree: '6 mois', certification: 'Dev YetinApp', poleNumero: 6),
    FormationContinue(id: 'F13-01', titre: 'Mediation et Heliee', description: 'Justice citoyenne, mediation', niveau: 'Avance', duree: '2 mois', certification: 'Mediateur', poleNumero: 13),
  ];

  static Cite getCite(String id) => cites.firstWhere((c) => c.id == id, orElse: () => cites.firstWhere((c) => c.id == 'BJ'));
  static List<Cite> byRegion(RegionUA r) => cites.where((c) => c.region == r).toList();
}
