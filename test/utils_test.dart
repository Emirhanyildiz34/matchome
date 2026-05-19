import 'package:flutter_test/flutter_test.dart';
import 'package:match_home/core/utils/format_utils.dart';
import 'package:match_home/core/utils/distance_utils.dart';

void main() {
  group('formatPrice', () {
    test('formats thousands with dots', () {
      expect(formatPrice(8000), '8.000');
      expect(formatPrice(15000), '15.000');
      expect(formatPrice(100000), '100.000');
      expect(formatPrice(1000000), '1.000.000');
    });

    test('does not format numbers under 1000', () {
      expect(formatPrice(500), '500');
      expect(formatPrice(99), '99');
      expect(formatPrice(0), '0');
    });

    test('formats exactly 1000', () {
      expect(formatPrice(1000), '1.000');
    });
  });

  group('currencySymbol', () {
    test('returns correct symbols', () {
      expect(currencySymbol('TL'), '₺');
      expect(currencySymbol('USD'), '\$');
      expect(currencySymbol('EUR'), '€');
      expect(currencySymbol('GBP'), '£');
    });

    test('case insensitive input', () {
      expect(currencySymbol('usd'), '\$');
      expect(currencySymbol('eur'), '€');
      expect(currencySymbol('tl'), '₺');
    });

    test('unknown currency defaults to TL symbol', () {
      expect(currencySymbol('JPY'), '₺');
      expect(currencySymbol('XYZ'), '₺');
    });
  });

  group('formatDateTr', () {
    test('formats standard dates', () {
      expect(formatDateTr(DateTime(2026, 3, 10)), '10 Mar 2026');
      expect(formatDateTr(DateTime(2026, 1, 1)), '1 Oca 2026');
      expect(formatDateTr(DateTime(2026, 12, 31)), '31 Ara 2026');
    });

    test('all months have correct abbreviations', () {
      final monthNames = [
        'Oca',
        'Şub',
        'Mar',
        'Nis',
        'May',
        'Haz',
        'Tem',
        'Ağu',
        'Eyl',
        'Eki',
        'Kas',
        'Ara',
      ];
      for (int i = 0; i < 12; i++) {
        final date = DateTime(2026, i + 1, 15);
        expect(formatDateTr(date), contains(monthNames[i]));
      }
    });
  });

  group('DistanceUtils', () {
    test('haversineKm returns 0 for same coordinates', () {
      final result = DistanceUtils.haversineKm(41.0, 29.0, 41.0, 29.0);
      expect(result, closeTo(0, 0.001));
    });

    test('haversineKm returns reasonable distance for known points', () {
      // Istanbul (Taksim) to Ankara approximate
      final result = DistanceUtils.haversineKm(
        41.0082, 28.9784, // Istanbul
        39.9334, 32.8597, // Ankara
      );
      // Distance is approx 350 km
      expect(result, greaterThan(300));
      expect(result, lessThan(400));
    });

    test('formatDistance formats meters for < 1km', () {
      expect(DistanceUtils.formatDistance(0.5), '500 m');
      expect(DistanceUtils.formatDistance(0.123), '123 m');
    });

    test('formatDistance formats with one decimal for 1-10 km', () {
      expect(DistanceUtils.formatDistance(3.456), '3.5 km');
      expect(DistanceUtils.formatDistance(9.99), '10.0 km');
    });

    test('formatDistance formats as integer for >= 10 km', () {
      expect(DistanceUtils.formatDistance(15.7), '16 km');
      expect(DistanceUtils.formatDistance(100.0), '100 km');
    });
  });
}
