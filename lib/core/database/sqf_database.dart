import 'package:sqflite/sqflite.dart';

class SqfDatabase {
  static Future<void> onCreate(Database db, int version) async {
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

    await db.execute('''
          CREATE TABLE screenshots (
          id TEXT PRIMARY KEY,
          imagePath TEXT,
          extractedText TEXT,
          timestamp INTEGER,
          status INTEGER,
          errorMessage TEXT
          )
        ''');
  }
}
