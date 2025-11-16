import 'dart:async';
import 'dart:collection';
import 'dart:io';

import 'package:local_ocr/core/extensions/string.dart';
import 'package:local_ocr/core/helper/ocr_service.dart';
import 'package:local_ocr/cubit/transaction_ocr/controllers/transaction_repository.dart';
import 'package:local_ocr/model/transaction_model.dart';

class OCRQueueManager {
  static const int maxConcurrent = 2;
  static const int maxRetries = 2;

  final TransactionRepository _repository;
  final Queue<String> _queue = Queue();
  int _processing = 0;
  bool _isPaused = false;

  // Callbacks
  Function(TransactionModel transaction)? onSuccess;
  Function(TransactionModel transaction)? onFailed;
  Function(int queueLength)? onQueueChanged;

  // Singleton
  static OCRQueueManager? _instance;

  OCRQueueManager._(this._repository);

  static OCRQueueManager get instance {
    if (_instance == null) {
      throw Exception(
        'OCRQueueManager not initialized. Call initialize() first.',
      );
    }
    return _instance!;
  }

  int get queueLength => _queue.length;
  int get processingCount => _processing;
  bool get isPaused => _isPaused;

  /// إضافة صورة للقائمة
  Future<void> addToQueue(String imagePath) async {
    print('📋 Adding to queue: $imagePath');
    _queue.add(imagePath);
    onQueueChanged?.call(_queue.length);
    _processNext();
  }

  /// إضافة عدة صور للقائمة
  Future<void> addMultipleToQueue(List<String> imagePaths) async {
    print('📋 Adding ${imagePaths.length} images to queue');
    _queue.addAll(imagePaths);
    onQueueChanged?.call(_queue.length);
    _processNext();
  }

  /// إيقاف مؤقت
  void pause() {
    print('⏸️ Queue paused');
    _isPaused = true;
  }

  /// استئناف
  void resume() {
    print('▶️ Queue resumed');
    _isPaused = false;
    _processNext();
  }

  /// مسح القائمة
  void clear() {
    print('🗑️ Queue cleared');
    _queue.clear();
    onQueueChanged?.call(0);
  }

  Future<void> _processNext() async {
    if (_isPaused) {
      print('⏸️ Queue is paused');
      return;
    }

    if (_processing >= maxConcurrent) {
      print('⏳ Max concurrent reached ($_processing/$maxConcurrent)');
      return;
    }

    if (_queue.isEmpty) {
      print('✅ Queue is empty');
      return;
    }

    _processing++;
    final imagePath = _queue.removeFirst();
    onQueueChanged?.call(_queue.length);

    print('🔄 Processing ($_processing/$maxConcurrent): $imagePath');

    try {
      await _performOCRWithRetry(imagePath);
    } catch (e) {
      print('❌ Final OCR failure for $imagePath: $e');
    } finally {
      _processing--;

      // معالجة التالي
      if (_queue.isNotEmpty && !_isPaused) {
        _processNext();
      }
    }
  }

  Future<void> _performOCRWithRetry(String imagePath, {int attempt = 1}) async {
    try {
      final result = await OcrService.startService(imagePath);

      final transaction = TransactionModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: result.name,
        phone: result.phone,
        amount: result.amount,
        reference: result.reference,
        date: result.date.toDateTime(),
        type: TransactionType.values[result.type],
        userPhone: "01289223643",
      );

      await _repository.insertTransaction(transaction.toJson());

      // حذف الصورة بعد النجاح
      final file = File(imagePath);
      if (await file.exists()) {
        await file.delete();
        print('🗑️ Deleted image: $imagePath');
      }

      print('✅ OCR Success: ${transaction.name} - ${transaction.amount}');
      onSuccess?.call(transaction);
    } catch (e) {
      print('❌ OCR Error (attempt $attempt/$maxRetries): $e');

      if (attempt < maxRetries) {
        // إعادة المحاولة
        print('🔄 Retrying... (${attempt + 1}/$maxRetries)');
        // await Future.delayed(Duration(seconds: attempt));
        // return _performOCRWithRetry(imagePath, attempt: attempt + 1);
      } else {
        // فشل نهائي - نقل للـ failed
        // await _handleFailure(imagePath, e.toString());
      }
    }
  }

  // Future<void> _handleFailure(String imagePath, String error) async {
  //   print('💾 Saving failed transaction: $imagePath');

  //   // نقل الصورة لمجلد failed
  //   final failedPath = await _moveToFailedDirectory(imagePath);

  //   final transaction = TransactionModel(
  //     id: DateTime.now().millisecondsSinceEpoch.toString(),
  //     type: '',
  //     name: '',
  //     phone: '',
  //     amount: 0,
  //     date: '',
  //     reference: '',
  //     imagePath: failedPath,
  //     timestamp: DateTime.now(),
  //     status: 'failed',
  //     errorMessage: error,
  //   );

  //   await _repository.insertTransaction(transaction.toJson());
  //   onFailed?.call(transaction);
  // }

  // Future<String> _moveToFailedDirectory(String imagePath) async {
  //   final file = File(imagePath);
  //   final failedDir = Directory(
  //     '${file.parent.parent.path}/failed_screenshots',
  //   );

  //   if (!await failedDir.exists()) {
  //     await failedDir.create(recursive: true);
  //   }

  //   final newPath = '${failedDir.path}/${file.uri.pathSegments.last}';
  //   await file.copy(newPath);

  //   if (await file.exists()) {
  //     await file.delete();
  //   }

  //   return newPath;
  // }

  /// إعادة محاولة معاملة فاشلة
  // Future<void> retryFailedTransaction(TransactionModel transaction) async {
  //   if (transaction.imagePath != null && transaction.imagePath!.isNotEmpty) {
  //     print('🔄 Retrying failed transaction: ${transaction.id}');
  //     await addToQueue(transaction.imagePath!);
  //     await _repository.deleteTransaction(transaction.id);
  //   }
  // }
}
