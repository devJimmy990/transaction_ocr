import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';

class FloatingOverlayButton extends StatefulWidget {
  const FloatingOverlayButton({super.key});

  @override
  State<FloatingOverlayButton> createState() => _FloatingOverlayButtonState();
}

class _FloatingOverlayButtonState extends State<FloatingOverlayButton> {
  final List<String> _screenshotQueue = [];
  StreamSubscription? _dataSubscription;

  bool _hasPermission = false;

  @override
  void initState() {
    super.initState();
    _listenToSharedData();
  }

  void _listenToSharedData() {
    _dataSubscription = FlutterOverlayWindow.overlayListener.listen((
      data,
    ) async {
      if (!mounted) return;

      print('Overlay received data: $data');

      // ✅ Handle different actions
      switch (data['action']) {
        case 'init':
          setState(() {
            _hasPermission = data['has_screenshot_permission'] == true;
          });
          break;

        case 'screenshot_captured':
          final path = data['path'] as String?;
          if (path != null && path.isNotEmpty) {
            _screenshotQueue.add(path);
            if (_screenshotQueue.length == 1) {
              _processQueue();
            }
          }
          break;
      }
    });
  }

  Future<void> _requestScreenshot() async {
    try {
      print("debug: Requesting screenshot from overlay");
      if (!_hasPermission) {
        print(
          "debug: Cannot request screenshot.  Has Permission: $_hasPermission",
        );
        return;
      }

      print("debug: Requesting screenshot from main app");
      await FlutterOverlayWindow.shareData({'action': 'request_screenshot'});
    } catch (e) {
      print("debug: error while capturing screenshot: $e");
    }
  }

  Future<void> _processQueue() async {
    while (_screenshotQueue.isNotEmpty) {
      final imagePath = _screenshotQueue.removeAt(0);

      try {
        print('Processing OCR for: $imagePath');
        // await sl<TransactionOcrCubit>().performOCR(imagePath);
      } catch (e) {
        print('OCR error: $e');
      }
    }
  }

  @override
  void dispose() {
    _dataSubscription?.cancel();
    super.dispose();
  }

  void _reset() {
    setState(() {
      _screenshotQueue.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 0.0),
      child: IconButton(
        onLongPress: _reset,
        onPressed: _requestScreenshot,
        style: IconButton.styleFrom(backgroundColor: Colors.blue),
        icon: const Icon(Icons.camera_alt, color: Colors.white, size: 38),
      ),
    );
  }
}
