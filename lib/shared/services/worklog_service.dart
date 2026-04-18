import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/app_models.dart';
import 'supabase_client.dart';

class WorklogService {
  static final WorklogService instance = WorklogService._();
  WorklogService._();

  SupabaseClient get _db => SupabaseClientService.client;

  Future<List<WorklogEntry>> fetchDayWorklogs(
    String employeeId,
    DateTime date,
  ) async {
    final dateStr = _dateStr(date);
    final data = await _db
        .from('worklog_entries')
        .select()
        .eq('employee_id', employeeId)
        .eq('date', dateStr)
        .order('start_time');
    return (data as List).map((r) => WorklogEntry.fromJson(r)).toList();
  }

  Future<List<WorklogEntry>> fetchMonthWorklogs(
    String employeeId,
    int year,
    int month,
  ) async {
    final from = '$year-${month.toString().padLeft(2, '0')}-01';
    final lastDay = DateTime(year, month + 1, 0).day;
    final to =
        '$year-${month.toString().padLeft(2, '0')}-${lastDay.toString().padLeft(2, '0')}';

    final data = await _db
        .from('worklog_entries')
        .select()
        .eq('employee_id', employeeId)
        .gte('date', from)
        .lte('date', to)
        .order('date')
        .order('start_time');
    return (data as List).map((r) => WorklogEntry.fromJson(r)).toList();
  }

  Future<List<WorklogEntry>> fetchWorklogsInRange(
    String employeeId,
    DateTime from,
    DateTime to,
  ) async {
    final fromStr = _dateStr(from);
    final toStr = _dateStr(to);

    final data = await _db
        .from('worklog_entries')
        .select()
        .eq('employee_id', employeeId)
        .gte('date', fromStr)
        .lte('date', toStr)
        .order('date', ascending: false)
        .order('start_time', ascending: false);
    return (data as List).map((r) => WorklogEntry.fromJson(r)).toList();
  }

  Future<WorklogEntry> createWorklog(
    WorklogEntry entry,
    String employeeId,
  ) async {
    final payload = entry.toJson(employeeId: employeeId)
      ..['created_at'] = DateTime.now().toUtc().toIso8601String()
      ..['updated_at'] = DateTime.now().toUtc().toIso8601String();

    final inserted = await _db
        .from('worklog_entries')
        .insert(payload)
        .select()
        .single();
    return WorklogEntry.fromJson(inserted);
  }

  Future<WorklogEntry> updateWorklog(
    WorklogEntry entry,
    String employeeId,
  ) async {
    final payload = entry.toJson(employeeId: employeeId)
      ..['updated_at'] = DateTime.now().toUtc().toIso8601String();

    final updated = await _db
        .from('worklog_entries')
        .update(payload)
        .eq('id', entry.id)
        .eq('employee_id', employeeId)
        .select()
        .single();
    return WorklogEntry.fromJson(updated);
  }

  Future<void> deleteWorklog(String id, String employeeId) async {
    await _db
        .from('worklog_entries')
        .delete()
        .eq('id', id)
        .eq('employee_id', employeeId);
  }

  static String _dateStr(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
