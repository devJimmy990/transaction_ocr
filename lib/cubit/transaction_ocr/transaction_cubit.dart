import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:local_ocr/cubit/transaction_ocr/controllers/transaction_repository.dart';

import 'transaction_state.dart';

class TransactionCubit extends Cubit<TransactionState> {
  final TransactionRepository _repository;

  TransactionCubit(this._repository) : super(const TransactionState()) {
    loadTransactions();
  }

  Future<void> loadTransactions() async {
    emit(state.copyWith(isLoading: true));

    try {
      final transactions = await _repository.getTransactions();
      final statistics = await _repository.getStatistics();

      emit(
        state.copyWith(
          transactions: transactions,
          statistics: statistics,
          isLoading: false,
          error: null,
        ),
      );
    } catch (e) {
      print('❌ Error loading transactions: $e');
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  Future<void> toggleReviewStatus(String id) async {
    try {
      final transaction = state.transactions.firstWhere((t) => t.id == id);
      final updated = transaction.copyWith(isReviewed: !transaction.isReviewed);

      await _repository.updateTransaction(updated);
      await loadTransactions();
    } catch (e) {
      print('❌ Error toggling review: $e');
      emit(state.copyWith(error: e.toString()));
    }
  }

  Future<void> deleteTransaction(String id) async {
    try {
      // final transaction = state.transactions.firstWhere((t) => t.id == id);

      // // حذف الصورة إذا كانت موجودة
      // if (transaction.imagePath != null && transaction.imagePath!.isNotEmpty) {
      //   final file = File(transaction.imagePath!);
      //   if (await file.exists()) {
      //     await file.delete();
      //   }
      // }

      await _repository.deleteTransaction(id);
      emit(state.copyWith(action: 'deleted'));
      await loadTransactions();
    } catch (e) {
      print('❌ Error deleting transaction: $e');
      emit(state.copyWith(error: e.toString(), action: 'deleted'));
    }
  }

  Future<void> deleteAllTransactions() async {
    try {
      // // حذف جميع الصور المرتبطة
      // for (var transaction in state.transactions) {
      //   if (transaction.imagePath != null &&
      //       transaction.imagePath!.isNotEmpty) {
      //     final file = File(transaction.imagePath!);
      //     if (await file.exists()) {
      //       await file.delete();
      //     }
      //   }
      // }

      await _repository.deleteAllTransactions();
      emit(state.copyWith(action: 'deleted-all'));
      await loadTransactions();
    } catch (e) {
      print('❌ Error deleting all transactions: $e');
      emit(state.copyWith(error: e.toString(), action: 'deleted-all'));
    }
  }

  void setFilter(TransactionFilter filter) {
    emit(state.copyWith(filter: filter));
  }

  void resetStatus() {
    emit(state.copyWith(action: null, error: null));
  }

  // Future<void> retryFailedTransaction(String id) async {
  //   try {
  //     final transaction = state.transactions.firstWhere((t) => t.id == id);

  //     if (transaction.imagePath != null && transaction.imagePath!.isNotEmpty) {
  //       // إضافة للـ Queue
  //       await OCRQueueManager.instance.retryFailedTransaction(transaction);

  //       emit(state.copyWith(action: 'retry-started'));
  //       await loadTransactions();
  //     }
  //   } catch (e) {
  //     print('❌ Error retrying transaction: $e');
  //     emit(state.copyWith(error: e.toString()));
  //   }
  // }

  /// الحصول على المعاملات المفلترة
}
