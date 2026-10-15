import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

class AiService {
  static const String _apiKey = String.fromEnvironment(
    'GEMINI_API_KEY',
    defaultValue: '',
  );

  static const List<String> _modelesFallback = [
    'gemini-flash-lite-latest',
    'gemini-flash-latest',
    'gemini-3.8-flash',
    'gemini-3.7-flash',
    'gemini-3.6-flash',
  ];

  static const String _baseUrlPattern =
      'https://generativelanguage.googleapis.com/v1beta/models';

  static SupabaseClient get _db => Supabase.instance.client;

  static Future<String> _appelGemini({
    required String promptSysteme,
    required String promptUser,
    double temperature = 0.7,
    int maxTokens = 2048,
  }) async {
    if (_apiKey.isEmpty) {
      throw Exception('Clé API Gemini manquante.');
    }

    // Essayer chaque modèle en fallback
    Exception? derniereErreur;
    for (final modele in _modelesFallback) {
      try {
        return await _appelGeminiModele(
          modele: modele,
          promptSysteme: promptSysteme,
          promptUser: promptUser,
          temperature: temperature,
          maxTokens: maxTokens,
        );
      } catch (e) {
        derniereErreur = e is Exception ? e : Exception(e.toString());
        // Si erreur 404 ou 503, on essaie le modèle suivant
        if (e.toString().contains('404') ||
            e.toString().contains('503') ||
            e.toString().contains('UNAVAILABLE')) {
          continue;
        }
        // Autre erreur → on arrête
        rethrow;
      }
    }
    throw derniereErreur ?? Exception('Tous les modèles IA sont indisponibles');
  }

  static Future<String> _appelGeminiModele({
    required String modele,
    required String promptSysteme,
    required String promptUser,
    double temperature = 0.7,
    int maxTokens = 2048,
  }) async {
    final url = Uri.parse('$_baseUrlPattern/$modele:generateContent?key=$_apiKey');

    // Gemini 3.5 Flash Lite ne supporte pas system_instruction → on fusionne
    final promptComplet = '$promptSysteme\n\n---\n\n$promptUser';

    final body = jsonEncode({
      'contents': [
        {
          'role': 'user',
          'parts': [{'text': promptComplet}]
        }
      ],
      'generationConfig': {
        'temperature': temperature,
        'maxOutputTokens': maxTokens,
      },
    });

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: body,
    );

    if (response.statusCode != 200) {
      throw Exception('Erreur API Gemini : ${response.statusCode}');
    }

    final data = jsonDecode(response.body);
    final candidates = data['candidates'];
    if (candidates == null || candidates.isEmpty) {
      throw Exception('Réponse vide');
    }

    final parts = candidates[0]['content']['parts'];
    if (parts == null || parts.isEmpty) {
      throw Exception('Pas de contenu');
    }

