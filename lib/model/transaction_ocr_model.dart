import 'dart:convert';

class TransactionOcrModel {
  final String id;
  final String type;
  final String name;
  final String phone;
  final int amount;
  final String date;
  final String reference;
  final String? imagePath;
  final String? extractedText;
  final String? arabicText;
  final String? englishText;
  final String? tesseractEnglishText;
  final DateTime timestamp;
  final String status;
  final String? errorMessage;
  final bool isReviewed;

  TransactionOcrModel({
    required this.id,
    required this.type,
    required this.name,
    required this.phone,
    required this.amount,
    required this.date,
    required this.reference,
    this.imagePath,
    this.extractedText,
    this.arabicText,
    this.englishText,
    this.tesseractEnglishText,
    required this.timestamp,
    required this.status,
    this.errorMessage,
    this.isReviewed = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'name': name,
      'phone': phone,
      'amount': amount,
      'date': date,
      'reference': reference,
      'imagePath': imagePath,
      'extractedText': extractedText,
      'arabicText': arabicText,
      'englishText': englishText,
      'tesseractEnglishText': tesseractEnglishText,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'status': status,
      'errorMessage': errorMessage,
      'isReviewed': isReviewed ? 1 : 0,
    };
  }

  factory TransactionOcrModel.fromMap(Map<String, dynamic> map) {
    return TransactionOcrModel(
      id: map['id'],
      type: map['type'],
      name: map['name'],
      phone: map['phone'],
      amount: map['amount'],
      date: map['date'],
      reference: map['reference'] ?? '',
      imagePath: map['imagePath'],
      extractedText: map['extractedText'],
      arabicText: map['arabicText'],
      englishText: map['englishText'],
      tesseractEnglishText: map['tesseractEnglishText'],
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp']),
      status: map['status'],
      errorMessage: map['errorMessage'],
      isReviewed: map['isReviewed'] == 1,
    );
  }

  TransactionOcrModel copyWith({
    bool? isReviewed,
    String? status,
    String? errorMessage,
  }) {
    return TransactionOcrModel(
      id: id,
      type: type,
      name: name,
      phone: phone,
      amount: amount,
      date: date,
      reference: reference,
      imagePath: imagePath,
      extractedText: extractedText,
      arabicText: arabicText,
      englishText: englishText,
      tesseractEnglishText: tesseractEnglishText,
      timestamp: timestamp,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      isReviewed: isReviewed ?? this.isReviewed,
    );
  }

  String toJson() => json.encode(toMap());

  factory TransactionOcrModel.fromJson(String source) =>
      TransactionOcrModel.fromMap(json.decode(source));
}
