class L10n {
  static String _lang='fr';
  static String get lang=>_lang;
  static void setLang(String l){ _lang=l; }
  static const Map<String, Map<String,String>> _t={
    'fr':{'ligue':'LIGUE PANAFRICAINE DES NEUROCITOYENS','hero':'Conscience. Competence. Engagement. Impact.','rejoindre':'REJOINDRE MA CITE','carte':'CARTE 55 CITES','modules':'Modules','dashboard':'Tableau de Bord','admin':'Admin','forum':'Forums','banque':'Banque','coop':'Cooperatives','profil':'Profil','missions':'Missions','universite':'Universite Panafricaine','charte':'Charte','modele':'Modele Eco','bienvenue':'Bienvenue','search':'Rechercher...'},
    'en':{'ligue':'PAN-AFRICAN LEAGUE','hero':'Consciousness. Competence. Engagement. Impact.','rejoindre':'JOIN MY CITY','carte':'55 CITIES MAP','modules':'Modules','dashboard':'Dashboard','admin':'Admin','forum':'Forums','banque':'Bank','coop':'Cooperatives','profil':'Profile','missions':'Missions','universite':'Pan-African University','charte':'Charter','modele':'Eco Model','bienvenue':'Welcome','search':'Search...'},
  };
  static String t(String k)=> _t[_lang]?[k] ?? _t['fr']?[k] ?? k;
}
