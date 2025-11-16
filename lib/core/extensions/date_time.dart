import 'package:intl/intl.dart';

extension DateTimeExtension on DateTime {
  String toArabic() =>
      "${DateFormat('dd/MM/yyyy hh:mm').format(this)} "
      "${DateFormat('a', "ar").format(this)}";

  String toShort() => DateFormat('dd/MM/yyyy').format(this);

  String toNormal() => DateFormat('dd/MM/yyyy hh:mm').format(this);

  String toCustomFrmat(String format) => DateFormat(format).format(this);

  bool isSameDate(DateTime other) =>
      year == other.year && month == other.month && day == other.day;
}
