import 'package:local_ocr/core/database/transaction_queries.dart';

class TransactionDataSource {
  final TransactionQueries _queries;

  TransactionDataSource(this._queries);

  Future<Map<String, dynamic>> getStaticstics() async {
    try {
      return await _queries.getStatistics();
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getTransactions() async {
    try {
      return await _queries.getAll();
    } catch (e) {
      rethrow;
    }
  }

  Future<int> insertTransaction(Map<String, dynamic> payload) async {
    try {
      return await _queries.insert(payload);
    } catch (e) {
      rethrow;
    }
  }

  Future<int> updateTransaction(String id, Map<String, dynamic> payload) async {
    try {
      return await _queries.update(id, payload);
    } catch (e) {
      rethrow;
    }
  }

  Future<int> deleteTransaction(String id) async {
    try {
      return await _queries.delete(id);
    } catch (e) {
      rethrow;
    }
  }

  Future<int> deleteAllTransactions() async {
    try {
      return await _queries.deleteAll();
    } catch (e) {
      rethrow;
    }
  }
}
