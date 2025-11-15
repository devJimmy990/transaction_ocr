import 'dart:io';

import 'package:flutter/material.dart';
import 'package:local_ocr/core/ocr_service.dart';
import 'package:local_ocr/presentation/widgets/scanning_indicator.dart';

class OcrScreen extends StatefulWidget {
  const OcrScreen({super.key});

  @override
  State<OcrScreen> createState() => _OcrScreenState();
}

class _OcrScreenState extends State<OcrScreen> {
  String _ocrText = '', path = '';
  bool _scanning = false, _showCard = false, _imageLoaded = false;

  /// Start OCR process
  Future<void> _performOCR(String imagePath) async {
    try {
      final (
        :type,
        :name,
        :date,
        :phone,
        :amount,
        :reference,
        :croppedWidth,
        :croppedHeight,
        :originalWidth,
        :originalHeight,
        :arabicText,
        :tesseractEnglishText,
        :englishText,
      ) = await OcrService.startService(imagePath);

      setState(() {
        _showCard = true;
        _ocrText = """
Original Aspect: ($originalWidth : $originalHeight)
Cropped Aspect: ($croppedWidth : $croppedHeight)

Type: $type
Name: $name
Date: $date
Phone: $phone
Amount: $amount
Reference: $reference

--- Arabic Text ---
$arabicText

--- Tesseract English Text ---
$tesseractEnglishText

--- English Text ---
$englishText
""";
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error processing image: $e')));
    } finally {
      setState(() => _scanning = false);
    }
  }

  /// Start scanning animation, then OCR
  Future<void> _startScanning() async {
    setState(() => _scanning = true);
    await Future.delayed(const Duration(seconds: 3)); // scanning duration
    await _performOCR(path);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Text Recognition'), centerTitle: true),
      body:
          path.isNotEmpty
              ? Center(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return Stack(
                      alignment: Alignment.center,
                      children: [
                        // 🖼️ Image display
                        Image.file(
                          File(path),
                          fit: BoxFit.contain,
                          frameBuilder: (
                            context,
                            child,
                            frame,
                            wasSynchronouslyLoaded,
                          ) {
                            if (frame != null && !_imageLoaded) {
                              WidgetsBinding.instance.addPostFrameCallback((
                                _,
                              ) async {
                                setState(() => _imageLoaded = true);
                                await _startScanning();
                              });
                            }
                            return child;
                          },
                        ),

                        // 🔹 Scanner effect
                        if (_scanning && _imageLoaded)
                          const Positioned.fill(child: ScanningIndicator()),

                        // 🔹 OCR result card
                        if (_showCard)
                          Center(
                            child: SizedBox(
                              width: 400,
                              child: Card(
                                elevation: 8,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Stack(
                                  children: [
                                    SingleChildScrollView(
                                      padding: const EdgeInsets.all(12),
                                      child: Text(_ocrText),
                                    ),
                                    Positioned(
                                      right: 0,
                                      top: 0,
                                      child: IconButton(
                                        icon: const Icon(Icons.visibility_off),
                                        onPressed:
                                            () => setState(
                                              () => _showCard = false,
                                            ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              )
              : const Center(child: Text("No Image Selected")),
    );
  }
}
