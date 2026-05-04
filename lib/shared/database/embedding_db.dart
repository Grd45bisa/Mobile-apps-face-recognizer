import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

/// Local SQLite store for face embeddings.
/// Embedding is stored as JSON array of 192 normalized doubles.
/// Source of truth is Supabase — this is a local cache for offline-guard
/// and fast lookup without round-trip latency.
class EmbeddingDb {
  static final EmbeddingDb instance = EmbeddingDb._();
  EmbeddingDb._();

  Database? _db;

  Future<Database> get db async {
    _db ??= await _open();
    return _db!;
  }

  Future<Database> _open() async {
    final dir = await getDatabasesPath();
    final path = join(dir, 'face_embeddings.db');
    return openDatabase(
      path,
      version: 1,
      onCreate: (db, _) async {
        await db.execute('''
          CREATE TABLE face_embeddings (
            employee_id TEXT PRIMARY KEY,
            embedding   TEXT NOT NULL,
            updated_at  TEXT NOT NULL
          )
        ''');
      },
    );
  }

  /// Save or replace embedding for an employee.
  Future<void> upsert(String employeeId, List<double> embedding) async {
    final d = await db;
    await d.insert(
      'face_embeddings',
      {
        'employee_id': employeeId,
        'embedding': jsonEncode(embedding),
        'updated_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Get embedding for an employee, or null if not enrolled.
  Future<List<double>?> get(String employeeId) async {
    final d = await db;
    final rows = await d.query(
      'face_embeddings',
      where: 'employee_id = ?',
      whereArgs: [employeeId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    final raw = rows.first['embedding'] as String;
    return (jsonDecode(raw) as List).map((e) => (e as num).toDouble()).toList();
  }

  /// Check if employee has an enrolled embedding.
  Future<bool> isEnrolled(String employeeId) async {
    final d = await db;
    final rows = await d.query(
      'face_embeddings',
      columns: ['employee_id'],
      where: 'employee_id = ?',
      whereArgs: [employeeId],
      limit: 1,
    );
    return rows.isNotEmpty;
  }

  /// Delete embedding (e.g. re-enrollment).
  Future<void> delete(String employeeId) async {
    final d = await db;
    await d.delete(
      'face_embeddings',
      where: 'employee_id = ?',
      whereArgs: [employeeId],
    );
  }

  /// Get all stored embeddings (for matching against any employee).
  Future<Map<String, List<double>>> getAll() async {
    final d = await db;
    final rows = await d.query('face_embeddings');
    return {
      for (final row in rows)
        row['employee_id'] as String:
            (jsonDecode(row['embedding'] as String) as List)
                .map((e) => (e as num).toDouble())
                .toList(),
    };
  }

  Future<void> close() async {
    await _db?.close();
    _db = null;
  }
}
