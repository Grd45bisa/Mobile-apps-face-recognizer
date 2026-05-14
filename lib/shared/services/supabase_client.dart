import 'package:supabase_flutter/supabase_flutter.dart';

// Supabase project credentials. Use the anon key in the client app.
// Never put the service role key in a Flutter client.
const String _supabaseUrl = 'https://wqeokmgvrrgrjtsnhisc.supabase.co';
const String _supabaseAnonKey =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6IndxZW9rbWd2cnJncmp0c25oaXNjIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzg3NTE0OTgsImV4cCI6MjA5NDMyNzQ5OH0.aqg_g51rbq5PVDfOqfOkBtJN4NgprOaSsSVpuO1hgE4';

class SupabaseClientService {
  static Future<void> initialize() async {
    await Supabase.initialize(url: _supabaseUrl, anonKey: _supabaseAnonKey);
  }

  static SupabaseClient get client => Supabase.instance.client;

  static String? get currentUserId => client.auth.currentUser?.id;

  static Stream<AuthState> get authStateChanges =>
      client.auth.onAuthStateChange;
}
