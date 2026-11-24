import '../../../domain/date_key.dart' as dk;

/// Formats an achievement's latest unlock date relative to [today].
String formatAchievementDate(String? latestDate, DateTime today) {
  if (latestDate == null || latestDate.isEmpty) return '';
  final cleanToday = dk.dateOnly(today);
  if (latestDate == dk.dateKey(cleanToday)) return '今天获得';
  if (latestDate == dk.dateKey(dk.addDays(cleanToday, -1))) return '昨天获得';
  return latestDate;
}

/// Returns the 3 consecutive calendar month start dates ending at [today]'s month.
List<DateTime> recentThreeMonths(DateTime today) {
  final clean = dk.dateOnly(today);
  return [
    DateTime(clean.year, clean.month - 2, 1),
    DateTime(clean.year, clean.month - 1, 1),
    DateTime(clean.year, clean.month, 1),
  ];
}
