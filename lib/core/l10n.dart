import 'package:flutter/material.dart';
class L10n {
  static String _lang='fr';
  static String get lang=>_lang;
  static void setLang(String v)=>_lang=v;
  static String tr(BuildContext c,String k)=>t(k);
  static String t(String k){
    const m={'ligue':'LIGUE PANAFRICAINE','hero_title':'Ligue Panafricaine des Neurocitoyens','hero_subtitle':'Une federation de Cites','cta_join':'Rejoindre','cta_explore':'Explorer','poles_title':'Les Poles','poles_subtitle':'Expertises','rejoindre':'REJOINDRE'};
    return m[k]??k;
  }
}
