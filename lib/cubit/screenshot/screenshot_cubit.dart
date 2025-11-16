// import 'dart:async';

// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:flutter_overlay_window/flutter_overlay_window.dart';
// import 'package:permission_handler/permission_handler.dart';

// import 'screenshot_state.dart';

// class ScreenshotCubit extends Cubit<ScreenshotState> {
//   Timer? _statusCheckTimer;

//   ScreenshotCubit() : super(const ScreenshotState());

//   Future<void> checkPermissions() async {
//     final systemAlertWindow = await Permission.systemAlertWindow.isGranted;
//     emit(state.copyWith(hasPermissions: systemAlertWindow));
//   }

//   Future<bool> requestPermissions() async {
//     final status = await Permission.systemAlertWindow.request();
//     final granted = status.isGranted;
//     emit(state.copyWith(hasPermissions: granted));
//     return granted;
//   }

//   Future<bool> startOverlay() async {
//     try {
//       // Check permissions first
//       if (!state.hasPermissions) {
//         final granted = await requestPermissions();
//         if (!granted) {
//           emit(state.copyWith(isServiceRunning: false));
//           return false;
//         }
//       }
//       print("debug: cubit permissions granted");
//       // Check if already active
//       if (await FlutterOverlayWindow.isActive()) {
//         emit(state.copyWith(isServiceRunning: true));
//         print("debug: cubit overlay is already active");
//         return true;
//       }
//       print("debug: cubit overlay not active, starting...");

//       // Show overlay
//       await FlutterOverlayWindow.showOverlay(
//         enableDrag: true,
//         overlayTitle: "Screenshot OCR",
//         overlayContent: 'اضغط للتقاط الشاشة',
//         flag: OverlayFlag.defaultFlag,
//         visibility: NotificationVisibility.visibilityPublic,
//         positionGravity: PositionGravity.left,
//         height: 200,
//         width: WindowSize.matchParent,
//       );

//       print("debug: cubit overlay started");

//       // ✅ Wait a bit for overlay to initialize
//       await Future.delayed(const Duration(milliseconds: 500));

//       // ✅ Check if overlay is actually active
//       final isActive = await FlutterOverlayWindow.isActive();

//       print("debug: cubit overlay isActive=$isActive");

//       emit(state.copyWith(isServiceRunning: isActive));

//       // ✅ Start periodic status check
//       if (isActive) {
//         print("debug: cubit starting status monitoring");
//         _startStatusMonitoring();
//       }

//       print("debug: cubit returning isActive=$isActive");
//       return isActive;
//     } catch (e) {
//       print('Error starting overlay: $e');
//       emit(state.copyWith(isServiceRunning: false));
//       return false;
//     }
//   }

//   // ✅ Monitor overlay status periodically
//   void _startStatusMonitoring() {
//     _statusCheckTimer?.cancel();
//     _statusCheckTimer = Timer.periodic(const Duration(seconds: 2), (
//       timer,
//     ) async {
//       final isActive = await FlutterOverlayWindow.isActive();
//       if (state.isServiceRunning != isActive) {
//         emit(state.copyWith(isServiceRunning: isActive));
//       }

//       // Stop monitoring if overlay is closed
//       if (!isActive) {
//         timer.cancel();
//       }
//     });
//   }

//   Future<void> closeOverlay() async {
//     try {
//       _statusCheckTimer?.cancel();

//       final isActive = await FlutterOverlayWindow.isActive();
//       if (isActive) {
//         await FlutterOverlayWindow.closeOverlay();
//       }

//       // Wait for overlay to close
//       await Future.delayed(const Duration(milliseconds: 300));

//       emit(state.copyWith(isServiceRunning: false));
//     } catch (e) {
//       print('Error closing overlay: $e');
//       emit(state.copyWith(isServiceRunning: false));
//     }
//   }

//   void updateSuccessCount() {
//     emit(state.copyWith(successCount: state.successCount + 1));
//   }

//   void updateFailedCount() {
//     emit(state.copyWith(failedCount: state.failedCount + 1));
//   }

//   void resetCounters() {
//     emit(state.copyWith(successCount: 0, failedCount: 0));
//   }

//   @override
//   Future<void> close() {
//     _statusCheckTimer?.cancel();
//     return super.close();
//   }
// }

import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:permission_handler/permission_handler.dart';

import 'screenshot_state.dart';

class ScreenshotCubit extends Cubit<ScreenshotState> {
  Timer? _statusCheckTimer;
  static const platform = MethodChannel('screenshot_channel');

