import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:lessdo/services/share_service.dart';

void main() {
  test('list sharing uses plain text', () async {
    final platform = _SharePlatform();
    final service = ShareService(platform: platform);

    await service.share(title: 'Work', text: 'Prepare report');

    expect(platform.title, 'Work');
    expect(platform.text, 'Prepare report');
    expect(platform.fileBytes, isNull);
  });

  test('diagnostic sharing exports a bounded text file', () async {
    final platform = _SharePlatform();
    final service = ShareService(platform: platform);
    final oversized = List.filled(300000, 'x').join();

    await service.shareDiagnostics(oversized);

    expect(platform.fileName, 'lessdo-diagnostics.txt');
    expect(platform.mimeType, 'text/plain');
    expect(platform.fileBytes, isNotNull);
    expect(platform.fileBytes!.length, lessThanOrEqualTo(256 * 1024));
    expect(utf8.decode(platform.fileBytes!), isNotEmpty);
  });
}

class _SharePlatform implements SharePlatform {
  String? title;
  String? text;
  String? fileName;
  String? mimeType;
  List<int>? fileBytes;

  @override
  Future<void> shareFile({
    required String fileName,
    required String mimeType,
    required List<int> bytes,
  }) async {
    this.fileName = fileName;
    this.mimeType = mimeType;
    fileBytes = bytes;
  }

  @override
  Future<void> shareText({required String title, required String text}) async {
    this.title = title;
    this.text = text;
  }
}
