extension NumExtension on num {
  bool isBetween(num min, num max) => this >= min && this <= max;

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
}
