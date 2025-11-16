import 'dart:async';

import 'package:flutter/services.dart';

class ScreenshotService {
  static const platform = MethodChannel('screenshot_channel');

  // Events
  Function(String imagePath)? onScreenshotCaptured;
  Function(String error)? onScreenshotFailed;
  Function()? onServiceStarted;
  Function()? onServiceStopped;
  Function(String error)? onServiceFailed;

  bool _isServiceRunning = false;

  ScreenshotService() {
    platform.setMethodCallHandler(_handleMethodCall);
  }

  Future<void> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'onScreenshotCaptured':
        onScreenshotCaptured?.call(call.arguments as String);
        break;
      case 'onScreenshotFailed':
        onScreenshotFailed?.call(call.arguments as String);
        break;
      case 'onServiceStarted':
        _isServiceRunning = true;
        onServiceStarted?.call();
        break;
      case 'onServiceStopped':
        _isServiceRunning = false;
        onServiceStopped?.call();
        break;
      case 'onServiceFailed':
        _isServiceRunning = false;
        onServiceFailed?.call(call.arguments as String);
        break;
    }
  }

  Future<bool> requestMediaProjectionAndStart() async {
    try {
      final result = await platform.invokeMethod<bool>(
        'requestMediaProjection',
      );
      return result ?? false;
    } catch (e) {
      return false;
    }
  }

  Future<void> takeScreenshot() async {
    try {
      await platform.invokeMethod('takeScreenshot');
    } catch (e) {
      onScreenshotFailed?.call(e.toString());
    }
  }

  Future<void> stopService() async {
    try {
      await platform.invokeMethod('stopService');
    } catch (e) {}
  }

  Future<bool> checkServiceStatus() async {
    try {
      final isRunning = await platform.invokeMethod<bool>('isServiceRunning');
      _isServiceRunning = isRunning ?? false;
      return _isServiceRunning;
    } catch (e) {
      return false;
    }
  }

  void dispose() {}
}
