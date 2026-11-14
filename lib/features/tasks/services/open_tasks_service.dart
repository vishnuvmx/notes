import '../../../shared/models/base_item.dart';
import '../../notes/models/text_note.dart';
import '../../../shared/models/sticky_note.dart';

/// Recurrence cadence units supported by `@repeat(...)` task metadata tokens.
enum RecurrenceUnit {
  day,
  weekdays,
  week,
  month,
  year,
}

/// Immutable recurrence rule parsed from `@repeat(...)` or `@every(...)`.
class TaskRecurrence {
  final RecurrenceUnit unit;
  final int interval;

  const TaskRecurrence({
    required this.unit,
    this.interval = 1,
  }) : assert(interval >= 1);

  static const TaskRecurrence daily = TaskRecurrence(unit: RecurrenceUnit.day);
  static const TaskRecurrence weekdays =
      TaskRecurrence(unit: RecurrenceUnit.weekdays);
  static const TaskRecurrence weekly = TaskRecurrence(unit: RecurrenceUnit.week);
  static const TaskRecurrence monthly =
      TaskRecurrence(unit: RecurrenceUnit.month);
  static const TaskRecurrence yearly = TaskRecurrence(unit: RecurrenceUnit.year);

  static final RegExp _intervalRegex = RegExp(
    r'^(?:every\s+)?(\d+)\s*(d|day|days|w|wk|wks|week|weeks|m|mo|mos|month|months|y|yr|yrs|year|years)$',
    caseSensitive: false,
  );

  /// Parses strings such as `daily`, `weekdays`, `weekly`, `monthly`, `yearly`,
  /// `2d`, `3 weeks`, or `every 2m`. Returns `null` if unrecognized.
  static TaskRecurrence? parse(String raw) {
    final normalized = raw.trim().toLowerCase();
    if (normalized.isEmpty) return null;

    switch (normalized) {
      case 'daily':
      case 'day':
      case 'every day':
        return daily;
      case 'weekdays':
      case 'weekday':
      case 'workdays':
      case 'workday':
        return weekdays;
      case 'weekly':
      case 'week':
      case 'every week':
        return weekly;
      case 'biweekly':
      case 'fortnightly':
        return const TaskRecurrence(unit: RecurrenceUnit.week, interval: 2);
      case 'monthly':
      case 'month':
      case 'every month':
        return monthly;
      case 'yearly':
      case 'annually':
      case 'year':
      case 'every year':
        return yearly;
    }

    final m = _intervalRegex.firstMatch(normalized);
    if (m == null) return null;
    final count = int.tryParse(m.group(1)!);
    if (count == null || count < 1) return null;
    final suffix = m.group(2)!.toLowerCase();

    if (suffix.startsWith('d')) {
      return TaskRecurrence(unit: RecurrenceUnit.day, interval: count);
    }
    if (suffix.startsWith('w')) {
      return TaskRecurrence(unit: RecurrenceUnit.week, interval: count);
    }
    if (suffix.startsWith('m')) {
      return TaskRecurrence(unit: RecurrenceUnit.month, interval: count);
    }
    if (suffix.startsWith('y')) {
      return TaskRecurrence(unit: RecurrenceUnit.year, interval: count);
    }
    return null;
  }

  /// Canonical Markdown token representation (e.g. `@repeat(daily)`).
  String toToken() {
    switch (unit) {
      case RecurrenceUnit.day:
        return interval == 1 ? '@repeat(daily)' : '@repeat(${interval}d)';
      case RecurrenceUnit.weekdays:
        return '@repeat(weekdays)';
      case RecurrenceUnit.week:
        return interval == 1 ? '@repeat(weekly)' : '@repeat(${interval}w)';
      case RecurrenceUnit.month:
        return interval == 1 ? '@repeat(monthly)' : '@repeat(${interval}m)';
      case RecurrenceUnit.year:
        return interval == 1 ? '@repeat(yearly)' : '@repeat(${interval}y)';
    }
  }

  /// Compact user-facing label for badges and sheets.
  String get label {
    switch (unit) {
      case RecurrenceUnit.day:
        return interval == 1 ? 'Daily' : 'Every ${interval}d';
      case RecurrenceUnit.weekdays:
        return 'Weekdays';
      case RecurrenceUnit.week:
        return interval == 1 ? 'Weekly' : 'Every ${interval}w';
      case RecurrenceUnit.month:
        return interval == 1 ? 'Monthly' : 'Every ${interval}m';
      case RecurrenceUnit.year:
        return interval == 1 ? 'Yearly' : 'Every ${interval}y';
    }
  }

