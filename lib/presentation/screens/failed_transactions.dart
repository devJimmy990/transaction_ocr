import 'dart:io';

import 'package:flutter/material.dart';
import 'package:local_ocr/core/ocr_processor.dart';
import 'package:local_ocr/model/screenshot_model.dart';

class FailedScreenshotsPage extends StatefulWidget {
  const FailedScreenshotsPage({super.key});

  @override
  State createState() => _FailedScreenshotsPageState();
}

class _FailedScreenshotsPageState extends State {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الصور الفاشلة'),
        backgroundColor: Colors.red,
      ),
      body: FutureBuilder<List<ScreenshotModel>>(
        future: OCRProcessor.getFailedScreenshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final screenshots = snapshot.data!;
          if (screenshots.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle, size: 80, color: Colors.green),
                  SizedBox(height: 16),
                  Text('لا توجد صور فاشلة', style: TextStyle(fontSize: 18)),
                ],
              ),
            );
          }
          return ListView.builder(
            itemCount: screenshots.length,
            padding: const EdgeInsets.all(8),
            itemBuilder: (context, index) {
              return _buildScreenshotCard(screenshots[index]);
            },
          );
        },
      ),
    );
  }

  Widget _buildScreenshotCard(ScreenshotModel screenshot) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image preview
          if (screenshot.imagePath != null)
            GestureDetector(
              onTap: () => _showFullImage(screenshot.imagePath!),
              child: Container(
                height: 200,
                width: double.infinity,
                color: Colors.grey[200],
                child: Image.file(
                  File(screenshot.imagePath!),
                  fit: BoxFit.contain,
                ),
              ),
            ),

          // Info and actions
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Timestamp
                Row(
                  children: [
                    const Icon(Icons.access_time, size: 16, color: Colors.grey),
                    const SizedBox(width: 8),
                    Text(
                      _formatDateTime(screenshot.timestamp),
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // Error message
                if (screenshot.errorMessage != null)
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error, size: 16, color: Colors.red),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            screenshot.errorMessage!,
                            style: const TextStyle(
                              color: Colors.red,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 16),

                // Action buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // Retry button
                    TextButton.icon(
                      onPressed: () => _retryScreenshot(screenshot),
                      icon: const Icon(Icons.refresh, color: Colors.blue),
                      label: const Text('إعادة المحاولة'),
                      style: TextButton.styleFrom(foregroundColor: Colors.blue),
                    ),

                    const SizedBox(width: 8),

                    // Delete button
                    TextButton.icon(
                      onPressed: () => _deleteScreenshot(screenshot),
                      icon: const Icon(Icons.delete, color: Colors.red),
                      label: const Text('حذف'),
                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  void _showFullImage(String imagePath) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder:
            (context) => Scaffold(
              appBar: AppBar(
                backgroundColor: Colors.black,
                iconTheme: const IconThemeData(color: Colors.white),
              ),
              backgroundColor: Colors.black,
              body: Center(
                child: InteractiveViewer(child: Image.file(File(imagePath))),
              ),
            ),
      ),
    );
  }

  Future _retryScreenshot(ScreenshotModel screenshot) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    // await widget.ocrProcessor.retryFailed(screenshot.id);

    Navigator.pop(context); // Close loading dialog

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('تمت إضافة الصورة لقائمة المعالجة'),
        backgroundColor: Colors.green,
      ),
    );

    // await _loadFailedScreenshots();
  }

  Future _deleteScreenshot(ScreenshotModel screenshot) async {
    final confirmed = await showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('تأكيد الحذف'),
            content: const Text('هل تريد حذف هذه الصورة نهائياً؟'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('إلغاء'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('حذف'),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      // await widget.ocrProcessor.deleteFailedScreenshot(screenshot.id);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('تم الحذف بنجاح')));

      // await _loadFailedScreenshots();
    }
  }
}
