import 'package:intl/intl.dart';

extension StringExtension on String {
  String capitalize() {
    return split(" ").map((e) => e.capitalizeFirst()).join(" ");
  }

  String capitalizeFirst() {
    return "${this[0].toUpperCase()}${substring(1).toLowerCase()}";
  }

  String toArabic() {
    const arabicDigits = ["٠", "١", "٢", "٣", "٤", "٥", "٦", "٧", "٨", "٩"];
    final western = toString();
    return western.split("").map((ch) {
      if (RegExp(r'\d').hasMatch(ch)) {
        return arabicDigits[int.parse(ch)];
      }
      return ch;
    }).join();
  }

  int toInt() => int.parse(this);

  DateTime toDateTime({String pattern = 'yyyy/MM/dd HH:mm'}) {
    return DateFormat(pattern).parse(this);
  }

  DateTime toReverseDateTime({String pattern = 'dd/MM/yyyy | h:mm a'}) {
    return DateFormat(pattern).parse(this);
  }
}