  ScreenshotCubit() : super(const ScreenshotState());

  Future<void> checkPermissions() async {
    final systemAlertWindow = await Permission.systemAlertWindow.isGranted;
    emit(state.copyWith(hasPermissions: systemAlertWindow));
  }

  Future<bool> requestPermissions() async {
    final status = await Permission.systemAlertWindow.request();
    final granted = status.isGranted;
    emit(state.copyWith(hasPermissions: granted));
    return granted;
  }

  // ✅ Request MediaProjection permission from MAIN APP
  Future<bool> requestMediaProjection() async {
    try {
      final result = await platform.invokeMethod('requestMediaProjection');
      return result as bool? ?? false;
    } catch (e) {
      print('Error requesting media projection: $e');
      return false;
    }
  }

  Future<bool> startOverlay() async {
    try {
      if (!state.hasPermissions) {
        final granted = await requestPermissions();
        if (!granted) {
          emit(state.copyWith(isServiceRunning: false));
          return false;
        }
      }

      // ✅ Request MediaProjection BEFORE showing overlay
      final mediaProjectionGranted = await requestMediaProjection();
      if (!mediaProjectionGranted) {
        print('MediaProjection permission denied');
        emit(state.copyWith(isServiceRunning: false));
        return false;
      }

      if (await FlutterOverlayWindow.isActive()) {
        emit(state.copyWith(isServiceRunning: true));
        return true;
      }

      // ✅ Share screenshot permission status to overlay
      await FlutterOverlayWindow.shareData({
        'has_screenshot_permission': true,
        'action': 'init',
      });

      await FlutterOverlayWindow.showOverlay(
        width: 200,
        height: 400,
        enableDrag: true,
        flag: OverlayFlag.defaultFlag,
        positionGravity: PositionGravity.auto,
        alignment: OverlayAlignment.centerLeft,
        startPosition: const OverlayPosition(0, 100),
        visibility: NotificationVisibility.visibilityPublic,
      );

      await Future.delayed(const Duration(milliseconds: 500));

      final isActive = await FlutterOverlayWindow.isActive();

      emit(state.copyWith(isServiceRunning: isActive));

      if (isActive) {
        _startStatusMonitoring();
      }

      return isActive;
    } catch (e) {
      print('Error starting overlay: $e');
      emit(state.copyWith(isServiceRunning: false));
      return false;
    }
  }

  // ✅ Capture screenshot from MAIN APP and share path to overlay
  Future<void> captureScreenshot() async {
    try {
      final String? path = await platform.invokeMethod('takeScreenshot');

      if (path != null && path.isNotEmpty) {
        // ✅ Share screenshot path to overlay
        await FlutterOverlayWindow.shareData({
          'action': 'screenshot_captured',
          'path': path,
        });
      } else {
        await FlutterOverlayWindow.shareData({'action': 'screenshot_failed'});
      }
    } catch (e) {
      print('Error capturing screenshot: $e');
      await FlutterOverlayWindow.shareData({'action': 'screenshot_failed'});
    }
  }

  void _startStatusMonitoring() {
    _statusCheckTimer?.cancel();
    _statusCheckTimer = Timer.periodic(const Duration(seconds: 2), (
      timer,
    ) async {
      final isActive = await FlutterOverlayWindow.isActive();
      if (state.isServiceRunning != isActive) {
        emit(state.copyWith(isServiceRunning: isActive));
      }

      if (!isActive) {
        timer.cancel();
      }
    });
  }

  Future<void> closeOverlay() async {
    try {
      _statusCheckTimer?.cancel();

      final isActive = await FlutterOverlayWindow.isActive();
      if (isActive) {
        await FlutterOverlayWindow.closeOverlay();
      }

      await Future.delayed(const Duration(milliseconds: 300));

      emit(state.copyWith(isServiceRunning: false));
    } catch (e) {
      print('Error closing overlay: $e');
      emit(state.copyWith(isServiceRunning: false));
    }
  }

  void updateSuccessCount() {
    emit(state.copyWith(successCount: state.successCount + 1));
  }

  void updateFailedCount() {
    emit(state.copyWith(failedCount: state.failedCount + 1));
  }

  void resetCounters() {
    emit(state.copyWith(successCount: 0, failedCount: 0));
  }

  @override
  Future<void> close() {
    _statusCheckTimer?.cancel();
    return super.close();
  }
}
