import 'package:flutter/material.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:local_ocr/core/ocr_processor.dart';
import 'package:local_ocr/core/screenshot_service.dart';
import 'package:local_ocr/presentation/screens/failed_transactions.dart';

import 'model/screenshot_model.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();
  Hive.registerAdapter(ScreenshotStatusAdapter());
  Hive.registerAdapter(ScreenshotModelAdapter());

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Screenshot OCR',
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      home: const HomePage2(),
    );
  }
}

class HomePage2 extends StatelessWidget {
  const HomePage2({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const HomePage()),
            );
          },
          child: const Text('اذهب إلى الصفحة الرئيسية'),
        ),
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State createState() => _HomePageState();
}

class _HomePageState extends State {
  final screenshotService = ScreenshotService();
  late OCRProcessor ocrProcessor;

  bool isServiceRunning = false;
  int successCount = 0;
  int failedCount = 0;

  @override
  void initState() {
    super.initState();

    // Initialize OCR Processor
    OCRProcessor.init(
      ocrFunction: performOCR, // Your OCR function
      screenshotService: screenshotService,
    );

    // Setup callbacks
    screenshotService.onScreenshotCaptured = (imagePath) {
      print('Screenshot captured: $imagePath');
      OCRProcessor.addToQueue(imagePath);
    };

    screenshotService.onScreenshotFailed = (imagePath) {
      print('Screenshot failed: $imagePath');
      setState(() => failedCount++);
    };

    screenshotService.onServiceStopped = () {
      setState(() => isServiceRunning = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم إيقاف خدمة التقاط الشاشة')),
      );
    };
  }

  // Your OCR function - replace with your implementation
  Future performOCR(String imagePath) async {
    // TODO: Replace with your actual OCR implementation
    // Example:
    // return await YourOCRClass.extractText(imagePath);

    await Future.delayed(const Duration(seconds: 2)); // Simulate processing
    return 'Extracted text from $imagePath';
  }

  Future startScreenshotService() async {
    // Check permissions
    final hasPermissions = await screenshotService.checkPermissions();
    if (!hasPermissions) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يجب منح الأذونات المطلوبة'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Request media projection
    final mediaProjectionGranted =
        await screenshotService.requestMediaProjection();
    if (!mediaProjectionGranted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يجب الموافقة على التقاط الشاشة'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    await screenshotService.startService();

    setState(() => isServiceRunning = true);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('تم بدء خدمة التقاط الشاشة'),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future stopScreenshotService() async {
    await screenshotService.stopService();
    setState(() => isServiceRunning = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Screenshot OCR'),
        actions: [
          IconButton(
            icon: const Icon(Icons.error_outline),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => FailedScreenshotsPage(),
                ),
              );
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Status indicator
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isServiceRunning ? Colors.green : Colors.grey[300],
              ),
              child: Icon(
                isServiceRunning ? Icons.camera_alt : Icons.camera_alt_outlined,
                size: 60,
                color: Colors.white,
              ),
            ),

            const SizedBox(height: 32),

            Text(
              isServiceRunning ? 'الخدمة نشطة' : 'الخدمة متوقفة',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 48),

            // Statistics
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildStatCard(
                  'ناجح',
                  successCount,
                  Colors.green,
                  Icons.check_circle,
                ),
                const SizedBox(width: 16),
                _buildStatCard('فاشل', failedCount, Colors.red, Icons.error),
              ],
            ),

            const SizedBox(height: 48),

            // Control button
            ElevatedButton.icon(
              onPressed:
                  isServiceRunning
                      ? stopScreenshotService
                      : startScreenshotService,
              icon: Icon(isServiceRunning ? Icons.stop : Icons.play_arrow),
              label: Text(
                isServiceRunning ? 'إيقاف الخدمة' : 'بدء التقاط الشاشة',
                style: const TextStyle(fontSize: 18),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: isServiceRunning ? Colors.red : Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, int count, Color color, IconData icon) {
    return Container(
      width: 140,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color, width: 2),
      ),
      child: Column(
        children: [
          Icon(icon, size: 40, color: color),
          const SizedBox(height: 8),
          Text(
            count.toString(),
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(label, style: TextStyle(fontSize: 16, color: color)),
        ],
      ),
    );
  }
}
