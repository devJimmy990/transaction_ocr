import 'package:equatable/equatable.dart';
import 'package:local_ocr/model/transaction_ocr_model.dart';

enum TransactionFilter { all, reviewed, notReviewed, success, failed }

class TransactionOcrState extends Equatable {
  final List<TransactionOcrModel> transactions;
  final TransactionFilter filter;
  final bool isLoading;
  final String? error;
  final String? action;
  final Map<String, int> statistics;

  const TransactionOcrState({
    this.transactions = const [],
    this.filter = TransactionFilter.all,
    this.isLoading = false,
    this.error,
    this.action,
    this.statistics = const {},
  });

  TransactionOcrState copyWith({
    List<TransactionOcrModel>? transactions,
    TransactionFilter? filter,
    bool? isLoading,
    String? error,
    String? action,
    Map<String, int>? statistics,
  }) {
    return TransactionOcrState(
      transactions: transactions ?? this.transactions,
      filter: filter ?? this.filter,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      action: action,
      statistics: statistics ?? this.statistics,
    );
  }

  @override
  List<Object?> get props => [
    transactions,
    filter,
    isLoading,
    error,
    action,
    statistics,
  ];
}
