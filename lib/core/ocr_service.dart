import 'dart:io';

import 'package:flutter_tesseract_ocr/android_ios.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

class OcrService {
  static Future<
    ({
      int amount,
      String type,
      String name,
      String date,
      String phone,
      String reference,
      double croppedWidth,
      double croppedHeight,
      double originalWidth,
      double originalHeight,
      String arabicText,
      String tesseractEnglishText,
      String englishText,
    })
  >
  startService(String path) async {
    final (
      :file,
      :croppedWidth,
      :croppedHeight,
      :originalWidth,
      :originalHeight,
    ) = await _preprocessImage(path);

    final results = await Future.wait([
      _extractArabicText(file.path),
      _extractTesseractEnglishText(file.path),
      _extractEnglishText(file.path),
    ]);

    final englishText = '${results[2]}\n${results[1]}'.trim();

    final parsed = _OcrParser.extractValues(results[0], englishText);

    return (
      type: parsed.type,
      name: parsed.name,
      date: parsed.date,
      phone: parsed.phone,
      amount: parsed.amount,
      reference: parsed.reference,
      croppedWidth: croppedWidth,
      croppedHeight: croppedHeight,
      originalWidth: originalWidth,
      originalHeight: originalHeight,
      arabicText:
          results[0]
              .split('\n')
              .map((line) => line.trim())
              .where((line) => line.isNotEmpty) // remove empty lines
              .join('\n')
              .trim(),
      tesseractEnglishText:
          results[1]
              .split('\n')
              .map((line) => line.trim())
              .where((line) => line.isNotEmpty) // remove empty lines
              .join('\n')
              .trim(),
      englishText:
          results[2]
              .split('\n')
              .map((line) => line.trim())
              .where((line) => line.isNotEmpty) // remove empty lines
              .join('\n')
              .trim(),
    );
  }

  static Future<
    ({
      File file,
      double croppedWidth,
      double croppedHeight,
      double originalWidth,
      double originalHeight,
    })
  >
  _preprocessImage(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) throw Exception("File not found: $filePath");

    final bytes = await file.readAsBytes();
    final img.Image? original = img.decodeImage(bytes);
    if (original == null) throw Exception("Error decoding image");

    final gray = img.grayscale(original);

    final contrast = img.adjustColor(gray, contrast: 1.5);

    final smooth = img.gaussianBlur(contrast, radius: 1);

    final normalized = img.normalize(smooth, min: 0, max: 255);

    final startY = 400;
    final halfWidth = (normalized.width / 2).round();

    final cropped = img.copyCrop(
      normalized,
      x: 0,
      y: startY.clamp(0, normalized.height - 1),
      width: halfWidth,
      height: normalized.height,
    );

    // 6. Save processed file
    final dir = await getTemporaryDirectory();
    final processedPath =
        '${dir.path}/processed_${DateTime.now().millisecondsSinceEpoch}.png';
    final processedFile = File(processedPath);
    await processedFile.writeAsBytes(img.encodePng(cropped));

    return (
      file: processedFile,
      croppedWidth: cropped.width.toDouble(),
      croppedHeight: cropped.height.toDouble(),
      originalWidth: normalized.width.toDouble(),
      originalHeight: normalized.height.toDouble(),
    );
  }

  static Future<String> _extractArabicText(String path) async {
    final text = await FlutterTesseractOcr.extractText(
      path,
      language: 'ara',
      args: {"preserve_interword_spaces": "1"},
    );
    return text
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty) // remove empty lines
        .join('\n')
        .trim();
  }

  static Future<String> _extractTesseractEnglishText(String path) async {
    final text = await FlutterTesseractOcr.extractText(
      path,
      language: 'eng',
      args: {"preserve_interword_spaces": "1"},
    );
    return text
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty) // remove empty lines
        .join('\n')
        .trim();
  }

  static Future<String> _extractEnglishText(String path) async {
    // تحديد الصورة
    final inputImage = InputImage.fromFilePath(path);

    // مخصص للنص الإنجليزي فقط
    final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

    try {
      final RecognizedText recognizedText = await textRecognizer.processImage(
        inputImage,
      );

      final buffer = StringBuffer();

      for (TextBlock block in recognizedText.blocks) {
        // لو حبيت تشوف البلوك كووردنيتس:
        // final Rect rect = block.boundingBox;
        // final List<Point<int>> cornerPoints = block.cornerPoints;
        // final List<String> languages = block.recognizedLanguages;

        for (TextLine line in block.lines) {
          final String lineText = line.text.trim();

          // هنا نقدر نفلتر الأسطر اللي فعلاً إنجليزية (يعني مفيهاش حروف عربية)
          if (_isEnglish(lineText)) {
            buffer.writeln(lineText);
          }

          // لو محتاج مستوى العنصر الأصغر (كلمة أو رقم):
          // for (TextElement element in line.elements) {
          //   buffer.write("${element.text} ");
          // }
        }
      }

      // الناتج النهائي بعد تجميع الأسطر
      return buffer.toString().trim();
    } catch (e) {
      print("Error extracting English text: $e");
      return '';
    } finally {
      textRecognizer.close();
    }
  }

  static bool _isEnglish(String text) {
    return RegExp(r'^[a-zA-Z0-9\s.,:/\-]+$').hasMatch(text);
  }
}

