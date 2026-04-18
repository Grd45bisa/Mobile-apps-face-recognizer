import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/app_models.dart';
import 'supabase_client.dart';

class ReminderService {
  static final ReminderService instance = ReminderService._();
  ReminderService._();

  SupabaseClient get _db => SupabaseClientService.client;

  Future<List<ReminderEvent>> fetchTodayReminders(String employeeId) async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day).toUtc();
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59).toUtc();

    final data = await _db
        .from('reminder_events')
        .select()
        .eq('employee_id', employeeId)
        .gte('start_datetime', startOfDay.toIso8601String())
        .lte('start_datetime', endOfDay.toIso8601String())
        .order('start_datetime');
    return (data as List).map((r) => ReminderEvent.fromJson(r)).toList();
  }

  Future<List<ReminderEvent>> fetchMonthReminders(
    String employeeId,
    int year,
    int month,
  ) async {
    final from = DateTime(year, month, 1).toUtc();
    final to = DateTime(year, month + 1, 0, 23, 59, 59).toUtc();

    final data = await _db
        .from('reminder_events')
        .select()
        .eq('employee_id', employeeId)
        .gte('start_datetime', from.toIso8601String())
        .lte('start_datetime', to.toIso8601String())
        .order('start_datetime');
    return (data as List).map((r) => ReminderEvent.fromJson(r)).toList();
  }

  Future<List<ReminderEvent>> fetchRemindersInRange(
    String employeeId,
    DateTime from,
    DateTime to,
  ) async {
    final rangeStart = DateTime(from.year, from.month, from.day).toUtc();
    final rangeEnd = DateTime(to.year, to.month, to.day, 23, 59, 59).toUtc();

    final data = await _db
        .from('reminder_events')
        .select()
        .eq('employee_id', employeeId)
        .gte('start_datetime', rangeStart.toIso8601String())
        .lte('start_datetime', rangeEnd.toIso8601String())
        .order('start_datetime');

    return (data as List).map((r) => ReminderEvent.fromJson(r)).toList();
  }

  Future<ReminderEvent> upsertReminder(
    ReminderEvent event,
    String employeeId,
  ) async {
    final payload = event.toJson(employeeId: employeeId)
      ..['updated_at'] = DateTime.now().toUtc().toIso8601String();

    final result = await _db
        .from('reminder_events')
        .upsert(payload, onConflict: 'id')
        .select()
        .single();

    // Preserve local notificationIds — they are not stored in Supabase
    return ReminderEvent.fromJson(
      result,
    ).copyWith(notificationIds: event.notificationIds);
  }

  Future<void> deleteReminder(String id, String employeeId) async {
    await _db
        .from('reminder_events')
        .delete()
        .eq('id', id)
        .eq('employee_id', employeeId);
  }
}
