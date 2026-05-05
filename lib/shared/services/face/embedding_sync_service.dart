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
///
/// The `embedding` column stores either a single embedding JSON array (v1)
/// or a JSON array-of-arrays for multi-pose enrollment (v2). Decoder is
/// shape-aware so existing v1 rows keep working.
class EmbeddingSyncService {
  static final EmbeddingSyncService instance = EmbeddingSyncService._();
  EmbeddingSyncService._();

  static const _table = 'face_embeddings';
  SupabaseClient get _client => SupabaseClientService.client;

  // ── Upload (enroll) ───────────────────────────────────────────────────────

  /// Save a single embedding to both SQLite and Supabase.
  /// Kept for backward compatibility — prefer [saveEmbeddings] for multi-pose.
  Future<void> saveEmbedding(String employeeId, List<double> embedding) async {
    final normalized = FaceRecognitionService.normalizeEmbedding(embedding);

    await EmbeddingDb.instance.upsert(employeeId, normalized);

    await _client.from(_table).upsert({
      'employee_id': employeeId,
      'embedding': jsonEncode(normalized),
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  /// Save multiple embeddings (one per pose) for stronger matching.
  /// Each embedding is L2-normalized before storage.
  Future<void> saveEmbeddings(
    String employeeId,
    List<List<double>> embeddings,
  ) async {
    final normalized = embeddings
        .map((e) => FaceRecognitionService.normalizeEmbedding(e))
        .toList();

    await EmbeddingDb.instance.upsertMulti(employeeId, normalized);

    await _client.from(_table).upsert({
      'employee_id': employeeId,
      'embedding': jsonEncode(normalized),
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  // ── Download (restore on new device) ─────────────────────────────────────

  /// Pull embedding(s) from Supabase and cache locally.
  /// Returns the list of normalized embeddings (1..N) or null if not enrolled.
  Future<List<List<double>>?> fetchAndCacheEmbeddings(String employeeId) async {
    final row = await _client
        .from(_table)
        .select('embedding')
        .eq('employee_id', employeeId)
        .maybeSingle();

    if (row == null) return null;

    final raw = row['embedding'] as String;
    final decoded = jsonDecode(raw) as List;
    if (decoded.isEmpty) return null;

    final List<List<double>> embeddings;
    if (decoded.first is List) {
      // v2: list of lists
      embeddings = decoded
          .map((e) =>
              (e as List).map((n) => (n as num).toDouble()).toList())
          .toList();
    } else {
      // v1: single list
      embeddings = [
        decoded.map((e) => (e as num).toDouble()).toList(),
      ];
    }

    final normalized = embeddings
        .map((e) => FaceRecognitionService.normalizeEmbedding(e))
        .toList();

    await EmbeddingDb.instance.upsertMulti(employeeId, normalized);
    return normalized;
  }

  /// Backward-compat single-embedding fetch — returns first embedding only.
  Future<List<double>?> fetchAndCacheEmbedding(String employeeId) async {
    final list = await fetchAndCacheEmbeddings(employeeId);
    if (list == null || list.isEmpty) return null;
    return list.first;
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

  /// Get all embeddings for current user — checks SQLite first, then Supabase.
  /// Returns null if not enrolled anywhere.
  Future<List<List<double>>?> getEmbeddings(String employeeId) async {
    final local = await EmbeddingDb.instance.getMulti(employeeId);
    if (local != null && local.isNotEmpty) return local;

    return fetchAndCacheEmbeddings(employeeId);
  }

  /// Backward-compat single-embedding getter — returns first only.
  Future<List<double>?> getEmbedding(String employeeId) async {
    final list = await getEmbeddings(employeeId);
    if (list == null || list.isEmpty) return null;
    return list.first;
  }

  // ── Adaptive update (online learning) ────────────────────────────────────

  /// Perbarui embedding saat presensi berhasil dengan similarity di zona
  /// [minSimilarity, maxSimilarity] — artinya wajah dikenali tapi ada
  /// pergeseran (ekspresi beda, pencahayaan beda, dsb).
  ///
  /// Cara kerja: exponential moving average antara embedding lama dan baru.
  /// [alpha] = bobot frame baru (0.05–0.15 cukup konservatif).
  /// Hanya embedding dengan similarity tertinggi yang diperbarui,
  /// sehingga pose lain (kiri/kanan/ekspresi) tidak terkontaminasi.
  Future<void> adaptEmbedding(
    String employeeId,
    List<double> newEmbedding, {
    double minSimilarity = 0.55,
    double maxSimilarity = 0.80,
    double alpha = 0.08,
  }) async {
    final stored = await getEmbeddings(employeeId);
    if (stored == null || stored.isEmpty) return;

    // Cari embedding tersimpan yang paling mirip dengan frame baru.
    int bestIdx = 0;
    double bestSim = -1;
    for (int i = 0; i < stored.length; i++) {
      final sim = FaceRecognitionService.cosineSimilarity(newEmbedding, stored[i]);
      if (sim > bestSim) {
        bestSim = sim;
        bestIdx = i;
      }
    }

    // Hanya update kalau similarity ada di zona "hampir cocok".
    if (bestSim < minSimilarity || bestSim > maxSimilarity) return;

    // EMA: blended = normalize((1-alpha)*old + alpha*new)
    final old = stored[bestIdx];
    final blended = List<double>.generate(
      old.length,
      (i) => (1 - alpha) * old[i] + alpha * newEmbedding[i],
    );
    final normalized = FaceRecognitionService.normalizeEmbedding(blended);

    final updated = List<List<double>>.from(stored);
    updated[bestIdx] = normalized;

    // Simpan ke SQLite lokal dulu (cepat), Supabase background.
    await EmbeddingDb.instance.upsertMulti(employeeId, updated);
    _client.from(_table).upsert({
      'employee_id': employeeId,
      'embedding': jsonEncode(updated),
      'updated_at': DateTime.now().toIso8601String(),
    }).then((_) {}).catchError((_) {});
  }

  // ── Delete (re-enrollment) ────────────────────────────────────────────────

  Future<void> deleteEmbedding(String employeeId) async {
    await EmbeddingDb.instance.delete(employeeId);
    await _client.from(_table).delete().eq('employee_id', employeeId);
  }
}
