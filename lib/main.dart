import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:local_ocr/core/helper/screenshot_service.dart';
import 'package:local_ocr/core/helper/service_locator.dart';
import 'package:local_ocr/cubit/transaction_ocr/transaction_cubit.dart';
import 'package:local_ocr/presentation/screens/screenshot_control_screen.dart';
import 'package:local_ocr/presentation/widgets/floating_overlay_button.dart';

@pragma("vm:entry-point")
void overlayMain() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: FloatingOverlayButton(),
    ),
  );
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await setupServiceLocator();

  _listenToOverlayRequests();

  runApp(const MyApp());
}

void _listenToOverlayRequests() {
  FlutterOverlayWindow.overlayListener.listen((data) async {
    final action = data['action'] as String?;
    print('debug: Main App received from overlay: $action');

    switch (action) {
      case 'request_screenshot':
        print(
          "debug: Handling screenshot request from overlay with action '$action'",
        );

        // طلب screenshot من الـ Service
        await sl<ScreenshotService>().takeScreenshot();
        break;

      case 'close_service':
        // إغلاق الخدمة بالكامل
        // سيتم معالجتها في ScreenshotCubit
        break;

      case 'reset_counters':
        // إعادة تعيين العدادات
        // يمكن معالجتها في الـ Cubit إذا لزم الأمر
        break;
    }
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [BlocProvider(create: (_) => sl<TransactionCubit>())],
      child: MaterialApp(
        title: 'Screenshot OCR',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.blue,
          useMaterial3: true,
          fontFamily: 'Cairo',
        ),
        home: const ScreenshotControlScreen(),
      ),
    );
  }
}
