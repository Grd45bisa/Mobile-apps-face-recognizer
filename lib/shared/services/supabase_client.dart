import 'package:supabase_flutter/supabase_flutter.dart';

// Supabase project credentials — replace with your project's values from
// https://supabase.com/dashboard/project/<your-project>/settings/api
const String _supabaseUrl = 'https://ueugwxcksmbscxacajpu.supabase.co';
const String _supabaseAnonKey =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InVldWd3eGNrc21ic2N4YWNhanB1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzY1MDc5MTcsImV4cCI6MjA5MjA4MzkxN30.nBPagbp7Tkb9MFPiQ4oGatP7AZbZuchNMVEjSVICaf8';

const String supabaseRoleKey =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InVldWd3eGNrc21ic2N4YWNhanB1Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc3NjUwNzkxNywiZXhwIjoyMDkyMDgzOTE3fQ.S9NZ-Z4YlyaBIwr5Dtqn6ZwwW60KR-pZuWClwHzxac8';

class SupabaseClientService {
  static Future<void> initialize() async {
    await Supabase.initialize(url: _supabaseUrl, anonKey: _supabaseAnonKey);
  }

  static SupabaseClient get client => Supabase.instance.client;

  static String? get currentUserId => client.auth.currentUser?.id;

  static Stream<AuthState> get authStateChanges =>
      client.auth.onAuthStateChange;
}
