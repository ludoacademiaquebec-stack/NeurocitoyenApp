// lib/core/supabase_config.dart
// ⚠️ L'URL et la clé anon sont PUBLIQUES (protégées par RLS Supabase).
// En production, la clé anon est injectée via --dart-define dans GitHub Actions.
class SupabaseConfig {
  static const String url = 'https://wgqwpuccrlpzczmqkpey.supabase.co';

  static const String anonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6IndncXdwdWNjcmxwemN6bXFrcGV5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTE3MjQ2MjEsImV4cCI6MjEwNzMwMDYyMX0.PqaOiODKuEYR8HNAwT2RmhFYYqkZ73dM3j6lbR4cmmQ', // ← COLLE ICI la clé anon pour le dev local
  );
}