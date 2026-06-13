import 'package:flutter_test/flutter_test.dart';
import 'package:lessdo/models/smart_task_parser.dart';

void main() {
  final now = DateTime(2026, 6, 13, 10);
  late SmartTaskParser parser;

  setUp(() {
    parser = SmartTaskParser(now: () => now);
  });

  test('parses an English tomorrow date and 12-hour time', () {
    final result = parser.parse('Buy coffee tomorrow at 3:30 pm');

    expect(result.title, 'Buy coffee');
    expect(result.dueAt, DateTime(2026, 6, 14, 15, 30));
    expect(result.reminderAt, result.dueAt);
  });

  test('parses a Chinese tomorrow date and afternoon time', () {
    final result = parser.parse('明天下午3点买咖啡');

    expect(result.title, '买咖啡');
    expect(result.dueAt, DateTime(2026, 6, 14, 15));
    expect(result.reminderAt, result.dueAt);
  });

  test('does not treat an unmarked number as a time', () {
    final result = parser.parse('Buy 12 apples');

    expect(result.title, 'Buy 12 apples');
    expect(result.dueAt, isNull);
    expect(result.reminderAt, isNull);
  });

  test('handles midnight and noon correctly', () {
    final midnight = parser.parse('Sleep tomorrow at 12am');
    final noon = parser.parse('Lunch tomorrow at 12pm');

    expect(midnight.title, 'Sleep');
    expect(midnight.dueAt, DateTime(2026, 6, 14));
    expect(noon.title, 'Lunch');
    expect(noon.dueAt, DateTime(2026, 6, 14, 12));
  });

  test('rejects a blank task', () {
    expect(() => parser.parse('  \n '), throwsFormatException);
  });

  test('rejects invalid Chinese hours instead of rolling the date', () {
    expect(() => parser.parse('明天25点买咖啡'), throwsFormatException);
    expect(() => parser.parse('明天上午13点买咖啡'), throwsFormatException);
  });

  test('rejects invalid Chinese minutes', () {
    expect(() => parser.parse('明天下午3点60分买咖啡'), throwsFormatException);
  });
}
