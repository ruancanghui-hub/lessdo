sealed class DeepLinkCommand {
  const DeepLinkCommand({this.successCallback});

  final Uri? successCallback;

  static DeepLinkCommand parse(Uri uri) {
    if (uri.scheme != 'lessdo' || uri.host != 'x-callback-url') {
      throw const FormatException('Unsupported deep-link origin.');
    }
    final action = uri.pathSegments.length == 1 ? uri.pathSegments.single : '';
    final callback = _parseCallback(uri.queryParameters['x-success']);
    return switch (action) {
      'create' => _parseCreate(uri, callback),
      'open' => _parseOpen(uri, callback),
      _ => throw const FormatException('Unsupported deep-link action.'),
    };
  }

  static CreateTaskCommand _parseCreate(Uri uri, Uri? callback) {
    final content = _boundedRequired(
      uri.queryParameters['content'],
      field: 'content',
    );
    final listName = _boundedOptional(
      uri.queryParameters['list'],
      field: 'list',
    );
    final date = _parseDate(uri.queryParameters['date']);
    final time = _parseTime(uri.queryParameters['time']);
    if (time != null && date == null) {
      throw const FormatException('A time requires a date.');
    }
    final scheduledAt = date == null
        ? null
        : DateTime(
            date.year,
            date.month,
            date.day,
            time?.$1 ?? 9,
            time?.$2 ?? 0,
          );
    return CreateTaskCommand(
      content: content,
      listName: listName,
      scheduledAt: scheduledAt,
      successCallback: callback,
    );
  }

  static OpenListCommand _parseOpen(Uri uri, Uri? callback) {
    return OpenListCommand(
      listName: _boundedRequired(uri.queryParameters['list'], field: 'list'),
      successCallback: callback,
    );
  }

  static String _boundedRequired(String? value, {required String field}) {
    final normalized = value?.trim() ?? '';
    if (normalized.isEmpty || normalized.length > 500) {
      throw FormatException('Invalid $field.');
    }
    return normalized;
  }

  static String? _boundedOptional(String? value, {required String field}) {
    if (value == null) return null;
    return _boundedRequired(value, field: field);
  }

  static DateTime? _parseDate(String? value) {
    if (value == null) return null;
    final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(value);
    if (match == null) throw const FormatException('Invalid date.');
    final year = int.parse(match.group(1)!);
    final month = int.parse(match.group(2)!);
    final day = int.parse(match.group(3)!);
    final parsed = DateTime(year, month, day);
    if (parsed.year != year || parsed.month != month || parsed.day != day) {
      throw const FormatException('Invalid date.');
    }
    return parsed;
  }

  static (int, int)? _parseTime(String? value) {
    if (value == null) return null;
    final match = RegExp(r'^(\d{2}):(\d{2})$').firstMatch(value);
    if (match == null) throw const FormatException('Invalid time.');
    final hour = int.parse(match.group(1)!);
    final minute = int.parse(match.group(2)!);
    if (hour > 23 || minute > 59) {
      throw const FormatException('Invalid time.');
    }
    return (hour, minute);
  }

  static Uri? _parseCallback(String? value) {
    if (value == null) return null;
    final callback = Uri.tryParse(value);
    if (callback == null ||
        callback.scheme.isEmpty ||
        callback.scheme == 'http' ||
        callback.scheme == 'https' ||
        callback.scheme == 'lessdo') {
      throw const FormatException('Unsafe success callback.');
    }
    return callback;
  }
}

class CreateTaskCommand extends DeepLinkCommand {
  const CreateTaskCommand({
    required this.content,
    this.listName,
    this.scheduledAt,
    super.successCallback,
  });

  final String content;
  final String? listName;
  final DateTime? scheduledAt;
}

class OpenListCommand extends DeepLinkCommand {
  const OpenListCommand({required this.listName, super.successCallback});

  final String listName;
}
