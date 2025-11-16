// import 'dart:async';
// import 'dart:io';

// import 'package:hive/hive.dart';
// import 'package:local_ocr/core/screenshot_service.dart';
// import 'package:local_ocr/model/screenshot_model.dart';

// class OCRProcessor {
//   final Function(String imagePath) _ocrFunction;
//   final ScreenshotService _screenshotService;

//   bool _isProcessing = false;
//   final List<String> _queue = [];
//   late Box<ScreenshotModel> _box;

//   // --- Singleton setup ---
//   static OCRProcessor? _instance;

//   OCRProcessor._internal(this._ocrFunction, this._screenshotService);

//   /// Initialize the singleton once before using it
//   static Future<void> init({
//     required Function(String imagePath) ocrFunction,
//     required ScreenshotService screenshotService,
//   }) async {
//     if (_instance != null) return; // Already initialized
//     final instance = OCRProcessor._internal(ocrFunction, screenshotService);
//     instance._box = await Hive.openBox<ScreenshotModel>('screenshots');
//     _instance = instance;
//   }

//   /// Internal getter
//   static OCRProcessor get _i {
//     if (_instance == null) {
//       throw Exception(
//         'OCRProcessor not initialized. Call OCRProcessor.init() first.',
//       );
//     }
//     return _instance!;
//   }

//   // --- Public static methods that use the singleton instance ---

//   static void addToQueue(String imagePath) => _i._addToQueue(imagePath);

//   static Future<List<ScreenshotModel>> getFailedScreenshots() =>
//       _i._getFailedScreenshots();

//   static Future<void> retryFailed(String id) => _i._retryFailed(id);

//   static Future<void> deleteFailedScreenshot(String id) =>
//       _i._deleteFailedScreenshot(id);

//   // --- Internal instance logic ---

//   void _addToQueue(String imagePath) {
//     _queue.add(imagePath);
//     _processNext();
//   }

//   Future<void> _processNext() async {
//     if (_isProcessing || _queue.isEmpty) return;

//     _isProcessing = true;
//     final imagePath = _queue.removeAt(0);

//     try {
//       final extractedText = await _ocrFunction(imagePath);

//       final model = ScreenshotModel(
//         id: DateTime.now().millisecondsSinceEpoch.toString(),
//         imagePath: null, // deleted after success
//         extractedText: extractedText,
//         timestamp: DateTime.now(),
//         status: ScreenshotStatus.success,
//       );

//       await _box.add(model);

//       final file = File(imagePath);
//       if (await file.exists()) await file.delete();

//       await _screenshotService.updateSuccessCount();
//     } catch (e) {
//       print('OCR Error: $e');

//       final failedPath = await _moveToFailedDirectory(imagePath);

//       final model = ScreenshotModel(
//         id: DateTime.now().millisecondsSinceEpoch.toString(),
//         imagePath: failedPath,
//         extractedText: null,
//         timestamp: DateTime.now(),
//         status: ScreenshotStatus.failed,
//         errorMessage: e.toString(),
//       );

//       await _box.add(model);
//       await _screenshotService.updateFailedCount();
//     }

//     _isProcessing = false;

//     if (_queue.isNotEmpty) _processNext();
//   }

//   Future<String> _moveToFailedDirectory(String imagePath) async {
//     final file = File(imagePath);
//     final failedDir = Directory(
//       '${file.parent.parent.path}/failed_screenshots',
//     );

//     if (!await failedDir.exists()) {
//       await failedDir.create(recursive: true);
//     }

//     final newPath = '${failedDir.path}/${file.uri.pathSegments.last}';
//     await file.copy(newPath);
//     await file.delete();
//     return newPath;
//   }

//   Future<void> _retryFailed(String id) async {
//     final model = _box.get(id);
//     if (model != null && model.imagePath != null) {
//       _addToQueue(model.imagePath!);
//       await _box.delete(id);
//     }
//   }

//   Future<List<ScreenshotModel>> _getFailedScreenshots() async {
//     return _box.values
//         .where((model) => model.status == ScreenshotStatus.failed)
//         .toList();
//   }

