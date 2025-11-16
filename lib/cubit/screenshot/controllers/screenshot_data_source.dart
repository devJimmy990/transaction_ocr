import 'package:local_ocr/core/database/screenshot_queries.dart';

class ScreenshotDataSource {
  final ScreenshotQueries _query;
  ScreenshotDataSource(this._query);

  Future<List<Map<String, dynamic>>> getAllScreenshots() async {
    try {
      return await _query.getAll();
    } catch (e) {
      rethrow;
    }
  }

  Future<int> insertScreenshot(Map<String, dynamic> payload) async {
    try {
      return await _query.insert(payload);
    } catch (e) {
      rethrow;
    }
  }

  Future<int> updateScreenshot(String id, Map<String, dynamic> payload) async {
    try {
      return await _query.update(id, payload);
    } catch (e) {
      rethrow;
    }
  }

  Future<int> deleteScreenshot(String id) async {
    try {
      return await _query.delete(id);
    } catch (e) {
      rethrow;
    }
  }
}