  /// Computes the next due date/time strictly after [referenceNow] (or current
  /// time), advancing from [baseDue] in exact rule steps to avoid cadence drift.
  DateTime nextDueAfter(DateTime baseDue, {DateTime? referenceNow}) {
    final now = referenceNow ?? DateTime.now();
    final anchorDay = baseDue.day;
    var candidate = baseDue;
    var step = 0;

    // Advance until candidate sits strictly after `now` (and at least 1 step
    // forward from `baseDue`).
    while (!candidate.isAfter(now) || candidate == baseDue) {
      step++;
      if (step > 500) {
        // Guard against ancient dates far in the past by jumping from today.
        candidate = _stepOnce(
          DateTime(now.year, now.month, now.day, baseDue.hour, baseDue.minute),
          now.day,
        );
        break;
      }
      candidate = _stepOnce(candidate, anchorDay, stepNumber: step, origin: baseDue);
    }

    return candidate;
  }

  DateTime _stepOnce(
    DateTime current,
    int anchorDay, {
    int stepNumber = 1,
    DateTime? origin,
  }) {
    switch (unit) {
      case RecurrenceUnit.day:
        return DateTime(
          current.year,
          current.month,
          current.day + interval,
          current.hour,
          current.minute,
        );
      case RecurrenceUnit.weekdays:
        var next = DateTime(
          current.year,
          current.month,
          current.day + 1,
          current.hour,
          current.minute,
        );
        while (next.weekday == DateTime.saturday ||
            next.weekday == DateTime.sunday) {
          next = DateTime(
            next.year,
            next.month,
            next.day + 1,
            next.hour,
            next.minute,
          );
        }
        return next;
      case RecurrenceUnit.week:
        return DateTime(
          current.year,
          current.month,
          current.day + (7 * interval),
          current.hour,
          current.minute,
        );
      case RecurrenceUnit.month:
        final base = origin ?? current;
        final totalMonths = (base.year * 12 + (base.month - 1)) +
            (interval * (origin != null ? stepNumber : 1));
        final targetYear = totalMonths ~/ 12;
        final targetMonth = (totalMonths % 12) + 1;
        final maxDay = _daysInMonth(targetYear, targetMonth);
        return DateTime(
          targetYear,
          targetMonth,
          anchorDay.clamp(1, maxDay),
          current.hour,
          current.minute,
        );
      case RecurrenceUnit.year:
        final base = origin ?? current;
        final targetYear = base.year + (interval * (origin != null ? stepNumber : 1));
        final maxDay = _daysInMonth(targetYear, base.month);
        return DateTime(
          targetYear,
          base.month,
          anchorDay.clamp(1, maxDay),
          current.hour,
          current.minute,
        );
    }
  }

  static int _daysInMonth(int year, int month) {
    return DateTime(year, month + 1, 0).day;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TaskRecurrence &&
          runtimeType == other.runtimeType &&
          unit == other.unit &&
          interval == other.interval;

  @override
  int get hashCode => Object.hash(unit, interval);
}

/// Result returned when completing or toggling a checklist line.
class TaskToggleResult {
  final String updatedContent;
  final bool advancedRecurrence;
  final bool isNowDone;
  final DateTime? nextDueAt;
  final bool hasExplicitTime;
  final TaskRecurrence? recurrence;
  final String cleanText;

  const TaskToggleResult({
    required this.updatedContent,
    required this.advancedRecurrence,
    required this.isNowDone,
    this.nextDueAt,
    this.hasExplicitTime = false,
    this.recurrence,
    required this.cleanText,
  });
}

/// Parsed task metadata extracted from a Markdown checklist line.
class ParsedTaskMetadata {
  final String cleanText;
  final DateTime? dueAt;
  final bool hasExplicitTime;
  final TaskRecurrence? recurrence;

