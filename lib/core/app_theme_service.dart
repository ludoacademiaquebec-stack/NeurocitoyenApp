import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Service central de thème.
/// Charge les couleurs depuis la table Supabase `app_theme` au démarrage.
/// Si Supabase est indisponible, utilise les valeurs BIIC par défaut.
class AppThemeService {
  static AppThemeService? _instance;
  static AppThemeService get instance => _instance ??= AppThemeService._();
  AppThemeService._();

  final Map<String, Color> _couleurs = {
    'nuit':    const Color(0xFF0B2B2F),
    'nuit2':   const Color(0xFF0E3A3D),
    'nuit3':   const Color(0xFF071D20),
    'or':      const Color(0xFFE0A82E),
    'orClair': const Color(0xFFF0BD4A),
    'vert':    const Color(0xFF1D7A52),
    'teal':    const Color(0xFF2F7D6D),
    'violet':  const Color(0xFF7A4E8C),
    'rouge':   const Color(0xFFB4473A),
    'ivoire':  const Color(0xFFF2F6F4),
    'encre':   const Color(0xFF10201F),
    'texte':   const Color(0xFF4A5A57),
  };

  bool _loaded = false;
  bool get isLoaded => _loaded;

  Color get(String nom) => _couleurs[nom] ?? Colors.white;

  Color get nuit    => get('nuit');
  Color get nuit2   => get('nuit2');
  Color get nuit3   => get('nuit3');
  Color get or      => get('or');
  Color get orClair => get('orClair');
  Color get vert    => get('vert');
  Color get teal    => get('teal');
  Color get violet  => get('violet');
  Color get rouge   => get('rouge');
  Color get ivoire  => get('ivoire');
  Color get encre   => get('encre');
  Color get texte   => get('texte');

  /// Charge les couleurs depuis Supabase. À appeler une fois au démarrage.
  Future<void> load() async {
    try {
      final rows = await Supabase.instance.client.from('app_theme').select();
      for (final row in rows) {
        final nom = row['nom'] as String?;
        final hex = row['valeur'] as String?;
        if (nom != null && hex != null) {
          final c = _parseHex(hex);
          if (c != null) _couleurs[nom] = c;
        }
      }
      _loaded = true;
    } catch (_) {
      _loaded = true;
    }
  }

  /// Force le rechargement (après édition admin).
  Future<void> reload() async {
    _loaded = false;
    await load();
  }

  /// Met à jour une couleur en local (optimistic UI).
  void setLocal(String nom, Color c) {
    _couleurs[nom] = c;
  }

  Color? _parseHex(String hex) {
    var h = hex.trim();
    if (h.startsWith('#')) h = h.substring(1);
    if (h.length == 6) h = 'FF$h';
    if (h.length != 8) return null;
    final v = int.tryParse(h, radix: 16);
    if (v == null) return null;
    return Color(v);
  }

  String toHex(Color c) {
    return '#${c.toARGB32().toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';
  }
}
