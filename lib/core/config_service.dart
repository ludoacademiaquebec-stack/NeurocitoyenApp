import 'package:supabase_flutter/supabase_flutter.dart';

class ConfigService {
  static SupabaseClient get _db => Supabase.instance.client;
  static Map<String, String>? _cache;
  static DateTime? _cacheDate;

  static Future<Map<String, String>> loadAll({bool force = false}) async {
    if (!force && _cache != null && _cacheDate != null) {
      if (DateTime.now().difference(_cacheDate!).inMinutes < 5) return _cache!;
    }
    try {
      final res = await _db.from('config_ligue').select();
      final map = <String, String>{};
      for (final row in res) {
        map[row['cle'] as String] = (row['valeur'] ?? '').toString();
      }
      _cache = map;
      _cacheDate = DateTime.now();
      return map;
    } catch (_) {
      return _cache ?? {};
    }
  }

  static Future<String> get(String cle, {String fallback = ''}) async {
    final all = await loadAll();
    return all[cle] ?? fallback;
  }

  static Future<int> getPrix(String cle, {int fallback = 0}) async {
    final v = await get(cle);
    return int.tryParse(v) ?? fallback;
  }

  static Future<bool> getBool(String cle, {bool fallback = false}) async {
    final v = await get(cle);
    return v.toLowerCase() == 'true';
  }

  static String formatPrix(int montant, {String devise = 'FCFA'}) {
    if (montant == 0) return 'Gratuit';
    final str = montant.toString();
    final buf = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) buf.write(' ');
      buf.write(str[i]);
    }
    return '${buf.toString()} $devise';
  }
}
