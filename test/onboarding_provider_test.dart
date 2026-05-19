import 'package:flutter_test/flutter_test.dart';
import 'package:match_home/features/onboarding/presentation/providers/onboarding_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Dummy class since we don't reach the save method in these simple tests
class DummySupabaseClient extends Fake implements SupabaseClient {}

void main() {
  group('OnboardingNotifier Tests', () {
    late OnboardingNotifier notifier;
    late DummySupabaseClient dummySupabaseClient;

    setUp(() {
      dummySupabaseClient = DummySupabaseClient();
      notifier = OnboardingNotifier(dummySupabaseClient);
    });

    test('Initial state should be correct', () {
      expect(notifier.state.currentIndex, 0);
      expect(notifier.state.answers.isEmpty, true);
      expect(notifier.state.isSaving, false);
      expect(notifier.state.isFinished, false);
      expect(notifier.state.error, null);
    });

    test('answerCurrentQuestion increments index and saves answer', () {
      final questionId = notifier.questions[0].id;
      final answerValue = notifier.questions[0].options[0].value;

      notifier.answerCurrentQuestion(answerValue);

      expect(notifier.state.currentIndex, 1);
      expect(notifier.state.answers[questionId], answerValue);
    });

    test('goBack decrements index', () {
      // First string forward
      notifier.answerCurrentQuestion(1);
      expect(notifier.state.currentIndex, 1);

      // Then go back
      notifier.goBack();
      expect(notifier.state.currentIndex, 0);
    });
  });
}
