import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

enum DiagnosticEvent {
  frameworkError,
  platformError,
  storageFailure,
  notificationFailure,
  authenticationFailure,
}

class DiagnosticLog {
  DiagnosticLog({
    required File file,
    required String appVersion,
    required String platform,
    DateTime Function()? clock,
  }) : _file = file,
       _appVersion = appVersion,
       _platform = platform,
       _clock = clock ?? DateTime.now;

  static const maxEvents = 200;

  static Future<DiagnosticLog> openDefault({
    required String appVersion,
    required String platform,
  }) async {
    final directory = await getApplicationSupportDirectory();
    return DiagnosticLog(
      file: File('${directory.path}/diagnostics/events.jsonl'),
      appVersion: appVersion,
      platform: platform,
    );
  }

  final File _file;
  final String _appVersion;
  final String _platform;
  final DateTime Function() _clock;
  Future<void> _writeQueue = Future.value();

  Future<void> record(DiagnosticEvent event, {Object? error}) {
    final completer = Completer<void>();
    _writeQueue = _writeQueue.then((_) async {
      try {
        await _record(event, error: error);
        completer.complete();
      } catch (writeError, stackTrace) {
        completer.completeError(writeError, stackTrace);
      }
    });
    return completer.future;
  }

  Future<void> _record(DiagnosticEvent event, {Object? error}) async {
    await _file.parent.create(recursive: true);
    final existing = await _readLines();
    final encoded = jsonEncode({
      'event': event.name,
      'timestampUtc': _clock().toUtc().toIso8601String(),
      'appVersion': _appVersion,
      'platform': _platform,
      if (error != null) 'errorType': error.runtimeType.toString(),
    });
    final lines = [...existing, encoded];
    final retained = lines.length <= maxEvents
        ? lines
        : lines.sublist(lines.length - maxEvents);
    await _file.writeAsString('${retained.join('\n')}\n', flush: true);
  }

  Future<String> readForExport() async {
    await _writeQueue;
    if (!await _file.exists()) return '';
    return _file.readAsString();
  }

  Future<List<String>> _readLines() async {
    if (!await _file.exists()) return const [];
    return (await _file.readAsLines())
        .where((line) => line.trim().isNotEmpty)
        .toList();
  }
}
