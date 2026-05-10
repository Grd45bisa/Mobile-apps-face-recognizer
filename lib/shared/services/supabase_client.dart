import 'package:supabase_flutter/supabase_flutter.dart';

// Supabase project credentials. Use the anon key in the client app.
// Never put the service role key in a Flutter client.
const String _supabaseUrl = 'https://ykqdacxjwvfuxpzmeuqu.supabase.co';
const String _supabaseAnonKey =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InlrcWRhY3hqd3ZmdXhwem1ldXF1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzc3ODY4MzQsImV4cCI6MjA5MzM2MjgzNH0.gKwCtfV3j_dESLx3_j7On3W_FZ-VMK7K6QdfA0ERqnM';

class SupabaseClientService {
  static Future<void> initialize() async {
    await Supabase.initialize(url: _supabaseUrl, anonKey: _supabaseAnonKey);
  }

  static SupabaseClient get client => Supabase.instance.client;

  static String? get currentUserId => client.auth.currentUser?.id;

  static Stream<AuthState> get authStateChanges =>
      client.auth.onAuthStateChange;
}
