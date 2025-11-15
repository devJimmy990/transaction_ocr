import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

class ScreenshotService {
  static const platform = MethodChannel('com.yourapp/screenshot');

  // Callbacks
  Function(String imagePath)? onScreenshotCaptured;
  Function(String imagePath)? onScreenshotFailed;
  Function()? onServiceStopped;

  ScreenshotService() {
    platform.setMethodCallHandler(_handleMethod);
  }

  Future _handleMethod(MethodCall call) async {
    switch (call.method) {
      case 'onScreenshotCaptured':
        onScreenshotCaptured?.call(call.arguments as String);
        break;
      case 'onScreenshotFailed':
        onScreenshotFailed?.call(call.arguments as String);
        break;
      case 'onServiceStopped':
        onServiceStopped?.call();
        break;
    }
  }

  Future checkPermissions() async {
    // Check overlay permission
    if (!await Permission.systemAlertWindow.isGranted) {
      final status = await Permission.systemAlertWindow.request();
      if (!status.isGranted) return false;
    }

    // Check notification permission (Android 13+)
    if (!await Permission.notification.isGranted) {
      await Permission.notification.request();
    }

    return true;
  }

  Future requestMediaProjection() async {
    try {
      final result = await platform.invokeMethod('requestMediaProjection');
      return result as bool;
    } catch (e) {
      print('Error requesting media projection: $e');
      return false;
    }
  }

  Future startService() async {
    try {
      await platform.invokeMethod('startService');
    } catch (e) {
      print('Error starting service: $e');
    }
  }

  Future stopService() async {
    try {
      await platform.invokeMethod('stopService');
    } catch (e) {
      print('Error stopping service: $e');
    }
  }

  Future updateSuccessCount() async {
    try {
      await platform.invokeMethod('updateSuccess');
    } catch (e) {
      print('Error updating success count: $e');
    }
  }

  Future updateFailedCount() async {
    try {
      await platform.invokeMethod('updateFailed');
    } catch (e) {
      print('Error updating failed count: $e');
    }
  }

  Future<void> requestNewScreenshot() async {
    try {
      // Request new permission before each screenshot
      final result = await platform.invokeMethod('requestNewScreenshot');
      if (!result) {
        print('User cancelled screenshot permission');
      }
    } catch (e) {
      print('Error requesting new screenshot: $e');
    }
  }
}
