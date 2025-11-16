import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:local_ocr/core/service_locator.dart';
import 'package:local_ocr/cubit/screenshot/screenshot_cubit.dart';
import 'package:local_ocr/cubit/transaction_ocr/transaction_ocr_cubit.dart';
import 'package:local_ocr/presentation/overlay/overlay_screen.dart';
import 'package:local_ocr/presentation/screens/screenshot_control_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await setupServiceLocator();

  _listenToOverlayRequests();

  runApp(const MyApp());
}

void _listenToOverlayRequests() {
  FlutterOverlayWindow.overlayListener.listen((data) async {
    if (data['action'] == 'request_screenshot') {
      await sl<ScreenshotCubit>().captureScreenshot();
    }
  });
}

@pragma("vm:entry-point")
void overlayMain() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    const MaterialApp(debugShowCheckedModeBanner: false, home: OverlayScreen()),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => sl<TransactionOcrCubit>()..loadTransactions(),
        ),
      ],
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
