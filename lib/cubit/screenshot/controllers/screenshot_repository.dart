import 'package:local_ocr/cubit/screenshot/controllers/screenshot_data_source.dart';
import 'package:local_ocr/model/screenshot_model.dart';

class ScreenshotRepository {
  final ScreenshotDataSource _dataSource;

  ScreenshotRepository(this._dataSource);

  Future<List<ScreenshotModel>> getAllScreenshots() async {
    try {
      final rows = await _dataSource.getAllScreenshots();
      return rows.map((r) => ScreenshotModel.fromJson(r)).toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> insertScreenshot(ScreenshotModel model) async {
    try {
      await _dataSource.insertScreenshot(model.toJson());
    } catch (e) {
      rethrow;
    }
  }

  Future<int> updateScreenshot(String id, ScreenshotModel model) async {
    try {
      return await _dataSource.updateScreenshot(id, model.toJson());
    } catch (e) {
      rethrow;
    }
  }

  // Future<void> deleteScreenshot(String id) async {
  //   // remove file if exists
  //   final rec = await _db.queryById(DBHelper.tableScreenshots, id);
  //   if (rec != null) {
  //     final path = rec['imagePath'] as String?;
  //     if (path != null) {
  //       final file = File(path);
  //       if (await file.exists()) await file.delete();
  //     }
  //   }
  //   await _db.delete(DBHelper.tableScreenshots, id);
  // }

  // Future<void> markAsSuccessAndDeleteFile(
  //   String id, {
  //   String? extractedText,
  // }) async {
  //   final rec = await getById(id);
  //   if (rec == null) return;
  //   // delete file if exists
  //   if (rec.imagePath != null) {
  //     final file = File(rec.imagePath!);
  //     if (await file.exists()) await file.delete();
  //   }
  //   final updated = ScreenshotModel(
  //     id: rec.id,
  //     imagePath: null,
  //     extractedText: extractedText ?? rec.extractedText,
  //     timestamp: DateTime.now(),
  //     status: ScreenshotStatus.success,
  //     errorMessage: null,
  //   );
  //   await _db.update(DBHelper.tableScreenshots, updated.toJson(), id);
  // }
}