  const ParsedTaskMetadata({
    required this.cleanText,
    this.dueAt,
    this.hasExplicitTime = false,
    this.recurrence,
  });
}

/// A derived task extracted from a Markdown checklist line (`- [ ]` or `- [x]`)
/// inside a note. Markdown remains the single source of truth (`04` F3, `08` §5).
class DerivedTaskItem {
  final String noteId;
  final String noteTitle;
  final String paletteId;
  final int lineIndex;
  final String text;
  final String rawText;
  final bool isDone;
  final DateTime noteUpdatedAt;
  final DateTime? dueAt;
  final bool hasExplicitTime;
  final TaskRecurrence? recurrence;

  const DerivedTaskItem({
    required this.noteId,
    required this.noteTitle,
    required this.paletteId,
    required this.lineIndex,
    required this.text,
    String? rawText,
    required this.isDone,
    required this.noteUpdatedAt,
    this.dueAt,
    this.hasExplicitTime = false,
    this.recurrence,
  }) : rawText = rawText ?? text;

  String get id => '$noteId:$lineIndex';

  bool get hasReminder => dueAt != null || recurrence != null;

  /// Scheduled notification fire time (defaults to 09:00 local time for date-only `@due(YYYY-MM-DD)`).
  DateTime? get reminderTriggerAt {
    final due = dueAt;
    if (due == null) return null;
    if (hasExplicitTime) return due;
    return DateTime(due.year, due.month, due.day, 9, 0);
  }

  bool isDueToday([DateTime? now]) {
    final due = dueAt;
    if (due == null) return false;
    final ref = now ?? DateTime.now();
    return due.year == ref.year &&
        due.month == ref.month &&
        due.day == ref.day;
  }

  bool isOverdue([DateTime? now]) {
    if (isDone) return false;
    final due = dueAt;
    if (due == null) return false;
    final ref = now ?? DateTime.now();
    if (hasExplicitTime) {
      return due.isBefore(ref);
    }
    final todayStart = DateTime(ref.year, ref.month, ref.day);
    final dueDayStart = DateTime(due.year, due.month, due.day);
    return dueDayStart.isBefore(todayStart);
  }

  /// Human-friendly due label (`Today · 2:30 PM`, `Tomorrow`, `Overdue · Nov 12`).
  String? formatDueLabel([DateTime? now]) {
    final due = dueAt;
    if (due == null) return null;
    final ref = now ?? DateTime.now();
    final today = DateTime(ref.year, ref.month, ref.day);
    final dueDay = DateTime(due.year, due.month, due.day);
    final dayDiff = dueDay.difference(today).inDays;

    String dayPart;
    if (dayDiff == 0) {
      dayPart = 'Today';
    } else if (dayDiff == 1) {
      dayPart = 'Tomorrow';
    } else if (dayDiff == -1) {
      dayPart = 'Yesterday';
    } else {
      const months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
      ];
      dayPart = '${months[due.month - 1]} ${due.day}';
      if (due.year != ref.year) {
        dayPart = '$dayPart, ${due.year}';
      }
    }

    if (!hasExplicitTime) {
      return isOverdue(ref) ? 'Overdue · $dayPart' : dayPart;
    }

    final timePart = _formatTime12h(due);
    final label = '$dayPart · $timePart';
    return isOverdue(ref) ? 'Overdue · $label' : label;
  }

  static String _formatTime12h(DateTime dt) {
    final hour12 = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final min = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    return '$hour12:$min $period';
  }

  /// Orders tasks by urgency: overdue -> due today -> upcoming scheduled -> recurring -> unscheduled.
  int compareUrgency(DerivedTaskItem other, [DateTime? now]) {
    final ref = now ?? DateTime.now();
    final myBucket = _urgencyBucket(ref);
    final otherBucket = other._urgencyBucket(ref);
    if (myBucket != otherBucket) return myBucket.compareTo(otherBucket);

    if (dueAt != null && other.dueAt != null) {
      final byDue = dueAt!.compareTo(other.dueAt!);
      if (byDue != 0) return byDue;
    }
    return other.noteUpdatedAt.compareTo(noteUpdatedAt);
  }

  int _urgencyBucket(DateTime ref) {
    if (isOverdue(ref)) return 0;
    if (isDueToday(ref)) return 1;
    if (dueAt != null) return 2;
    if (recurrence != null) return 3;
    return 4;
  }
}

/// Service for extracting and toggling Markdown checklist tasks across workspace notes,
/// parsing `@due(...)` / `@repeat(...)` metadata, and propagating wiki-link renames (`04` M2/F3/F5, `08` §5).
class OpenTasksService {
  static final RegExp _taskLineRegex = RegExp(
    r'^(\s*[-*]\s+\[)([ xX])(\]\s+)(.+)$',
  );

