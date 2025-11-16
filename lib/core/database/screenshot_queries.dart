import 'package:local_ocr/core/database/base_database_queries.dart';
import 'package:sqflite/sqflite.dart';

class ScreenshotQueries implements BaseDatabaseQueries {
  final Database _db;
  ScreenshotQueries(this._db);

  @override
  Future<List<Map<String, dynamic>>> getAll() async {
    try {
      return await _db.query("screenshots");
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<int> insert(Map<String, dynamic> payload) async {
    try {
      return await _db.insert("screenshots", payload);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<int> update(String id, Map<String, dynamic> payload) async {
    try {
      return await _db.update(
        "screenshots",
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
      return await _db.delete("screenshots", where: 'id = ?', whereArgs: [id]);
    } catch (e) {
      rethrow;
    }
  }
}
