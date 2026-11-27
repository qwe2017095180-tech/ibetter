/// Pure-Dart date helpers. All business dates are *local calendar dates*
/// represented either as a midnight [DateTime] or a `yyyy-MM-dd` key string.
library;

String _two(int v) => v.toString().padLeft(2, '0');

/// `yyyy-MM-dd` key for the calendar day of [d].
String dateKey(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${_two(d.month)}-${_two(d.day)}';

/// Parses a `yyyy-MM-dd` key into a local midnight [DateTime].
DateTime parseDateKey(String key) {
  final parts = key.split('-');
  return DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
}

/// Strips the time component.
DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

/// Today as a local midnight [DateTime].
DateTime today() => dateOnly(DateTime.now());

/// DST-safe day arithmetic.
DateTime addDays(DateTime d, int days) => DateTime(d.year, d.month, d.day + days);

/// 0 = Sunday ... 6 = Saturday.
int weekdayIndex(DateTime d) => d.weekday % 7;

/// 0-based column index in a 7-column calendar grid, honoring [weekStartsOnMonday].
int weekdayColumnIndex(DateTime d, {bool weekStartsOnMonday = false}) =>
    weekStartsOnMonday ? (d.weekday - 1) : weekdayIndex(d);

/// First day of the week containing [d] (Sunday by default, or Monday when [weekStartsOnMonday]).
DateTime startOfWeek(DateTime d, {bool weekStartsOnMonday = false}) =>
    addDays(dateOnly(d), -weekdayColumnIndex(d, weekStartsOnMonday: weekStartsOnMonday));

/// First day of the month containing [d].
DateTime startOfMonth(DateTime d) => DateTime(d.year, d.month, 1);

/// Number of days in the month of [d].
int daysInMonth(DateTime d) => DateTime(d.year, d.month + 1, 0).day;

bool isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

/// Weekday bitmask helpers: bit0 = Sunday ... bit6 = Saturday.
const int allWeekdaysMask = 0x7F;

bool maskHas(int mask, int weekdayIdx) => (mask >> weekdayIdx) & 1 == 1;