  static final RegExp dueTokenRegex = RegExp(
    r'@due\(\s*([^)]+)\s*\)',
    caseSensitive: false,
  );

  static final RegExp repeatTokenRegex = RegExp(
    r'@(?:repeat|every)\(\s*([^)]+)\s*\)',
    caseSensitive: false,
  );

  static final RegExp _isoDateTimeRegex = RegExp(
    r'^(\d{4})-(\d{1,2})-(\d{1,2})(?:[T\s]+(\d{1,2}):(\d{2}))?$',
  );

  static final RegExp _relativeDateTimeRegex = RegExp(
    r'^(today|tomorrow)(?:\s+(\d{1,2}):(\d{2}))?$',
    caseSensitive: false,
  );

  /// Extracts `@due(...)` and `@repeat(...)` tokens from raw task line text
  /// and returns a cleaned display string plus structured reminder metadata.
  static ParsedTaskMetadata parseTaskMetadata(
    String rawTaskText, {
    DateTime? referenceNow,
  }) {
    final now = referenceNow ?? DateTime.now();
    DateTime? parsedDue;
    bool hasExplicitTime = false;
    TaskRecurrence? parsedRecurrence;

    final dueMatch = dueTokenRegex.firstMatch(rawTaskText);
    if (dueMatch != null) {
      final parsed = _parseDueValue(dueMatch.group(1) ?? '', now);
      if (parsed != null) {
        parsedDue = parsed.dueAt;
        hasExplicitTime = parsed.hasExplicitTime;
      }
    }

    final repeatMatch = repeatTokenRegex.firstMatch(rawTaskText);
    if (repeatMatch != null) {
      parsedRecurrence = TaskRecurrence.parse(repeatMatch.group(1) ?? '');
    }

    var cleaned = rawTaskText;
    if (dueMatch != null && parsedDue != null) {
      cleaned = cleaned.replaceFirst(dueTokenRegex, '');
    }
    if (repeatMatch != null && parsedRecurrence != null) {
      cleaned = cleaned.replaceFirst(repeatTokenRegex, '');
    }
    cleaned = cleaned.replaceAll(RegExp(r'\s{2,}'), ' ').trim();
    if (cleaned.isEmpty) {
      cleaned = rawTaskText.trim();
    }

    return ParsedTaskMetadata(
      cleanText: cleaned,
      dueAt: parsedDue,
      hasExplicitTime: hasExplicitTime,
      recurrence: parsedRecurrence,
    );
  }

  static ({DateTime dueAt, bool hasExplicitTime})? _parseDueValue(
    String raw,
    DateTime now,
  ) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;

    final relMatch = _relativeDateTimeRegex.firstMatch(trimmed);
    if (relMatch != null) {
      final keyword = relMatch.group(1)!.toLowerCase();
      final offsetDays = keyword == 'tomorrow' ? 1 : 0;
      final hourStr = relMatch.group(2);
      final minStr = relMatch.group(3);
      if (hourStr != null && minStr != null) {
        final hour = int.tryParse(hourStr);
        final min = int.tryParse(minStr);
        if (hour != null && min != null && hour >= 0 && hour <= 23 && min >= 0 && min <= 59) {
          return (
            dueAt: DateTime(now.year, now.month, now.day + offsetDays, hour, min),
            hasExplicitTime: true,
          );
        }
      }
      return (
        dueAt: DateTime(now.year, now.month, now.day + offsetDays),
        hasExplicitTime: false,
      );
    }

    final isoMatch = _isoDateTimeRegex.firstMatch(trimmed);
    if (isoMatch != null) {
      final year = int.tryParse(isoMatch.group(1)!);
      final month = int.tryParse(isoMatch.group(2)!);
      final day = int.tryParse(isoMatch.group(3)!);
      if (year == null || month == null || day == null) return null;
      if (month < 1 || month > 12 || day < 1 || day > 31) return null;

      final hourStr = isoMatch.group(4);
      final minStr = isoMatch.group(5);
      if (hourStr != null && minStr != null) {
        final hour = int.tryParse(hourStr);
        final min = int.tryParse(minStr);
        if (hour == null || min == null || hour < 0 || hour > 23 || min < 0 || min > 59) {
          return null;
        }
        final dt = DateTime(year, month, day, hour, min);
        if (dt.month != month || dt.day != day) return null;
        return (dueAt: dt, hasExplicitTime: true);
      }

      final dt = DateTime(year, month, day);
      if (dt.month != month || dt.day != day) return null;
      return (dueAt: dt, hasExplicitTime: false);
    }

