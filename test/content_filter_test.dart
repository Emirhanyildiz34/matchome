import 'package:flutter_test/flutter_test.dart';
import 'package:match_home/core/utils/content_filter.dart';

void main() {
  group('ContentFilter', () {
    test('detects blocked Turkish profanity words', () {
      expect(ContentFilter.hasBlockedContent('bu ilan çok sikik'), true);
      expect(ContentFilter.hasBlockedContent('amk ne diyorsun'), true);
      expect(ContentFilter.hasBlockedContent('bu adamlar orospu'), true);
    });

    test('returns false for clean text', () {
      expect(ContentFilter.hasBlockedContent('güzel bir ev ilanı'), false);
      expect(
          ContentFilter.hasBlockedContent('Merhaba, bu oda müsait mi?'), false);
      expect(ContentFilter.hasBlockedContent(''), false);
    });

    test('findBlockedWords returns matching words', () {
      final result = ContentFilter.findBlockedWords('bu boktan bir yer amk');
      expect(result, isNotEmpty);
      expect(result, contains('boktan'));
      expect(result, contains('amk'));
    });

    test('findBlockedWords returns empty list for clean text', () {
      final result = ContentFilter.findBlockedWords('bu güzel bir yer');
      expect(result, isEmpty);
    });

    test('detects case-insensitive blocked content', () {
      expect(ContentFilter.hasBlockedContent('AMK ne ya'), true);
      expect(ContentFilter.hasBlockedContent('Bu BOKTAN yer'), true);
    });

    test('detects internet slang', () {
      expect(ContentFilter.hasBlockedContent('aq ya bu ne'), true);
      expect(ContentFilter.hasBlockedContent('skm bunu'), true);
    });

    test('handles empty and whitespace strings', () {
      expect(ContentFilter.hasBlockedContent(''), false);
      expect(ContentFilter.hasBlockedContent('   '), false);
    });
  });
}
