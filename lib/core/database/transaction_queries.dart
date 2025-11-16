import 'package:local_ocr/core/database/base_database_queries.dart';
import 'package:sqflite/sqflite.dart';

class TransactionQueries implements BaseDatabaseQueries {
  final Database _db;
  TransactionQueries(this._db);

  @override
  Future<int> insert(Map<String, dynamic> payload) async {
    try {
      return await _db.insert(
        'transactions',
        payload,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getAll() async {
    try {
      return await _db.query('transactions', orderBy: 'timestamp DESC');
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<int> update(String id, Map<String, dynamic> payload) async {
    try {
      return await _db.update(
        'transactions',
        payload,
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<int> delete(String id) async {
    try {
      return await _db.delete('transactions', where: 'id = ?', whereArgs: [id]);
    } catch (e) {
      rethrow;
    }
  }

  Future<int> deleteAll() async {
    try {
      return await _db.delete('transactions');
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, int>> getStatistics() async {
    final result = await _db.rawQuery('''
      SELECT 
        COUNT(*) as total,
        SUM(CASE WHEN status = 'success' THEN 1 ELSE 0 END) as success,
        SUM(CASE WHEN status = 'failed' THEN 1 ELSE 0 END) as failed,
        SUM(CASE WHEN isReviewed = 1 THEN 1 ELSE 0 END) as reviewed
      FROM transactions
    ''');

    return {
      'total': result[0]['total'] as int? ?? 0,
      'success': result[0]['success'] as int? ?? 0,
      'failed': result[0]['failed'] as int? ?? 0,
      'reviewed': result[0]['reviewed'] as int? ?? 0,
    };
  }
}
