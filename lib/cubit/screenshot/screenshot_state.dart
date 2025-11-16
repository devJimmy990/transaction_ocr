import 'package:equatable/equatable.dart';

class ScreenshotState extends Equatable {
  final bool isServiceRunning;
  final bool hasPermissions;
  final int successCount;
  final int failedCount;

  const ScreenshotState({
    this.isServiceRunning = false,
    this.hasPermissions = false,
    this.successCount = 0,
    this.failedCount = 0,
  });

  ScreenshotState copyWith({
    bool? isServiceRunning,
    bool? hasPermissions,
    int? successCount,
    int? failedCount,
  }) {
    return ScreenshotState(
      isServiceRunning: isServiceRunning ?? this.isServiceRunning,
      hasPermissions: hasPermissions ?? this.hasPermissions,
      successCount: successCount ?? this.successCount,
      failedCount: failedCount ?? this.failedCount,
    );
  }

  @override
  List<Object?> get props => [
    isServiceRunning,
    hasPermissions,
    successCount,
    failedCount,
  ];
}
