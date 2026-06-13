class SmartTaskResult {
  const SmartTaskResult({required this.title, this.dueAt, this.reminderAt});

  final String title;
  final DateTime? dueAt;
  final DateTime? reminderAt;
}

class SmartTaskParser {
  SmartTaskParser({required DateTime Function() now}) : _now = now;

  final DateTime Function() _now;

  static final _englishDate = RegExp(
    r'\b(today|tomorrow|next week)\b',
    caseSensitive: false,
  );
  static final _englishTime = RegExp(
    r'\b(?:at\s+)?(1[0-2]|0?[1-9])(?::([0-5]\d))?\s*(am|pm)\b',
    caseSensitive: false,
  );
  static final _chineseDate = RegExp(r'(今天|明天|下周)');
  static final _chineseTime = RegExp(
    r'(上午|中午|下午|晚上|凌晨)?\s*(\d{1,2})[点時时](半|[0-5]?\d分?)?',
  );

  SmartTaskResult parse(String raw) {
    if (raw.trim().isEmpty) {
      throw const FormatException('Task title cannot be empty.');
    }
    _validateChineseTimes(raw);

    final current = _now();
    final englishDateMatch = _englishDate.firstMatch(raw);
    final chineseDateMatch = _chineseDate.firstMatch(raw);
    final englishTimeMatch = _englishTime.firstMatch(raw);
    final chineseTimeMatch = _chineseTime.firstMatch(raw);

    final dateMatch = englishDateMatch ?? chineseDateMatch;
    final timeMatch = englishTimeMatch ?? chineseTimeMatch;
    if (dateMatch == null && timeMatch == null) {
      return SmartTaskResult(title: raw.trim());
    }

    final dayOffset = _dayOffset(
      englishDateMatch?.group(1)?.toLowerCase() ?? chineseDateMatch?.group(1),
    );
    final time = englishTimeMatch != null
        ? _englishClock(englishTimeMatch)
        : chineseTimeMatch != null
        ? _chineseClock(chineseTimeMatch)
        : const (hour: 0, minute: 0);
    final dueAt = DateTime(
      current.year,
      current.month,
      current.day + dayOffset,
      time.hour,
      time.minute,
    );

    var title = raw;
    for (final match in [
      englishDateMatch,
      chineseDateMatch,
      englishTimeMatch,
      chineseTimeMatch,
    ]) {
      if (match != null) {
        title = title.replaceFirst(match.group(0)!, ' ');
      }
    }
    title = title.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (title.isEmpty) {
      throw const FormatException('Task title cannot be empty.');
    }

    return SmartTaskResult(
      title: title,
      dueAt: dueAt,
      reminderAt: timeMatch == null ? null : dueAt,
    );
  }

  void _validateChineseTimes(String raw) {
    final candidates = RegExp(
      r'(上午|中午|下午|晚上|凌晨)?\s*(\d+)[点時时](?:(\d+)分)?',
    ).allMatches(raw);
    for (final match in candidates) {
      final period = match.group(1);
      final hour = int.parse(match.group(2)!);
      final minute = int.tryParse(match.group(3) ?? '') ?? 0;
      if (hour > 23 || (period != null && hour > 12) || minute > 59) {
        throw const FormatException('Invalid Chinese time.');
      }
    }
  }

  int _dayOffset(String? phrase) {
    return switch (phrase) {
      'tomorrow' || '明天' => 1,
      'next week' || '下周' => 7,
      _ => 0,
    };
  }

  ({int hour, int minute}) _englishClock(RegExpMatch match) {
    var hour = int.parse(match.group(1)!);
    final minute = int.tryParse(match.group(2) ?? '') ?? 0;
    final period = match.group(3)!.toLowerCase();
    if (period == 'am' && hour == 12) {
      hour = 0;
    } else if (period == 'pm' && hour != 12) {
      hour += 12;
    }
    return (hour: hour, minute: minute);
  }

  ({int hour, int minute}) _chineseClock(RegExpMatch match) {
    var hour = int.parse(match.group(2)!);
    final period = match.group(1);
    if ((period == '中午' || period == '下午' || period == '晚上') && hour < 12) {
      hour += 12;
    } else if (period == '凌晨' && hour == 12) {
      hour = 0;
    }
    final minuteText = match.group(3);
    final minute = minuteText == '半'
        ? 30
        : int.tryParse((minuteText ?? '').replaceAll('分', '')) ?? 0;
    return (hour: hour, minute: minute);
  }
}
