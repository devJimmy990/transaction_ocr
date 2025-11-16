import 'dart:io';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:local_ocr/core/database_helper.dart';
import 'package:local_ocr/core/ocr_service.dart';
import 'package:local_ocr/model/transaction_ocr_model.dart';

import 'transaction_ocr_state.dart';

class TransactionOcrCubit extends Cubit<TransactionOcrState> {
  final DatabaseHelper _databaseHelper;

  TransactionOcrCubit(this._databaseHelper)
    : super(const TransactionOcrState());

  Future<void> loadTransactions() async {
    emit(state.copyWith(isLoading: true));
    try {
      final transactions = await _databaseHelper.getTransactions();
      final statistics = await _databaseHelper.getStatistics();
      emit(
        state.copyWith(
          transactions: transactions,
          statistics: statistics,
          isLoading: false,
        ),
      );
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  Future<void> performOCR(String imagePath) async {
    try {
      final result = await OcrService.startService(imagePath);

      final transaction = TransactionOcrModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        type: result.type,
        name: result.name,
        phone: result.phone,
        amount: result.amount,
        date: result.date,
        reference: result.reference,
        extractedText: result.arabicText,
        arabicText: result.arabicText,
        englishText: result.englishText,
        tesseractEnglishText: result.tesseractEnglishText,
        timestamp: DateTime.now(),
        status: 'success',
      );

      await _databaseHelper.insertTransaction(transaction);

      // Delete image after success
      final file = File(imagePath);
      if (await file.exists()) await file.delete();

      // Notify overlay to update success count
      FlutterOverlayWindow.shareData({'action': 'update_success'});

      await loadTransactions();
    } catch (e) {
      final failedTransaction = TransactionOcrModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        type: '',
        name: '',
        phone: '',
        amount: 0,
        date: '',
        reference: '',
        imagePath: imagePath,
        timestamp: DateTime.now(),
        status: 'failed',
        errorMessage: e.toString(),
      );

      await _databaseHelper.insertTransaction(failedTransaction);

      // Notify overlay to update failed count
      FlutterOverlayWindow.shareData({'action': 'update_failed'});

      await loadTransactions();
    }
  }

  Future<void> toggleReviewStatus(String id) async {
    try {
      final transaction = state.transactions.firstWhere((t) => t.id == id);
      final updated = transaction.copyWith(isReviewed: !transaction.isReviewed);
      await _databaseHelper.updateTransaction(updated);
      await loadTransactions();
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  Future<void> deleteTransaction(String id) async {
    try {
      final transaction = state.transactions.firstWhere((t) => t.id == id);
      if (transaction.imagePath != null) {
        final file = File(transaction.imagePath!);
        if (await file.exists()) await file.delete();
      }

      await _databaseHelper.deleteTransaction(id);
      emit(state.copyWith(action: 'deleted'));
      await loadTransactions();
    } catch (e) {
      emit(state.copyWith(error: e.toString(), action: 'deleted'));
    }
  }

  Future<void> deleteAllTransactions() async {
    try {
      await _databaseHelper.deleteAllTransactions();
      emit(state.copyWith(action: 'deleted-all'));
      await loadTransactions();
    } catch (e) {
      emit(state.copyWith(error: e.toString(), action: 'deleted-all'));
    }
  }

  void setFilter(TransactionFilter filter) {
    emit(state.copyWith(filter: filter));
  }

  void resetStatus() {
    emit(state.copyWith(action: null, error: null));
  }

  Future<void> retryFailedTransaction(String id) async {
    try {
      final transaction = state.transactions.firstWhere((t) => t.id == id);
      if (transaction.imagePath != null) {
        await performOCR(transaction.imagePath!);
        await _databaseHelper.deleteTransaction(id);
        await loadTransactions();
      }
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }
}
