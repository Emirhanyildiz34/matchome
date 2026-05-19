// MatchHome Widget Test
//
// Temel uygulama bileşenlerinin doğru yüklendiğini kontrol eder.

import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:match_home/features/onboarding/presentation/providers/onboarding_provider.dart';
import 'package:match_home/features/listings/data/models/listing_model.dart';

void main() {
  group('OnboardingState Tests', () {
    test('OnboardingState default values', () {
      final state = OnboardingState();
      expect(state.currentIndex, 0);
      expect(state.answers, const {});
      expect(state.isSaving, false);
      expect(state.isFinished, false);
      expect(state.error, isNull);
    });

    test('OnboardingState copyWith works correctly', () {
      final state = OnboardingState();
      final updated = state.copyWith(
        currentIndex: 2,
        answers: {'cleaning_habit': 3},
      );

      expect(updated.currentIndex, 2);
      expect(updated.answers['cleaning_habit'], 3);
      expect(updated.isSaving, false); // Değiştirilmedi
    });
  });

  group('ListingModel Tests', () {
    test('ListingModel toJson and fromJson round-trip', () {
      final listing = ListingModel(
        hostId: 'test-user-id',
        title: 'Test İlanı',
        description: 'Test açıklama',
        price: 8500,
        utilitiesIncluded: true,
        roomCount: '2+1',
        houseFeatures: ['Eşyalı', 'WiFi'],
        imageUrls: ['https://example.com/img.jpg'],
        addressText: 'İstanbul, Kadıköy',
        listingType: 'room_search',
      );

      final json = listing.toJson();
      final restored = ListingModel.fromJson(json);

      expect(restored.hostId, listing.hostId);
      expect(restored.title, listing.title);
      expect(restored.price, listing.price);
      expect(restored.utilitiesIncluded, true);
      expect(restored.roomCount, '2+1');
      expect(restored.houseFeatures, ['Eşyalı', 'WiFi']);
      expect(restored.imageUrls, ['https://example.com/img.jpg']);
      expect(restored.addressText, 'İstanbul, Kadıköy');
      expect(restored.listingType, 'room_search');
    });

    test('ListingModel fromJson handles null fields', () {
      final json = {
        'id': 'abc123',
        'host_id': 'user-1',
        'title': 'Minimal İlan',
        'price': 5000,
      };

      final listing = ListingModel.fromJson(json);
      expect(listing.id, 'abc123');
      expect(listing.description, isNull);
      expect(listing.utilitiesIncluded, false);
      expect(listing.houseFeatures, isEmpty);
      expect(listing.imageUrls, isEmpty);
      expect(listing.isActive, true);
      expect(listing.listingType, 'room_offer'); // Varsayılan değer
    });
  });

  group('QuestionModel Tests', () {
    test('All onboarding questions have valid options', () {
      final notifier = OnboardingNotifier(_FakeSupabaseClient());
      for (final q in notifier.questions) {
        expect(q.id.isNotEmpty, true);
        expect(q.text.isNotEmpty, true);
        expect(q.options.isNotEmpty, true);
        for (final opt in q.options) {
          expect(opt.text.isNotEmpty, true);
          expect(opt.emoji.isNotEmpty, true);
        }
      }
    });

    test('There are 6 onboarding questions', () {
      final notifier = OnboardingNotifier(_FakeSupabaseClient());
      expect(notifier.questions.length, 6);
    });
  });
}

// Fake SupabaseClient for unit tests (save is not called)
class _FakeSupabaseClient extends Fake implements SupabaseClient {}
