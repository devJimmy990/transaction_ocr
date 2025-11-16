import 'dart:async';

typedef OcrFunction = Future<String> Function(String imagePath);

class OCRProcessor {
  final OcrFunction ocrFunction;
  bool _isProcessing = false;
  final List<String> _queue = [];

  // callbacks to UI / cubit
  FutureOr<void> Function(String imagePath, String extracted)? onSuccess;
  FutureOr<void> Function(String imagePath, Object error)? onFailure;

  OCRProcessor({required this.ocrFunction});

  void process(String imagePath) {
    _queue.add(imagePath);
    _maybeStart();
  }

  void _maybeStart() {
    if (_isProcessing || _queue.isEmpty) return;
    _isProcessing = true;
    final path = _queue.removeAt(0);
    _run(path);
  }

  Future<void> _run(String path) async {
    try {
      final text = await ocrFunction(path);
      if (onSuccess != null) await onSuccess!(path, text);
    } catch (e) {
      if (onFailure != null) await onFailure!(path, e);
    } finally {
      _isProcessing = false;
      if (_queue.isNotEmpty) _maybeStart();
    }
  }

  void dispose() {
    _queue.clear();
  }
}
