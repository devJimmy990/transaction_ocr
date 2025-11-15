import 'package:equatable/equatable.dart';

enum TransactionType { send, receive, instapay }

class TransactionModel extends Equatable {
  final int amount;
  final DateTime date;
  final bool isReviewed;
  final TransactionType type;
  final String id, phone, userPhone, reference, name;

  const TransactionModel({
    required this.id,
    required this.date,
    required this.type,
    required this.phone,
    required this.amount,
    required this.userPhone,
    this.isReviewed = false,
    this.name = "",
    String? reference,
  }) : reference = reference ?? "";

  factory TransactionModel.fromJson(Map<String, dynamic> json) =>
      TransactionModel(
        id: json['id'] as String,
        amount: json['amount'] as int,
        phone: json['phone'] as String,
        name: json['name'] ?? "no name",
        reference: json['reference'] as String,
        userPhone: json['user_phone'] as String,
        isReviewed: json['is_reviewed'] as bool,
        type: TransactionType.values[json['type'] as int],
        date: DateTime.fromMillisecondsSinceEpoch(json['date'] as int),
      );

  Map<String, dynamic> toJson() => {
    "id": id,
    "name": name,
    "phone": phone,
    "amount": amount,
    "type": type.index,
    "reference": reference,
    "user_phone": userPhone,
    "is_reviewed": isReviewed ? 1 : 0,
    "date": date.millisecondsSinceEpoch,
  };

  TransactionModel copyWith({
    int? amount,
    bool? isReviewed,
    TransactionType? type,
  }) => TransactionModel(
    id: id,
    date: date,
    name: name,
    phone: phone,
    reference: reference,
    userPhone: userPhone,
    type: type ?? this.type,
    amount: amount ?? this.amount,
    isReviewed: isReviewed ?? this.isReviewed,
  );

  @override
  String toString() =>
      'Transaction(id: $id, reference: $reference, date: $date, type: $type, phone: $phone, amount: $amount)';

  @override
  List<Object?> get props => [
    id,
    name,
    reference,
    date,
    type,
    phone,
    amount,
    isReviewed,
    userPhone,
  ];
}
