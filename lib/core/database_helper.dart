import 'package:local_ocr/model/transaction_ocr_model.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await initDatabase();
    return _database!;
  }

  Future<Database> initDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, 'transactions_ocr.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE transactions (
            id TEXT PRIMARY KEY,
            type TEXT NOT NULL,
            name TEXT NOT NULL,
            phone TEXT NOT NULL,
            amount INTEGER NOT NULL,
            date TEXT NOT NULL,
            reference TEXT,
            imagePath TEXT,
            extractedText TEXT,
            arabicText TEXT,
            englishText TEXT,
            tesseractEnglishText TEXT,
            timestamp INTEGER NOT NULL,
            status TEXT NOT NULL,
            errorMessage TEXT,
            isReviewed INTEGER DEFAULT 0
          )
        ''');
      },
    );
  }

  Future<int> insertTransaction(TransactionOcrModel transaction) async {
    final db = await database;
    return await db.insert(
      'transactions',
      transaction.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<TransactionOcrModel>> getTransactions() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'transactions',
      orderBy: 'timestamp DESC',
    );
    return List.generate(
      maps.length,
      (i) => TransactionOcrModel.fromMap(maps[i]),
    );
  }

  Future<List<TransactionOcrModel>> getTransactionsByStatus(
    String status,
  ) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'transactions',
      where: 'status = ?',
      whereArgs: [status],
      orderBy: 'timestamp DESC',
    );
    return List.generate(
      maps.length,
      (i) => TransactionOcrModel.fromMap(maps[i]),
    );
  }

  Future<int> updateTransaction(TransactionOcrModel transaction) async {
    final db = await database;
    return await db.update(
      'transactions',
      transaction.toMap(),
      where: 'id = ?',
      whereArgs: [transaction.id],
    );
  }

  Future<int> deleteTransaction(String id) async {
    final db = await database;
    return await db.delete('transactions', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteAllTransactions() async {
    final db = await database;
    return await db.delete('transactions');
  }

  Future<Map<String, int>> getStatistics() async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT 
        COUNT(*) as total,
        SUM(CASE WHEN status = 'success' THEN 1 ELSE 0 END) as success,
        SUM(CASE WHEN status = 'failed' THEN 1 ELSE 0 END) as failed,
        SUM(CASE WHEN isReviewed = 1 THEN 1 ELSE 0 END) as reviewed
      FROM transactions
    ''');

    return {
      'total': result[0]['total'] as int? ?? 0,
      'success': result[0]['success'] as int? ?? 0,
      'failed': result[0]['failed'] as int? ?? 0,
      'reviewed': result[0]['reviewed'] as int? ?? 0,
    };
  }
}
