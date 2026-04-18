import 'supabase_client.dart';

class TimerStateService {
  static final TimerStateService instance = TimerStateService._();
  TimerStateService._();

  final _db = SupabaseClientService.client;

  Future<DateTime?> fetchActiveTimer(String userId) async {
    final row = await _db
        .from('active_timers')
        .select('start_time')
        .eq('employee_id', userId)
        .maybeSingle();
    if (row == null) return null;
    return DateTime.parse(row['start_time'] as String);
  }

  Future<void> saveActiveTimer(String userId, DateTime startTime) async {
    await _db.from('active_timers').upsert({
      'employee_id': userId,
      'start_time': startTime.toUtc().toIso8601String(),
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }, onConflict: 'employee_id');
  }

  Future<void> clearActiveTimer(String userId) async {
    await _db.from('active_timers').delete().eq('employee_id', userId);
  }
}
