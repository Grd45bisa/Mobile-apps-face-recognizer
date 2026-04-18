import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/app_models.dart';
import 'supabase_client.dart';

class ScheduleSettingsService {
  static final ScheduleSettingsService instance = ScheduleSettingsService._();
  ScheduleSettingsService._();

  SupabaseClient get _db => SupabaseClientService.client;

  Future<WorkScheduleSettings> fetchSettings(String employeeId) async {
    final data = await _db
        .from('work_schedule_settings')
        .select()
        .eq('employee_id', employeeId)
        .maybeSingle();

    return data != null
        ? WorkScheduleSettings.fromJson(data)
        : WorkScheduleSettings.defaults();
  }

  Future<void> saveSettings(
    String employeeId,
    WorkScheduleSettings settings,
  ) async {
    final payload = settings.toJson(employeeId: employeeId)
      ..['updated_at'] = DateTime.now().toUtc().toIso8601String();

    await _db
        .from('work_schedule_settings')
        .upsert(payload, onConflict: 'employee_id');
  }
}
