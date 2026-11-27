import '../date_key.dart';
import '../models/check_in.dart';
import '../models/habit.dart';
import 'schedule_service.dart';

/// One completed check-in row in the "历史记录" timeline.
class HistoryEntry {
  const HistoryEntry({
    required this.habit,
    required this.checkIn,
    required this.date,
    required this.timeLabel,
  });

  final Habit habit;
  final CheckIn checkIn;
  final DateTime date;

  /// `HH:mm` local time derived from [CheckIn.updatedAt].
  final String timeLabel;
}

/// All completed entries for one calendar day.
class HistoryDayGroup {
  const HistoryDayGroup({
    required this.date,
    required this.dateKey,
    required this.entries,
  });

  final DateTime date;
  final String dateKey;
  final List<HistoryEntry> entries;
}

/// All day groups inside one month (e.g. `11月, 2026`).
class HistoryMonthGroup {
  const HistoryMonthGroup({
    required this.year,
    required this.month,
    required this.days,
  });

  final int year;
  final int month;
  final List<HistoryDayGroup> days;

  String get label => '$month月, $year';
}

/// Groups completed check-ins into a reverse-chronological timeline.
class HistoryService {
  const HistoryService([this._schedule = const ScheduleService()]);

  final ScheduleService _schedule;

  List<HistoryMonthGroup> buildTimeline(
    List<Habit> habits,
    Iterable<CheckIn> checkIns,
  ) {
    final habitById = {for (final h in habits) h.id: h};
    final byDate = <String, List<HistoryEntry>>{};

    for (final c in checkIns) {
      final h = habitById[c.habitId];
      if (h == null || !_schedule.isDone(h, c.count)) continue;
      final d = parseDateKey(c.date);
      final t = c.updatedAt;
      final hh = t.hour.toString().padLeft(2, '0');
      final mm = t.minute.toString().padLeft(2, '0');
      (byDate[c.date] ??= <HistoryEntry>[]).add(HistoryEntry(
        habit: h,
        checkIn: c,
        date: d,
        timeLabel: '$hh:$mm',
      ));
    }

    if (byDate.isEmpty) return const [];

    // Sort days descending (newest first), and entries inside a day by updatedAt descending.
    final sortedKeys = byDate.keys.toList()..sort((a, b) => b.compareTo(a));
    final byMonth = <(int, int), List<HistoryDayGroup>>{};

    for (final key in sortedKeys) {
      final entries = byDate[key]!
        ..sort((a, b) => b.checkIn.updatedAt.compareTo(a.checkIn.updatedAt));
      final d = entries.first.date;
      (byMonth[(d.year, d.month)] ??= <HistoryDayGroup>[]).add(
        HistoryDayGroup(date: d, dateKey: key, entries: entries),
      );
    }

    final monthKeys = byMonth.keys.toList()
      ..sort((a, b) {
        final y = b.$1.compareTo(a.$1);
        return y != 0 ? y : b.$2.compareTo(a.$2);
      });

    return [
      for (final mk in monthKeys)
        HistoryMonthGroup(year: mk.$1, month: mk.$2, days: byMonth[mk]!),
    ];
  }
}
