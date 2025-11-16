import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

class ScreenshotService {
  static const platform = MethodChannel('com.yourapp/screenshot');

  Function(String imagePath)? onScreenshotCaptured;
  Function(String imagePath)? onScreenshotFailed;
  Function()? onServiceStopped;

  ScreenshotService() {
    platform.setMethodCallHandler(_handleMethod);
  }

  Future<void> _handleMethod(MethodCall call) async {
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
      case 'requestNewPermission': // ✅ NEW
        await _requestNewPermissionForScreenshot();
        break;
    }
  }

  // ✅ Request new permission and auto-capture
  Future<void> _requestNewPermissionForScreenshot() async {
    try {
      final result = await platform.invokeMethod('requestMediaProjection');
      // Permission dialog will show, and after approval,
      // MainActivity will trigger the screenshot automatically
    } catch (e) {
      print('Error requesting new permission: $e');
    }
  }

  Future<bool> checkPermissions() async {
    if (!await Permission.systemAlertWindow.isGranted) {
      final status = await Permission.systemAlertWindow.request();
      if (!status.isGranted) return false;
    }

    if (!await Permission.notification.isGranted) {
      await Permission.notification.request();
    }

    return true;
  }

  Future<bool> requestMediaProjection() async {
    try {
      final result = await platform.invokeMethod('requestMediaProjection');
      return result as bool;
    } catch (e) {
      print('Error requesting media projection: $e');
      return false;
    }
  }

  Future<void> startService() async {
    try {
      await platform.invokeMethod('startService');
    } catch (e) {
      print('Error starting service: $e');
    }
  }

  Future<void> stopService() async {
    try {
      await platform.invokeMethod('stopService');
    } catch (e) {
      print('Error stopping service: $e');
    }
  }

  Future<void> updateSuccessCount() async {
    try {
      await platform.invokeMethod('updateSuccess');
    } catch (e) {
      print('Error updating success count: $e');
    }
  }

  Future<void> updateFailedCount() async {
    try {
      await platform.invokeMethod('updateFailed');
    } catch (e) {
      print('Error updating failed count: $e');
    }
  }
}
