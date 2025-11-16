enum ScreenshotStatus { success, failed }

class ScreenshotModel {
  final String id;
  final String? imagePath;
  final String? extractedText;
  final DateTime timestamp;
  final ScreenshotStatus status;
  final String? errorMessage;

  ScreenshotModel({
    required this.id,
    this.imagePath,
    this.extractedText,
    required this.timestamp,
    required this.status,
    this.errorMessage,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'imagePath': imagePath,
    'extractedText': extractedText,
    'timestamp': timestamp.millisecondsSinceEpoch,
    'status': status == ScreenshotStatus.success ? 0 : 1,
    'errorMessage': errorMessage,
  };

  factory ScreenshotModel.fromJson(Map<String, dynamic> map) => ScreenshotModel(
    id: map['id'] as String,
    imagePath: map['imagePath'] as String?,
    extractedText: map['extractedText'] as String?,
    timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] as int),
    status:
        (map['status'] as int) == 0
            ? ScreenshotStatus.success
            : ScreenshotStatus.failed,
    errorMessage: map['errorMessage'] as String?,
  );

  @override
  String toString() =>
      'ScreenshotModel(id: $id, status: $status, path: $imagePath)';
}
