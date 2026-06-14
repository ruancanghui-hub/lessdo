import 'package:flutter_test/flutter_test.dart';
import 'package:lessdo/navigation/deep_link_command.dart';

void main() {
  test('rejects an unsupported deep-link action', () {
    expect(
      () => DeepLinkCommand.parse(Uri.parse('lessdo://x-callback-url/delete')),
      throwsFormatException,
    );
  });

  test('rejects unsafe x-success callbacks', () {
    final uri = Uri.parse(
      'lessdo://x-callback-url/create'
      '?content=Test&x-success=https://evil.test',
    );

    expect(() => DeepLinkCommand.parse(uri), throwsFormatException);
  });

  test('parses a bounded create command', () {
    final command = DeepLinkCommand.parse(
      Uri.parse(
        'lessdo://x-callback-url/create'
        '?content=Pay%20bill&list=Inbox&date=2026-06-15&time=09%3A30'
        '&x-success=shortcuts%3A%2F%2Fcallback',
      ),
    );

    expect(command, isA<CreateTaskCommand>());
    final create = command as CreateTaskCommand;
    expect(create.content, 'Pay bill');
    expect(create.listName, 'Inbox');
    expect(create.scheduledAt, DateTime(2026, 6, 15, 9, 30));
    expect(create.successCallback?.scheme, 'shortcuts');
  });

  test('rejects malformed dates, times, and oversized content', () {
    expect(
      () => DeepLinkCommand.parse(
        Uri.parse(
          'lessdo://x-callback-url/create?content=Test&date=2026-02-30',
        ),
      ),
      throwsFormatException,
    );
    expect(
      () => DeepLinkCommand.parse(
        Uri.parse('lessdo://x-callback-url/create?content=Test&time=25%3A00'),
      ),
      throwsFormatException,
    );
    expect(
      () => DeepLinkCommand.parse(
        Uri(
          scheme: 'lessdo',
          host: 'x-callback-url',
          path: '/create',
          queryParameters: {'content': 'x' * 501},
        ),
      ),
      throwsFormatException,
    );
  });
}
