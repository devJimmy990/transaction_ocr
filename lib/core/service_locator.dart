import 'package:get_it/get_it.dart';
import 'package:local_ocr/core/database_helper.dart';
import 'package:local_ocr/cubit/screenshot/screenshot_cubit.dart';
import 'package:local_ocr/cubit/transaction_ocr/transaction_ocr_cubit.dart';

final sl = GetIt.instance;

Future<void> setupServiceLocator() async {
  // Database
  sl.registerLazySingleton<DatabaseHelper>(() => DatabaseHelper());
  await sl<DatabaseHelper>().initDatabase();

  // Cubits
  sl.registerFactory<ScreenshotCubit>(() => ScreenshotCubit());
  sl.registerFactory<TransactionOcrCubit>(
    () => TransactionOcrCubit(sl<DatabaseHelper>()),
  );
}