    return null;
  }

  /// Formats [dueAt] into a canonical `@due(YYYY-MM-DD)` or `@due(YYYY-MM-DD HH:MM)` token.
  static String formatDueToken(DateTime dueAt, {bool hasExplicitTime = false}) {
    final y = dueAt.year.toString().padLeft(4, '0');
    final m = dueAt.month.toString().padLeft(2, '0');
    final d = dueAt.day.toString().padLeft(2, '0');
    if (!hasExplicitTime) {
      return '@due($y-$m-$d)';
    }
    final hh = dueAt.hour.toString().padLeft(2, '0');
    final mm = dueAt.minute.toString().padLeft(2, '0');
    return '@due($y-$m-$d $hh:$mm)';
  }

  /// Extracts all tasks from active (non-trash, non-inbox) notes, ordered by urgency.
  static List<DerivedTaskItem> extractTasks(
    Iterable<BaseWorkspaceItem> items, {
    bool includeCompleted = false,
    DateTime? now,
  }) {
    final ref = now ?? DateTime.now();
    final results = <DerivedTaskItem>[];

    for (final item in items) {
      if (item.isTrash || item.isInbox) continue;
      String? body;
      if (item is TextNote) {
        body = item.content;
      } else if (item is StickyNote) {
        body = item.content;
      }
      if (body == null || body.isEmpty) continue;

      final lines = body.split('\n');
      bool inCodeFence = false;

      for (int i = 0; i < lines.length; i++) {
        final rawLine = lines[i];
        final trimmed = rawLine.trimLeft();
        if (trimmed.startsWith('```')) {
          inCodeFence = !inCodeFence;
          continue;
        }
        if (inCodeFence) continue;

        final match = _taskLineRegex.firstMatch(rawLine);
        if (match != null) {
          final mark = match.group(2)!;
          final isDone = mark.toLowerCase() == 'x';
          if (!includeCompleted && isDone) continue;

          final rawTaskText = match.group(4)!.trim();
          if (rawTaskText.isEmpty) continue;

          final parsed = parseTaskMetadata(rawTaskText, referenceNow: ref);

          results.add(
            DerivedTaskItem(
              noteId: item.id,
              noteTitle: item.title.trim().isEmpty ? 'Untitled' : item.title,
              paletteId: item.paletteId,
              lineIndex: i,
              text: parsed.cleanText,
              rawText: rawTaskText,
              isDone: isDone,
              noteUpdatedAt: item.updatedAt,
              dueAt: parsed.dueAt,
              hasExplicitTime: parsed.hasExplicitTime,
              recurrence: parsed.recurrence,
            ),
          );
        }
      }
    }

    results.sort((a, b) => a.compareUrgency(b, ref));
    return results;
  }

  /// Toggles the checkbox state on [lineIndex] of [markdownContent].
  /// When checking an open recurring task (`@repeat(...)`), advances `@due(...)`
  /// to the next occurrence in-place and keeps `[ ]`.
  /// Returns the updated Markdown string, or `null` if [lineIndex] is invalid.
  static String? toggleTaskAtLine(
    String markdownContent,
    int lineIndex, {
    DateTime? now,
  }) {
    return completeOrToggleTaskAtLine(
      markdownContent,
      lineIndex,
      now: now,
    )?.updatedContent;
  }

  /// Detailed version of [toggleTaskAtLine] returning recurrence advancement info.
  static TaskToggleResult? completeOrToggleTaskAtLine(
    String markdownContent,
    int lineIndex, {
    DateTime? now,
  }) {
    final ref = now ?? DateTime.now();
    final lines = markdownContent.split('\n');
    if (lineIndex < 0 || lineIndex >= lines.length) return null;

    final match = _taskLineRegex.firstMatch(lines[lineIndex]);
    if (match == null) return null;

    final prefix = match.group(1)!;
    final currentMark = match.group(2)!;
    final middle = match.group(3)!;
    final rest = match.group(4)!;
    final wasDone = currentMark.toLowerCase() == 'x';
    final parsed = parseTaskMetadata(rest, referenceNow: ref);

    if (!wasDone && parsed.recurrence != null) {
      final baseDue = parsed.dueAt ??
          DateTime(ref.year, ref.month, ref.day);
      final nextDue = parsed.recurrence!.nextDueAfter(
        baseDue,
        referenceNow: ref,
      );
      final updatedRest = _applyReminderTokens(
        rest,
        dueAt: nextDue,
        hasExplicitTime: parsed.hasExplicitTime,
        recurrence: parsed.recurrence,
      );
      lines[lineIndex] = '$prefix $middle$updatedRest';
      return TaskToggleResult(
        updatedContent: lines.join('\n'),
        advancedRecurrence: true,
        isNowDone: false,
        nextDueAt: nextDue,
        hasExplicitTime: parsed.hasExplicitTime,
        recurrence: parsed.recurrence,
        cleanText: parsed.cleanText,
      );
    }

    final nextMark = wasDone ? ' ' : 'x';
    lines[lineIndex] = '$prefix$nextMark$middle$rest';
    return TaskToggleResult(
      updatedContent: lines.join('\n'),
      advancedRecurrence: false,
      isNowDone: !wasDone,
      nextDueAt: parsed.dueAt,
      hasExplicitTime: parsed.hasExplicitTime,
      recurrence: parsed.recurrence,
      cleanText: parsed.cleanText,
    );
  }

  /// Sets, updates, or clears `@due(...)` and `@repeat(...)` on checklist line [lineIndex].
  static String? setTaskReminderAtLine(
    String markdownContent,
    int lineIndex, {
    DateTime? dueAt,
    bool hasExplicitTime = false,
    TaskRecurrence? recurrence,
  }) {
    final lines = markdownContent.split('\n');
    if (lineIndex < 0 || lineIndex >= lines.length) return null;

    final match = _taskLineRegex.firstMatch(lines[lineIndex]);
    if (match == null) return null;

    final prefix = match.group(1)!;
    final mark = match.group(2)!;
    final middle = match.group(3)!;
    final rest = match.group(4)!;

    final updatedRest = _applyReminderTokens(
      rest,
      dueAt: dueAt,
      hasExplicitTime: hasExplicitTime,
      recurrence: recurrence,
    );
    lines[lineIndex] = '$prefix$mark$middle$updatedRest';
    return lines.join('\n');
  }

  static String _applyReminderTokens(
    String rawTaskRest, {
    required DateTime? dueAt,
    required bool hasExplicitTime,
    required TaskRecurrence? recurrence,
  }) {
    var body = rawTaskRest
        .replaceAll(dueTokenRegex, '')
        .replaceAll(repeatTokenRegex, '')
        .replaceAll(RegExp(r'\s{2,}'), ' ')
        .trim();

    final parts = <String>[if (body.isNotEmpty) body];
    if (dueAt != null) {
      parts.add(formatDueToken(dueAt, hasExplicitTime: hasExplicitTime));
    }
    if (recurrence != null) {
      parts.add(recurrence.toToken());
    }
    return parts.join(' ').trim();
  }

  /// Rewrites `[[oldTitle]]`, `[[oldTitle|alias]]`, `[[oldTitle#heading]]`, and
  /// `![[oldTitle...]]` references inside [markdown] to [newTitle].
  static String rewriteWikiLinks(
    String markdown, {
    required String oldTitle,
    required String newTitle,
  }) {
    final oldTrimmed = oldTitle.trim();
    final newTrimmed = newTitle.trim();
    if (oldTrimmed.isEmpty ||
        newTrimmed.isEmpty ||
        oldTrimmed.toLowerCase() == newTrimmed.toLowerCase()) {
      return markdown;
    }

    final escapedOld = RegExp.escape(oldTrimmed);
    final pattern = RegExp(
      r'(!?\[\[)(' + escapedOld + r')((?:#[^\]|]+)?(?:\|[^\]]+)?)(\]\])',
      caseSensitive: false,
    );

    return markdown.replaceAllMapped(pattern, (m) {
      final open = m.group(1)!;
      final suffix = m.group(3) ?? '';
      final close = m.group(4)!;
      return '$open$newTrimmed$suffix$close';
    });
  }
}
