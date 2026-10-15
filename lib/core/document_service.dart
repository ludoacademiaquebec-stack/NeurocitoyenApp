import 'package:supabase_flutter/supabase_flutter.dart';

/// Service unique pour lire Charte, Institutionnel et Modèle économique
/// depuis Supabase. Toutes les données sont en cache 10 min.
class DocumentService {
  static SupabaseClient get _db => Supabase.instance.client;

  // ===========================================================================
  // CHARTE
  // ===========================================================================
  static Map<String, dynamic>? _charteCache;
  static DateTime? _charteDate;

  static Future<Map<String, dynamic>> loadCharte({bool force = false}) async {
    if (!force && _charteCache != null && _charteDate != null) {
      if (DateTime.now().difference(_charteDate!).inMinutes < 10) {
        return _charteCache!;
      }
    }
    try {
      final titres = await _db
          .from('charte_titres')
          .select()
          .eq('actif', true)
          .order('numero_ordre');
      final articles = await _db
          .from('charte_articles')
          .select()
          .eq('actif', true)
          .order('numero');
      final annexes = await _db
          .from('charte_annexes')
          .select()
          .eq('actif', true)
          .order('lettre');
      final historique = await _db
          .from('charte_historique')
          .select()
          .order('date_adoption', ascending: false);

      final result = {
        'titres': List<Map<String, dynamic>>.from(titres),
        'articles': List<Map<String, dynamic>>.from(articles),
        'annexes': List<Map<String, dynamic>>.from(annexes),
        'historique': List<Map<String, dynamic>>.from(historique),
      };
      _charteCache = result;
      _charteDate = DateTime.now();
      return result;
    } catch (e) {
      return _charteCache ??
          {'titres': [], 'articles': [], 'annexes': [], 'historique': []};
    }
  }

  // ===========================================================================
  // INSTITUTIONNEL
  // ===========================================================================
  static Map<String, dynamic>? _instCache;
  static DateTime? _instDate;

  static Future<Map<String, dynamic>> loadInstitutions(
      {bool force = false}) async {
    if (!force && _instCache != null && _instDate != null) {
      if (DateTime.now().difference(_instDate!).inMinutes < 10) {
        return _instCache!;
      }
    }
    try {
      final sections = await _db
          .from('institutions_sections')
          .select()
          .eq('actif', true)
          .order('numero_ordre');
      final niveaux = await _db
          .from('institutions_niveaux')
          .select()
          .eq('actif', true)
          .order('numero');
      final poles = await _db
          .from('institutions_poles_officiels')
          .select()
          .eq('actif', true)
          .order('numero');
      final grades = await _db
          .from('institutions_grades')
          .select()
          .eq('actif', true)
          .order('numero');

      final result = {
        'sections': List<Map<String, dynamic>>.from(sections),
        'niveaux': List<Map<String, dynamic>>.from(niveaux),
        'poles': List<Map<String, dynamic>>.from(poles),
        'grades': List<Map<String, dynamic>>.from(grades),
      };
      _instCache = result;
      _instDate = DateTime.now();
      return result;
    } catch (e) {
      return _instCache ??
          {'sections': [], 'niveaux': [], 'poles': [], 'grades': []};
    }
  }

  // ===========================================================================
  // MODÈLE ÉCONOMIQUE
  // ===========================================================================
  static Map<String, dynamic>? _ecoCache;
  static DateTime? _ecoDate;

  static Future<Map<String, dynamic>> loadModeleEco({bool force = false}) async {
    if (!force && _ecoCache != null && _ecoDate != null) {
      if (DateTime.now().difference(_ecoDate!).inMinutes < 10) {
        return _ecoCache!;
      }
    }
    try {
      final sections = await _db
          .from('modele_eco_sections')
          .select()
          .eq('actif', true)
          .order('numero_ordre');
      final sources = await _db
          .from('modele_eco_sources_revenus')
          .select()
          .eq('actif', true)
          .order('numero');
      final flux = await _db
          .from('modele_eco_flux_federaux')
          .select()
          .eq('actif', true)
          .order('ordre');
      final previsions = await _db
          .from('modele_eco_previsions')
          .select()
          .eq('actif', true)
          .order('ordre');

      final result = {
        'sections': List<Map<String, dynamic>>.from(sections),
        'sources': List<Map<String, dynamic>>.from(sources),
        'flux': List<Map<String, dynamic>>.from(flux),
        'previsions': List<Map<String, dynamic>>.from(previsions),
      };
      _ecoCache = result;
      _ecoDate = DateTime.now();
      return result;
    } catch (e) {
      return _ecoCache ??
          {'sections': [], 'sources': [], 'flux': [], 'previsions': []};
    }
  }

  // ===========================================================================
  // VERSIONS DES DOCUMENTS
  // ===========================================================================
  static Future<List<Map<String, dynamic>>> listVersions() async {
    try {
      final res = await _db
          .from('documents_versions')
          .select()
          .order('document')
          .order('version', ascending: false);
      return List<Map<String, dynamic>>.from(res);
    } catch (_) {
      return [];
    }
  }

  // ===========================================================================
  // IMAGES DU DOCUMENT INSTITUTIONNEL
  // ===========================================================================
  static Future<List<Map<String, dynamic>>> loadInstitutionImages() async {
    try {
      final res = await _db
          .from('institutions_images')
          .select()
          .eq('actif', true)
          .order('ordre');
      return List<Map<String, dynamic>>.from(res);
    } catch (_) {
      return [];
    }
  }
}