class _OcrParser {
  static String extractType(String text) {
    if (text.contains("ستقبال")) {
      return "إستقبال";
    } else if (text.contains("رسال")) {
      return "إرسال";
    }
    return "إستقبال";
  }

  static ({
    String name,
    String type,
    String date,
    String phone,
    int amount,
    String reference,
  })
  extractValues(String arabicText, String englishText) {
    final arabicLines =
        arabicText
            .split('\n')
            .map((l) => l.trim())
            .where((l) => l.isNotEmpty)
            .toList();
    final englishLines =
        englishText
            .split('\n')
            .map((l) => l.toLowerCase().trim())
            .where((l) => l.isNotEmpty)
            .toList();

    double amount = 0.0;
    String name = '';
    String phone = '';
    String reference = '';
    String date = "";
    String type = extractType(arabicLines.join(','));

    // Extract name prioritizing Arabic text, fallback to English
    final namePattern = RegExp(r'^[\p{Letter}\s]+$', unicode: true);
    for (var line in arabicLines) {
      if (namePattern.hasMatch(line) &&
          !RegExp(r'\d').hasMatch(line) &&
          !line.contains("نقدية") &&
          !line.contains("سحب") &&
          !line.contains("expaynet") &&
          line.length > 8) {
        name = line;
        break;
      }
    }
    if (name.isEmpty) {
      for (var line in englishLines) {
        if (namePattern.hasMatch(line) &&
            !RegExp(r'\d').hasMatch(line) &&
            line.length > 8) {
          name = line
              .split(" ")
              .map((w) => w[0].toUpperCase() + w.substring(1))
              .join(" ");
          break;
        }
      }
    }

    // Extract other fields from English text
    for (var line in englishLines) {
      if (phone.isEmpty && _isNumberPattern(line)) {
        phone = line.substring(3);
      } else if (amount == 0.0 && _isAmountPattern(line)) {
        final amtStr = _extractAmount(line);
        if (amtStr != null) {
          amount = double.parse(amtStr);
        }
      } else if (date.isEmpty && _isDatePattern(line)) {
        date = _extractDate(line);
      } else if (reference.isEmpty && _isReferencePattern(line)) {
        reference = line;
      }
    }

    return (
      type: type,
      name: name,
      date: date,
      phone: phone,
      reference: reference,
      amount: amount.toInt(),
    );
  }

  static bool _isNumberPattern(String line) =>
      line.startsWith("00201") && RegExp(r'^00201[0125]\d{8}$').hasMatch(line);

  static bool _isAmountPattern(String line) => RegExp(
    r'(?:pa|pe|p:|p.a|p.e|p|p.2|p.o)([\d.,]+){1,}',
  ).hasMatch(line.replaceAll(" ", ""));

  static bool _isDatePattern(String line) =>
      line.length > 10 && (line.contains(" am") || line.contains(" pm"));

  static bool _isReferencePattern(String line) =>
      RegExp(r'^(?=.*\d)[a-zA-Z0-9]{6,10}$').hasMatch(line);

  static String _extractDate(String line) {
    if (line.contains(" 1 ")) {
      line = line.replaceAll(" 1 ", " ");
    }
    final meridiem = line.contains("pm") ? "PM" : "AM";

    var normalized = line.replaceAll('.', ':');
    normalized = normalized.replaceAll(RegExp(r'[a-z\s|]'), '');

    final date = normalized.substring(0, 10);
    final time = normalized.substring(10);
    final parts = time.split(":");

    var hour = parts[0];
    var min = parts[1];

    if (double.tryParse(hour) != null && double.parse(hour) > 12) {
      hour = hour.substring(1);
    }

    return "$date | $hour:$min $meridiem";
  }

  static String? _extractAmount(String line) {
    final match = RegExp(r'([\d.]+)').firstMatch(line);
    if (match == null) return null;
    final amountStr = match.group(1)!.replaceAll(RegExp(r'[^0-9.]'), '');
    final amount = double.tryParse(amountStr);
    return amount != null && amount >= 0 ? amountStr : null;
  }
}
