import 'package:flutter_test/flutter_test.dart';
import 'package:notes/core/utils/date_formatter.dart';

void main() {
  group('DateFormatter.formatShortDate', () {
    test('formats a date correctly', () {
      final date = DateTime(2026, 9, 4);

      expect(
        DateFormatter.formatShortDate(date),
        '04 Sep 2026',
      );
    });
    
  });

  group('DateFormatter.formatOrdinalDate', () {
    test('formats 1st correctly', () {
      final date = DateTime(2026, 9, 1);

      expect(
        DateFormatter.formatOrdinalDate(date),
        '1st Sep 2026',
      );
    });

    test('formats 2nd correctly', () {
      final date = DateTime(2026, 9, 2);

      expect(
        DateFormatter.formatOrdinalDate(date),
        '2nd Sep 2026',
      );
    });

    test('formats 3rd correctly', () {
      final date = DateTime(2026, 9, 3);

      expect(
        DateFormatter.formatOrdinalDate(date),
        '3rd Sep 2026',
      );
    });

    test('formats 4th correctly', () {
      final date = DateTime(2026, 9, 4);

      expect(
        DateFormatter.formatOrdinalDate(date),
        '4th Sep 2026',
      );
    });

    test('formats 11th, 12th and 13th correctly', () {
      expect(
        DateFormatter.formatOrdinalDate(DateTime(2026, 9, 11)),
        '11th Sep 2026',
      );

      expect(
        DateFormatter.formatOrdinalDate(DateTime(2026, 9, 12)),
        '12th Sep 2026',
      );

      expect(
        DateFormatter.formatOrdinalDate(DateTime(2026, 9, 13)),
        '13th Sep 2026',
      );
    });

    test('formats 21st correctly', () {
      final date = DateTime(2026, 9, 21);

      expect(
        DateFormatter.formatOrdinalDate(date),
        '21st Sep 2026',
      );
    });
  });
}