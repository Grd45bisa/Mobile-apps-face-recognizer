import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../supabase_client.dart';
import '../../database/embedding_db.dart';
import 'face_recognition_service.dart';

/// Syncs face embeddings between SQLite (local cache) and Supabase (cloud backup).
///
/// Table schema (run in Supabase SQL editor):
/// ```sql
/// CREATE TABLE face_embeddings (
///   employee_id  TEXT PRIMARY KEY REFERENCES employee_profiles(id) ON DELETE CASCADE,
///   embedding    TEXT NOT NULL,
///   updated_at   TIMESTAMPTZ NOT NULL DEFAULT NOW()
/// );
/// ALTER TABLE face_embeddings ENABLE ROW LEVEL SECURITY;
/// CREATE POLICY "employee_own" ON face_embeddings
///   USING (employee_id = auth.uid())
///   WITH CHECK (employee_id = auth.uid());
/// ```
class EmbeddingSyncService {
  static final EmbeddingSyncService instance = EmbeddingSyncService._();
  EmbeddingSyncService._();

  static const _table = 'face_embeddings';
  SupabaseClient get _client => SupabaseClientService.client;

  // ── Upload (enroll) ───────────────────────────────────────────────────────

  /// Save embedding to both SQLite and Supabase.
  Future<void> saveEmbedding(String employeeId, List<double> embedding) async {
    final normalized = FaceRecognitionService.normalizeEmbedding(embedding);

    // Always save locally first
    await EmbeddingDb.instance.upsert(employeeId, normalized);

    // Then sync to cloud
    await _client.from(_table).upsert({
      'employee_id': employeeId,
      'embedding': jsonEncode(normalized),
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  // ── Download (restore on new device) ─────────────────────────────────────

  /// Pull embedding from Supabase and cache it in SQLite.
  /// Call this when local cache is empty but user is authenticated.
  Future<List<double>?> fetchAndCacheEmbedding(String employeeId) async {
    final row = await _client
        .from(_table)
        .select('embedding')
        .eq('employee_id', employeeId)
        .maybeSingle();

    if (row == null) return null;

    final embedding = (jsonDecode(row['embedding'] as String) as List)
        .map((e) => (e as num).toDouble())
        .toList();
    final normalized = FaceRecognitionService.normalizeEmbedding(embedding);

    await EmbeddingDb.instance.upsert(employeeId, normalized);
    return normalized;
  }

  // ── Check enrollment status ───────────────────────────────────────────────

  /// Returns true if embedding exists in Supabase.
  Future<bool> isEnrolledOnCloud(String employeeId) async {
    final row = await _client
        .from(_table)
        .select('employee_id')
        .eq('employee_id', employeeId)
        .maybeSingle();
    return row != null;
  }

  // ── Get embedding (local-first, cloud fallback) ───────────────────────────

  /// Get embedding for current user — checks SQLite first, then Supabase.
  /// Returns null if not enrolled anywhere.
  Future<List<double>?> getEmbedding(String employeeId) async {
    // Try local cache first (fast path)
    final local = await EmbeddingDb.instance.get(employeeId);
    if (local != null) return local;

    // Fallback: pull from cloud and cache locally
    return fetchAndCacheEmbedding(employeeId);
  }

  // ── Delete (re-enrollment) ────────────────────────────────────────────────

  Future<void> deleteEmbedding(String employeeId) async {
    await EmbeddingDb.instance.delete(employeeId);
    await _client.from(_table).delete().eq('employee_id', employeeId);
  }
}