    return parts[0]['text']?.toString() ?? '';
  }

  static Future<String> genererContenuModule({
    required Map<String, dynamic> module,
    required Map<String, dynamic>? apprenant,
  }) async {
    final promptSysteme = module['ia_prompt_systeme']?.toString() ??
        'Tu es Coach Baobab, un coach neurocitoyen bienveillant et pédagogue.';

    final contenuRef = module['ia_contenu_reference']?.toString() ?? '';
    final objectifs = module['ia_objectifs'];
    final titre = module['titre'] ?? '';
    final sousTitre = module['sous_titre'] ?? '';

    String contexteApprenant = '';
    if (apprenant != null) {
      final prenom = apprenant['prenoms'] ?? apprenant['pseudo'] ?? 'ami';
      final pays = apprenant['pays_id'] ?? '';
      contexteApprenant = 'Prénom : $prenom\nPays : $pays';
    }

    final promptUser = '''
Présente le module suivant à un apprenant :

Titre : $titre
Sous-titre : $sousTitre

Points clés :
$contenuRef

Objectifs :
${_formaterObjectifs(objectifs)}

Contexte apprenant :
$contexteApprenant

Instructions :
1. Accroche chaleureuse personnalisée
2. Présente en 3-4 paragraphes clairs
3. Exemples concrets adaptés au contexte africain
4. Termine par 2-3 questions ouvertes
5. Ton chaleureux et encourageant

Réponds en français. Maximum 600 mots.
''';

    return await _appelGemini(
      promptSysteme: promptSysteme,
      promptUser: promptUser,
      temperature: 0.8,
      maxTokens: 2048,
    );
  }

  static Future<Map<String, dynamic>> genererQuiz({
    required Map<String, dynamic> module,
    required Map<String, dynamic>? apprenant,
  }) async {
    final promptSysteme = module['ia_prompt_systeme']?.toString() ??
        'Tu es Coach Baobab, un coach neurocitoyen.';

    final contenuRef = module['ia_contenu_reference']?.toString() ?? '';
    final objectifs = module['ia_objectifs'];
    final nbQuestions = module['ia_nb_questions'] ?? 5;
    final titre = module['titre'] ?? '';

    final promptUser = '''
Génère un quiz de $nbQuestions questions sur le module "$titre".

Contenu de référence :
$contenuRef

Objectifs :
${_formaterObjectifs(objectifs)}

Format attendu : JSON STRICT (aucun texte avant/après) :

{
  "questions": [
    {
      "id": 1,
      "question": "Question ?",
      "options": [
        {"id": "a", "texte": "Option A"},
        {"id": "b", "texte": "Option B"},
        {"id": "c", "texte": "Option C"},
        {"id": "d", "texte": "Option D"}
      ],
      "bonne_reponse": "a",
      "explication": "Explication"
    }
  ]
}

Règles :
1. Questions variées (QCM, mise en situation)
2. 4 options par question
3. Une seule bonne réponse
4. Testent la COMPRÉHENSION
5. Vocabulaire adapté au contexte africain
6. Questions DIFFÉRENTES à chaque appel

Réponds UNIQUEMENT avec le JSON.
''';

    final reponse = await _appelGemini(
      promptSysteme: promptSysteme,
      promptUser: promptUser,
      temperature: 1.0,
      maxTokens: 3000,
    );

    var cleaned = reponse.trim();
    if (cleaned.startsWith('```json')) cleaned = cleaned.substring(7);
    if (cleaned.startsWith('```')) cleaned = cleaned.substring(3);
    if (cleaned.endsWith('```')) cleaned = cleaned.substring(0, cleaned.length - 3);
    cleaned = cleaned.trim();

    final data = jsonDecode(cleaned);
    return Map<String, dynamic>.from(data);
  }

  static Future<Map<String, dynamic>> evaluerQuiz({
    required Map<String, dynamic> module,
    required Map<String, dynamic> quiz,
    required Map<String, String> reponses,
    required Map<String, dynamic>? apprenant,
  }) async {
    final questions = quiz['questions'] as List;
    int bonnes = 0;
    final details = <Map<String, dynamic>>[];

    for (final q in questions) {
      final qid = q['id']?.toString() ?? '';
      final bonne = q['bonne_reponse']?.toString() ?? '';
      final repondu = reponses[qid] ?? '';
      final correct = repondu == bonne;

      if (correct) bonnes++;

      details.add({
        'question_id': qid,
        'question': q['question'],
        'repondu': repondu,
        'bonne': bonne,
        'correct': correct,
        'explication': q['explication'] ?? '',
      });
    }

    final score = questions.isEmpty
        ? 0
        : ((bonnes / questions.length) * 100).round();
    final seuil = module['ia_seuil'] ?? 85;
    final valide = score >= seuil;

    final promptSysteme = module['ia_prompt_systeme']?.toString() ??
        'Tu es Coach Baobab, un coach neurocitoyen bienveillant.';

    String feedback = '';
    try {
      final promptUser = '''
Score : $score% (seuil : $seuil%)
Résultat : ${valide ? "VALIDÉ" : "NON VALIDÉ"}

Génère un feedback chaleureux (max 150 mots) :
- Si validé : félicite
- Si non validé : encourage
''';

      feedback = await _appelGemini(
        promptSysteme: promptSysteme,
        promptUser: promptUser,
        temperature: 0.8,
        maxTokens: 500,
      );
    } catch (_) {
      feedback = valide
          ? 'Bravo, tu as validé !'
          : 'Presque ! Réessaie.';
    }

    return {
      'score': score,
      'seuil': seuil,
      'valide': valide,
      'bonnes_reponses': bonnes,
      'total': questions.length,
      'details': details,
      'feedback': feedback,
    };
  }

  static Future<void> sauvegarderConversation({
    required String userId,
    required String moduleId,
    required String moduleType,
    required String role,
    required String contenu,
  }) async {
    try {
      await _db.from('ia_conversations').insert({
        'user_id': userId,
        'module_id': moduleId,
        'module_type': moduleType,
        'role': role,
        'contenu': contenu,
      });
    } catch (_) {}
  }

  static Future<void> sauvegarderTentativeQuiz({
    required String userId,
    required String moduleId,
    required String moduleType,
    required Map<String, dynamic> quiz,
    required Map<String, String> reponses,
    required Map<String, dynamic> resultat,
  }) async {
    try {
      await _db.from('ia_quiz_tentatives').insert({
        'user_id': userId,
        'module_id': moduleId,
        'module_type': moduleType,
        'questions': quiz['questions'],
        'reponses': reponses,
        'score': resultat['score'],
        'seuil': resultat['seuil'],
        'valide': resultat['valide'],
        'feedback_ia': resultat['feedback'],
      });
    } catch (_) {}
  }

  static String _formaterObjectifs(dynamic objectifs) {
    if (objectifs == null) return '—';
    if (objectifs is List) {
      return objectifs.map((o) => '• $o').join('\n');
    }
    return objectifs.toString();
  }

  // ===========================================================================
  // CHAT INTERACTIF AVEC LE COACH
  // ===========================================================================
  static Future<String> repondreQuestion({
    required Map<String, dynamic> module,
    required String questionApprenant,
    required List<Map<String, String>> historique,
    Map<String, dynamic>? apprenant,
  }) async {
    final promptSysteme = module['ia_prompt_systeme']?.toString() ??
        'Tu es Coach Baobab, un coach neurocitoyen bienveillant et pédagogue.';

    // Construire le contexte
    String contexteApprenant = '';
    if (apprenant != null) {
      final prenom = apprenant['prenoms'] ?? apprenant['pseudo'] ?? 'ami';
      contexteApprenant = 'Prénom de l\'apprenant : $prenom';
    }

    // Construire l'historique
    final buffer = StringBuffer();
    buffer.writeln('MODULE EN COURS : ${module['titre']}');
    buffer.writeln('CONTENU DE RÉFÉRENCE :');
    buffer.writeln(module['ia_contenu_reference'] ?? '—');
    buffer.writeln('');
    buffer.writeln(contexteApprenant);
    buffer.writeln('');
    buffer.writeln('HISTORIQUE DE LA CONVERSATION :');

    for (final msg in historique) {
      final role = msg['role'] ?? '';
      final contenu = msg['contenu'] ?? '';
      buffer.writeln('$role: $contenu');
    }

    buffer.writeln('');
    buffer.writeln('NOUVELLE QUESTION DE L\'APPRENANT :');
    buffer.writeln(questionApprenant);
    buffer.writeln('');
    buffer.writeln('Réponds à la question de manière chaleureuse et pédagogique (max 300 mots). '
        'Si l\'apprenant répond à une question que tu as posée, félicite et approfondis. '
        'Si la question est hors-sujet, redirige doucement vers le module.');

    return await _appelGemini(
      promptSysteme: promptSysteme,
      promptUser: buffer.toString(),
      temperature: 0.8,
      maxTokens: 1500,
    );
  }

  // ===========================================================================
  // CHARGER L'HISTORIQUE D'UN MODULE
  // ===========================================================================
  static Future<List<Map<String, dynamic>>> chargerHistorique({
    required String userId,
    required String moduleId,
    required String moduleType,
  }) async {
    try {
      final res = await _db
          .from('ia_conversations')
          .select()
          .eq('user_id', userId)
          .eq('module_id', moduleId)
          .eq('module_type', moduleType)
          .order('created_at');
      return List<Map<String, dynamic>>.from(res);
    } catch (_) {
      return [];
    }
  }
}
