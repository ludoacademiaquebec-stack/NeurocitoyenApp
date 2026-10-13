// lib/core/supabase_config.dart
// ⚠️ NE PAS COMMIT AVEC LES VRAIES CLÉS — utilise --dart-define en prod
class SupabaseConfig {
  static const String url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://VOTRE_PROJET.supabase.co',
  );
  static const String anonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6IndncXdwdWNjcmxwemN6bXFrcGV5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTE3MjQ2MjEsImV4cCI6MjEwNzMwMDYyMX0.PqaOiODKuEYR8HNAwT2RmhFYYqkZ73dM3j6lbR4cmmQ',
  );
}