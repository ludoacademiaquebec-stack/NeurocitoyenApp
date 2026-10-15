import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';

class AiService {
  static SupabaseClient get _db => Supabase.instance.client;

  // Appel centralisé vers la Edge Function Groq
  static Future<String> _callGroq({required String systemPrompt, required String userPrompt, double temperature=0.7}) async {
    try {
      final res = await _db.functions.invoke('ia-chat', body: {
        'prompt': userPrompt,
        'systemPrompt': systemPrompt,
        'message': userPrompt,
        'ia_type': 'GUIDE',
        'temperature': temperature,
      });
      final data = res.data;
      if (data is Map) {
        return (data['response']?? data['reponse']?? data['text']?? '').toString();
      }
      return data.toString();
    } catch (e) {
      throw Exception('IA indisponible: $e');
    }
  }

  static Future<String> genererContenuModule({required Map<String, dynamic> module, required Map<String, dynamic>? apprenant}) async {
    final systemPrompt = module['ia_prompt_systeme']?.toString()?? 'Tu es Coach Baobab, coach neurocitoyen bienveillant, chaleureux, africain. Max 600 mots.';
    final contenuRef = module['ia_contenu_reference']?.toString()?? '';
    final titre = module['titre']?? '';
    final sousTitre = module['sous_titre']?? '';
    final prenom = apprenant?['prenoms']?? apprenant?['pseudo']?? 'ami';
    final userPrompt = '''
Module: $titre - $sousTitre
Contenu ref: $contenuRef
Objectifs: ${_formaterObjectifs(module['ia_objectifs'])}
Apprenant: $prenom

Présente le module en 3-4 paragraphes clairs, exemples africains concrets, termine par 2-3 questions ouvertes. Ton chaleureux.
''';
    return await _callGroq(systemPrompt: systemPrompt, userPrompt: userPrompt, temperature: 0.8);
  }

  static Future<Map<String, dynamic>> genererQuiz({required Map<String, dynamic> module, required Map<String, dynamic>? apprenant}) async {
    final systemPrompt = module['ia_prompt_systeme']?.toString()?? 'Tu es Coach Baobab. Génère UNIQUEMENT du JSON valide.';
    final nbQuestions = module['ia_nb_questions']?? 5;
    final userPrompt = '''
Génère un quiz de $nbQuestions questions sur "${module['titre']}".

Contenu: ${module['ia_contenu_reference']?? ''}
Objectifs: ${_formaterObjectifs(module['ia_objectifs'])}

Format JSON STRICT uniquement:
{
  "questions": [
    {
      "id": 1,
      "question": "Question?",
      "options": [{"id":"a","texte":"A"},{"id":"b","texte":"B"},{"id":"c","texte":"C"},{"id":"d","texte":"D"}],
      "bonne_reponse": "a",
      "explication": "Explication"
    }
  ]
}
''';
    final raw = await _callGroq(systemPrompt: systemPrompt, userPrompt: userPrompt, temperature: 1.0);
    var cleaned = raw.trim();
    if (cleaned.contains('```')) {
      cleaned = cleaned.replaceAll(RegExp(r'```json?'), '').replaceAll('```', '').trim();
    }
    final start = cleaned.indexOf('{');
    final end = cleaned.lastIndexOf('}');
    if (start!= -1 && end!= -1) cleaned = cleaned.substring(start, end+1);
    final data = jsonDecode(cleaned);
    return Map<String, dynamic>.from(data);
  }

  static Future<Map<String, dynamic>> evaluerQuiz({required Map<String, dynamic> module, required Map<String, dynamic> quiz, required Map<String, String> reponses, required Map<String, dynamic>? apprenant}) async {
    final questions = quiz['questions'] as List;
    int bonnes=0; final details=<Map<String,dynamic>>[];
    for (final q in questions) {
      final qid=q['id']?.toString()??'';
      final bonne=q['bonne_reponse']?.toString()??'';
      final repondu=reponses[qid]??'';
      final correct=repondu==bonne;
      if(correct) bonnes++;
      details.add({'question_id':qid,'question':q['question'],'repondu':repondu,'bonne':bonne,'correct':correct,'explication':q['explication']??''});
    }
    final score=questions.isEmpty?0:((bonnes/questions.length)*100).round();
    final seuil=module['ia_seuil']??85;
    final valide=score>=seuil;

    String feedback='';
    try{
      feedback=await _callGroq(systemPrompt: module['ia_prompt_systeme']?.toString()??'Tu es Coach Baobab bienveillant.', userPrompt: 'Score: $score% seuil $seuil% ${valide?"VALIDE":"NON VALIDE"}. Génère feedback chaleureux max 150 mots.', temperature: 0.8);
    }catch(_){
      feedback=valide?'Bravo, tu as validé! 🎉':'Presque! Réessaie, tu es sur la bonne voie.';
    }

    return {'score':score,'seuil':seuil,'valide':valide,'bonnes_reponses':bonnes,'total':questions.length,'details':details,'feedback':feedback};
  }

  static Future<String> repondreQuestion({required Map<String, dynamic> module, required String questionApprenant, required List<Map<String, String>> historique, Map<String, dynamic>? apprenant}) async {
    final systemPrompt=module['ia_prompt_systeme']?.toString()??'Tu es Coach Baobab, coach neurocitoyen bienveillant.';
    final buf=StringBuffer();
    buf.writeln('MODULE: ${module['titre']}');
    buf.writeln('REF: ${module['ia_contenu_reference']??"—"}');
    buf.writeln('APPRENANT: ${apprenant?['prenoms']??"ami"}');
    for(final m in historique){ buf.writeln('${m['role']}: ${m['contenu']}'); }
    buf.writeln('NOUVELLE QUESTION: $questionApprenant');
    buf.writeln('Réponds chaleureusement max 300 mots.');
    return await _callGroq(systemPrompt: systemPrompt, userPrompt: buf.toString(), temperature: 0.8);
  }

  // Sauvegardes
  static Future<void> sauvegarderConversation({required String userId, required String moduleId, required String moduleType, required String role, required String contenu}) async {
    try{ await _db.from('ia_conversations').insert({'user_id':userId,'module_id':moduleId,'module_type':moduleType,'role':role,'contenu':contenu}); }catch(_){}
  }
  static Future<void> sauvegarderTentativeQuiz({required String userId, required String moduleId, required String moduleType, required Map<String, dynamic> quiz, required Map<String, String> reponses, required Map<String, dynamic> resultat}) async {
    try{ await _db.from('ia_quiz_tentatives').insert({'user_id':userId,'module_id':moduleId,'module_type':moduleType,'questions':quiz['questions'],'reponses':reponses,'score':resultat['score'],'seuil':resultat['seuil'],'valide':resultat['valide'],'feedback_ia':resultat['feedback']}); }catch(_){}
  }
  static Future<List<Map<String, dynamic>>> chargerHistorique({required String userId, required String moduleId, required String moduleType}) async {
    try{
      final res=await _db.from('ia_conversations').select().eq('user_id',userId).eq('module_id',moduleId).eq('module_type',moduleType).order('created_at');
      return List<Map<String, dynamic>>.from(res);
    }catch(_){ return []; }
  }

  static String _formaterObjectifs(dynamic o){ if(o==null) return '—'; if(o is List) return o.map((e)=>'• $e').join('\n'); return o.toString(); }
}
