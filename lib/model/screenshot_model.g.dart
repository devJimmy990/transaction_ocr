// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'screenshot_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ScreenshotModelAdapter extends TypeAdapter<ScreenshotModel> {
  @override
  final int typeId = 1;

  @override
  ScreenshotModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ScreenshotModel(
      id: fields[0] as String,
      imagePath: fields[1] as String?,
      extractedText: fields[2] as String?,
      timestamp: fields[3] as DateTime,
      status: fields[4] as ScreenshotStatus,
      errorMessage: fields[5] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, ScreenshotModel obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.imagePath)
      ..writeByte(2)
      ..write(obj.extractedText)
      ..writeByte(3)
      ..write(obj.timestamp)
      ..writeByte(4)
      ..write(obj.status)
      ..writeByte(5)
      ..write(obj.errorMessage);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ScreenshotModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ScreenshotStatusAdapter extends TypeAdapter<ScreenshotStatus> {
  @override
  final int typeId = 0;

  @override
  ScreenshotStatus read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return ScreenshotStatus.success;
      case 1:
        return ScreenshotStatus.failed;
      default:
        return ScreenshotStatus.success;
    }
  }

  @override
  void write(BinaryWriter writer, ScreenshotStatus obj) {
    switch (obj) {
      case ScreenshotStatus.success:
        writer.writeByte(0);
        break;
      case ScreenshotStatus.failed:
        writer.writeByte(1);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ScreenshotStatusAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
