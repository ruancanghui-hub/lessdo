import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lessdo/diagnostics/diagnostic_log.dart';

void main() {
  late Directory directory;
  late DiagnosticLog log;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('lessdo_diagnostics_');
    log = DiagnosticLog(
      file: File('${directory.path}/events.jsonl'),
      appVersion: '1.0.0+1',
      platform: 'test',
      clock: () => DateTime.utc(2026, 6, 14, 10),
    );
  });

  tearDown(() => directory.delete(recursive: true));

  test('diagnostic log redacts user content', () async {
    await log.record(
      DiagnosticEvent.storageFailure,
      error: Exception('task title: Secret medical appointment'),
    );

    final exported = await log.readForExport();
    expect(exported, isNot(contains('Secret medical appointment')));
    expect(exported, contains('Exception'));
    expect(exported, contains('storageFailure'));
  });

  test('diagnostic log retains only the newest 200 events', () async {
    for (var index = 0; index < 205; index += 1) {
      await log.record(DiagnosticEvent.frameworkError);
    }

    final lines = (await log.readForExport())
        .split('\n')
        .where((line) => line.isNotEmpty)
        .toList();
    expect(lines, hasLength(200));
  });
}
