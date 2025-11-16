import 'package:get_it/get_it.dart';
import 'package:local_ocr/core/database/screenshot_queries.dart';
import 'package:local_ocr/core/database/sqf_database.dart';
import 'package:local_ocr/core/database/transaction_queries.dart';
import 'package:local_ocr/core/helper/screenshot_service.dart';
import 'package:local_ocr/cubit/screenshot/controllers/screenshot_data_source.dart';
import 'package:local_ocr/cubit/screenshot/controllers/screenshot_repository.dart';
import 'package:local_ocr/cubit/screenshot/screenshot_cubit.dart';
import 'package:local_ocr/cubit/transaction_ocr/controllers/transaction_data_source.dart';
import 'package:local_ocr/cubit/transaction_ocr/controllers/transaction_repository.dart';
import 'package:local_ocr/cubit/transaction_ocr/transaction_cubit.dart';
import 'package:sqflite/sqflite.dart';

final sl = GetIt.instance;

Future<void> setupServiceLocator() async {
  // Database
  await _registerDatabase();

  _registerScreenshotController();
  _registerTransactionController();
  // Screenshot Service
  sl.registerLazySingleton<ScreenshotService>(() => ScreenshotService());
}

Future<void> _registerDatabase() async {
  String dbPath = await getDatabasesPath();
  String path = "$dbPath/local_ocr.db";

  final db = await openDatabase(
    path,
    version: 1,
    onCreate: SqfDatabase.onCreate,
  );

  sl.registerLazySingleton<SqfDatabase>(() => SqfDatabase());
  sl.registerLazySingleton<ScreenshotQueries>(() => ScreenshotQueries(db));
  sl.registerLazySingleton<TransactionQueries>(() => TransactionQueries(db));
}

void _registerTransactionController() {
  sl.registerLazySingleton<TransactionDataSource>(
    () => TransactionDataSource(sl()),
  );
  sl.registerLazySingleton<TransactionRepository>(
    () => TransactionRepository(sl()),
  );
  sl.registerLazySingleton<TransactionCubit>(() => TransactionCubit(sl()));
}

void _registerScreenshotController() {
  sl.registerLazySingleton<ScreenshotDataSource>(
    () => ScreenshotDataSource(sl()),
  );
  sl.registerLazySingleton<ScreenshotRepository>(
    () => ScreenshotRepository(sl()),
  );
  sl.registerLazySingleton<ScreenshotCubit>(() => ScreenshotCubit());
}
