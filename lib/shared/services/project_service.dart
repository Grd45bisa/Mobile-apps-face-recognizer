import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/app_models.dart';
import 'supabase_client.dart';

class ProjectService {
  static final ProjectService instance = ProjectService._();
  ProjectService._();

  SupabaseClient get _db => SupabaseClientService.client;

  Future<List<Project>> fetchProjects(String employeeId) async {
    final data = await _db
        .from('projects')
        .select()
        .eq('employee_id', employeeId)
        .order('project_name');
    return (data as List).map((r) => Project.fromJson(r)).toList();
  }

  Future<Project> createProject(Project project, String employeeId) async {
    final payload = project.toJson(employeeId: employeeId)
      ..['created_at'] = DateTime.now().toUtc().toIso8601String()
      ..['updated_at'] = DateTime.now().toUtc().toIso8601String();

    final inserted = await _db
        .from('projects')
        .insert(payload)
        .select()
        .single();
    return Project.fromJson(inserted);
  }

  Future<Project> updateProject(Project project, String employeeId) async {
    final payload = project.toJson(employeeId: employeeId)
      ..['updated_at'] = DateTime.now().toUtc().toIso8601String();

    final updated = await _db
        .from('projects')
        .update(payload)
        .eq('id', project.id)
        .eq('employee_id', employeeId)
        .select()
        .single();
    return Project.fromJson(updated);
  }

  Future<void> deleteProject(String id, String employeeId) async {
    await _db
        .from('projects')
        .delete()
        .eq('id', id)
        .eq('employee_id', employeeId);
  }
}
