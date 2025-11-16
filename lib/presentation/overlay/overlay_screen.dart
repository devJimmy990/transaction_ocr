import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:local_ocr/core/service_locator.dart';
import 'package:local_ocr/cubit/transaction_ocr/transaction_ocr_cubit.dart';

class OverlayScreen extends StatefulWidget {
  const OverlayScreen({super.key});

  @override
  State<OverlayScreen> createState() => _OverlayScreenState();
}

class _OverlayScreenState extends State<OverlayScreen> {
  int failedCount = 0;
  int successCount = 0;
  bool isProcessing = false;
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
            if (_screenshotQueue.length == 1 && !isProcessing) {
              _processQueue();
            }
          }
          break;

        case 'screenshot_failed':
          setState(() {
            failedCount++;
            isProcessing = false;
          });
          break;

        case 'update_success':
          setState(() => successCount++);
          break;

        case 'update_failed':
          setState(() => failedCount++);
          break;
      }
    });
  }

  Future<void> _requestScreenshot() async {
    if (isProcessing || !_hasPermission) {
      return;
    }

    setState(() => isProcessing = true);

    await FlutterOverlayWindow.shareData({'action': 'request_screenshot'});
  }

  Future<void> _processQueue() async {
    if (_screenshotQueue.isEmpty) {
      setState(() => isProcessing = false);
      return;
    }

    setState(() => isProcessing = true);

    while (_screenshotQueue.isNotEmpty) {
      final imagePath = _screenshotQueue.removeAt(0);

      try {
        print('Processing OCR for: $imagePath');
        await sl<TransactionOcrCubit>().performOCR(imagePath);

        if (mounted) {
          setState(() => successCount++);
        }
      } catch (e) {
        print('OCR error: $e');
        if (mounted) {
          setState(() => failedCount++);
        }
      }
    }

    if (mounted) {
      setState(() => isProcessing = false);
    }
  }

  @override
  void dispose() {
    _dataSubscription?.cancel();
    super.dispose();
  }

  void _reset() {
    setState(() {
      successCount = 0;
      failedCount = 0;
      isProcessing = false;
      _screenshotQueue.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: SizedBox(
        width: 200,
        height: 400,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Center(
              child: IconButton(
                onLongPress: _reset,
                onPressed: _requestScreenshot,
                style: IconButton.styleFrom(backgroundColor: Colors.blue),
                icon: const Icon(
                  Icons.camera_alt,
                  color: Colors.white,
                  size: 42,
                ),
              ),
            ),
            Positioned(
              right: 0,
              top: 0,
              child: _buildCounter('ناجح', 5, Colors.green),
            ),

            Positioned(
              right: 0,
              bottom: 0,
              child: _buildCounter('فاشل', 5, Colors.red),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCounter(String label, int count, Color color) {
    return CircleAvatar(
      radius: 10,
      backgroundColor: color,
      child: Center(
        child: Text(
          '$count',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}
