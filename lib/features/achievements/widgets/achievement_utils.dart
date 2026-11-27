import '../../../domain/date_key.dart' as dk;

/// Formats an achievement's latest unlock date relative to [today].
String formatAchievementDate(String? latestDate, DateTime today) {
  if (latestDate == null || latestDate.isEmpty) return '';
  final cleanToday = dk.dateOnly(today);
  final DateTime parsed;
  try {
    parsed = dk.parseDateKey(latestDate);
  } catch (_) {
    return latestDate;
  }
  final utcToday = DateTime.utc(cleanToday.year, cleanToday.month, cleanToday.day);
  final utcParsed = DateTime.utc(parsed.year, parsed.month, parsed.day);
  final diff = utcToday.difference(utcParsed).inDays;
  if (diff == 0) return '今天获得';
  if (diff >= 1 && diff <= 30) return '$diff天前获得';
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
