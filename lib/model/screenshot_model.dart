import 'package:hive/hive.dart';

part 'screenshot_model.g.dart';

@HiveType(typeId: 0)
enum ScreenshotStatus {
  @HiveField(0)
  success,
  @HiveField(1)
  failed,
}

@HiveType(typeId: 1)
class ScreenshotModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String? imagePath; // null if success and deleted

  @HiveField(2)
  final String? extractedText;

  @HiveField(3)
  final DateTime timestamp;

  @HiveField(4)
  final ScreenshotStatus status;

  @HiveField(5)
  final String? errorMessage;

  ScreenshotModel({
    required this.id,
    this.imagePath,
    this.extractedText,
    required this.timestamp,
    required this.status,
    this.errorMessage,
  });
}
