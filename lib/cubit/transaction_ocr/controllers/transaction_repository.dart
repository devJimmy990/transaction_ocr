import 'package:local_ocr/cubit/transaction_ocr/controllers/transaction_data_source.dart';
import 'package:local_ocr/model/transaction_model.dart';

class TransactionRepository {
  final TransactionDataSource _dataSource;

  TransactionRepository(this._dataSource);

  getStatistics() async {
    try {
      return await _dataSource.getStaticstics();
    } catch (e) {
      rethrow;
    }
  }

  Future<List<TransactionModel>> getTransactions() async {
    try {
      final rows = await _dataSource.getTransactions();
      return rows.map((r) => TransactionModel.fromJson(r)).toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<int> deleteAllTransactions() async {
    try {
      return await _dataSource.deleteAllTransactions();
    } catch (e) {
      rethrow;
    }
  }

  Future<int> deleteTransaction(String id) async {
    try {
      return await _dataSource.deleteTransaction(id);
    } catch (e) {
      rethrow;
    }
  }

  Future<int> insertTransaction(Map<String, dynamic> map) async {
    try {
      return _dataSource.insertTransaction(map);
    } catch (e) {
      rethrow;
    }
  }

  Future<int> updateTransaction(TransactionModel updated) async {
    try {
      return await _dataSource.updateTransaction(updated.id, updated.toJson());
    } catch (e) {
      rethrow;
    }
  }
}