//   Future<void> _deleteFailedScreenshot(String id) async {
//     final model = _box.get(id);
//     if (model != null && model.imagePath != null) {
//       final file = File(model.imagePath!);
//       if (await file.exists()) await file.delete();
//       await _box.delete(id);
//     }
//   }
// }

import 'dart:async';
import 'dart:io';

import 'package:hive/hive.dart';
import 'package:local_ocr/core/screenshot_service.dart';
import 'package:local_ocr/model/screenshot_model.dart';

class OCRProcessor {
  final Future<String> Function(String imagePath) _ocrFunction;
  final ScreenshotService _screenshotService;

  bool _isProcessing = false;
  final List<String> _queue = [];
  late Box<ScreenshotModel> _box;

  static OCRProcessor? _instance;

  OCRProcessor._internal(this._ocrFunction, this._screenshotService);

  static Future<void> init({
    required Future<String> Function(String imagePath) ocrFunction,
    required ScreenshotService screenshotService,
  }) async {
    if (_instance != null) return;
    final instance = OCRProcessor._internal(ocrFunction, screenshotService);
    instance._box = await Hive.openBox<ScreenshotModel>('screenshots');
    _instance = instance;
  }

  static OCRProcessor get _i {
    if (_instance == null) {
      throw Exception(
        'OCRProcessor not initialized. Call OCRProcessor.init() first.',
      );
    }
    return _instance!;
  }

  static void addToQueue(String imagePath) => _i._addToQueue(imagePath);

  static Future<List<ScreenshotModel>> getFailedScreenshots() =>
      _i._getFailedScreenshots();

  static Future<void> retryFailed(String id) => _i._retryFailed(id);

  static Future<void> deleteFailedScreenshot(String id) =>
      _i._deleteFailedScreenshot(id);

  void _addToQueue(String imagePath) {
    _queue.add(imagePath);
    print('📸 Added to queue: $imagePath (Queue size: ${_queue.length})');
    _processNext();
  }

  Future<void> _processNext() async {
    if (_isProcessing || _queue.isEmpty) return;

    _isProcessing = true;
    final imagePath = _queue.removeAt(0);

    print('🔄 Processing: $imagePath');

    try {
      final extractedText = await _ocrFunction(imagePath);
      print('✅ OCR Success: $extractedText');
      await _screenshotService.updateSuccessCount();
    } catch (e) {
      print('❌ OCR Error: $e');

      final failedPath = await _moveToFailedDirectory(imagePath);

      final model = ScreenshotModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        imagePath: failedPath,
        extractedText: null,
        timestamp: DateTime.now(),
        status: ScreenshotStatus.failed,
        errorMessage: e.toString(),
      );

      await _box.add(model);
      await _screenshotService.updateFailedCount();
    }

    _isProcessing = false;

    if (_queue.isNotEmpty) {
      print('📋 Queue remaining: ${_queue.length}');
      _processNext();
    }
  }

  Future<String> _moveToFailedDirectory(String imagePath) async {
    final file = File(imagePath);
    final failedDir = Directory(
      '${file.parent.parent.path}/failed_screenshots',
    );

    if (!await failedDir.exists()) {
      await failedDir.create(recursive: true);
    }

    final newPath = '${failedDir.path}/${file.uri.pathSegments.last}';
    await file.copy(newPath);
    await file.delete();
    return newPath;
  }

  Future<void> _retryFailed(String id) async {
    final model = _box.get(id);
    if (model != null && model.imagePath != null) {
      _addToQueue(model.imagePath!);
      await _box.delete(id);
    }
  }

  Future<List<ScreenshotModel>> _getFailedScreenshots() async {
    return _box.values
        .where((model) => model.status == ScreenshotStatus.failed)
        .toList();
  }

  Future<void> _deleteFailedScreenshot(String id) async {
    final model = _box.get(id);
    if (model != null && model.imagePath != null) {
      final file = File(model.imagePath!);
      if (await file.exists()) await file.delete();
      await _box.delete(id);
    }
  }
}
