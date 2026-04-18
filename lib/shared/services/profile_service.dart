import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/app_models.dart';
import 'supabase_client.dart';

class ProfileService {
  static final ProfileService instance = ProfileService._();
  ProfileService._();

  SupabaseClient get _db => SupabaseClientService.client;

  Future<EmployeeProfile> fetchProfile(String employeeId) async {
    final data = await _db
        .from('profiles')
        .select()
        .eq('id', employeeId)
        .single();
    return EmployeeProfile.fromJson(data);
  }

  Future<void> updateProfile(EmployeeProfile profile) async {
    await _db.from('profiles').update({
      'full_name': profile.fullName,
      'avatar_url': profile.avatarUrl,
      'department': profile.department,
      'position': profile.position,
      'phone_number': profile.phoneNumber,
      'notifications_enabled': profile.notificationsEnabled,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', profile.id);
  }

  /// Creates profile row if not yet exists (called on first login).
  Future<EmployeeProfile> ensureProfileExists(User user) async {
    final existing = await _db
        .from('profiles')
        .select()
        .eq('id', user.id)
        .maybeSingle();

    if (existing != null) return EmployeeProfile.fromJson(existing);

    final payload = {
      'id': user.id,
      'full_name': user.userMetadata?['full_name'] as String? ?? user.email ?? '',
      'email': user.email ?? '',
      'created_at': DateTime.now().toUtc().toIso8601String(),
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };
    final inserted = await _db
        .from('profiles')
        .insert(payload)
        .select()
        .single();
    return EmployeeProfile.fromJson(inserted);
  }
}
