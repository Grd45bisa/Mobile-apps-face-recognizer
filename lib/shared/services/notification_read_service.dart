import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_client.dart';

class NotificationReadService {
  static final NotificationReadService instance = NotificationReadService._();
  NotificationReadService._();

  SupabaseClient get _db => SupabaseClientService.client;

  Future<Set<String>> fetchReadIds(String employeeId) async {
    final data = await _db
        .from('notification_reads')
        .select('notification_id')
        .eq('employee_id', employeeId);

    return (data as List)
        .map((row) => row['notification_id'] as String?)
        .whereType<String>()
        .toSet();
  }

  Future<void> markRead(String employeeId, String notificationId) async {
    await _db.from('notification_reads').upsert({
      'employee_id': employeeId,
      'notification_id': notificationId,
      'read_at': DateTime.now().toUtc().toIso8601String(),
    }, onConflict: 'employee_id,notification_id');
  }

  Future<void> markAllRead(
    String employeeId,
    Iterable<String> notificationIds,
  ) async {
    final now = DateTime.now().toUtc().toIso8601String();
    final rows = notificationIds.map((id) {
      return {'employee_id': employeeId, 'notification_id': id, 'read_at': now};
    }).toList();

    if (rows.isEmpty) return;
    await _db
        .from('notification_reads')
        .upsert(rows, onConflict: 'employee_id,notification_id');
  }
}
