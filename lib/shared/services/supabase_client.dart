import 'package:supabase_flutter/supabase_flutter.dart';

// Supabase project credentials — replace with your project's values from
// https://supabase.com/dashboard/project/<your-project>/settings/api
const String _supabaseUrl = 'https://ykqdacxjwvfuxpzmeuqu.supabase.co';
const String _supabaseAnonKey =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InlrcWRhY3hqd3ZmdXhwem1ldXF1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzc3ODY4MzQsImV4cCI6MjA5MzM2MjgzNH0.gKwCtfV3j_dESLx3_j7On3W_FZ-VMK7K6QdfA0ERqnM';

const String supabaseRoleKey =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InlrcWRhY3hqd3ZmdXhwem1ldXF1Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc3Nzc4NjgzNCwiZXhwIjoyMDkzMzYyODM0fQ.x99EyX0svLa0i8vJcvnCipMgmgGcAKicFtqyyWRlkYQ';

class SupabaseClientService {
  static Future<void> initialize() async {
    await Supabase.initialize(url: _supabaseUrl, anonKey: _supabaseAnonKey);
  }

  static SupabaseClient get client => Supabase.instance.client;

  static String? get currentUserId => client.auth.currentUser?.id;

  static Stream<AuthState> get authStateChanges =>
      client.auth.onAuthStateChange;
}
