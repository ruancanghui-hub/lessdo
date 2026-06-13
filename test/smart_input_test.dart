import 'package:flutter_test/flutter_test.dart';
import 'package:lessdo/store/app_store.dart';

void main() {
  test('parses English tomorrow time', () {
    final result = parseSmartTask('Call Alex tomorrow at 2pm');

    expect(result.title, 'Call Alex tomorrow at 2pm');
    expect(result.dueAt.day, DateTime.now().add(const Duration(days: 1)).day);
    expect(result.reminderAt?.hour, 14);
  });

  test('parses Chinese tomorrow time', () {
    final result = parseSmartTask('明天下午3点买咖啡');

    expect(result.dueAt.day, DateTime.now().add(const Duration(days: 1)).day);
    expect(result.reminderAt?.hour, 15);
  });
}
