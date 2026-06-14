import 'dart:convert';
import 'dart:typed_data';

import 'package:share_plus/share_plus.dart';

import 'platform_coordinators.dart';

abstract interface class SharePlatform {
  Future<void> shareText({required String title, required String text});

  Future<void> shareFile({
    required String fileName,
    required String mimeType,
    required List<int> bytes,
  });
}

class ShareService implements SharingCoordinator {
  ShareService({SharePlatform? platform})
    : _platform = platform ?? SharePlusPlatform();

  static const maxDiagnosticBytes = 256 * 1024;

  final SharePlatform _platform;

  @override
  Future<void> share({required String title, required String text}) {
    return _platform.shareText(title: title, text: text);
  }

  Future<void> shareDiagnostics(String diagnostics) {
    return _platform.shareFile(
      fileName: 'lessdo-diagnostics.txt',
      mimeType: 'text/plain',
      bytes: _boundedUtf8(diagnostics, maxDiagnosticBytes),
    );
  }

  List<int> _boundedUtf8(String value, int maxBytes) {
    final bytes = <int>[];
    for (final rune in value.runes) {
      final encoded = utf8.encode(String.fromCharCode(rune));
      if (bytes.length + encoded.length > maxBytes) break;
      bytes.addAll(encoded);
    }
    return bytes;
  }
}

class SharePlusPlatform implements SharePlatform {
  @override
  Future<void> shareText({required String title, required String text}) {
    return SharePlus.instance.share(ShareParams(title: title, text: text));
  }

  @override
  Future<void> shareFile({
    required String fileName,
    required String mimeType,
    required List<int> bytes,
  }) {
    return SharePlus.instance.share(
      ShareParams(
        files: [
          XFile.fromData(
            Uint8List.fromList(bytes),
            mimeType: mimeType,
            name: fileName,
          ),
        ],
      ),
    );
  }
}
