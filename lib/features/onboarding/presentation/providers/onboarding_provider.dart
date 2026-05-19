import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Kişilik Testi Soru Modeli
class QuestionModel {
  final String id;
  final String text;
  final String description;
  final List<AnswerOption> options;

  QuestionModel({
    required this.id,
    required this.text,
    required this.description,
    required this.options,
  });
}

class AnswerOption {
  final String text;
  final dynamic value;
  final String emoji;

  AnswerOption({
    required this.text,
    required this.value,
    required this.emoji,
  });
}

// State Modeli
class OnboardingState {
  final int currentIndex;
  final Map<String, dynamic> answers;
  final bool isSaving;
  final String? error;
  final bool isFinished;

  OnboardingState({
    this.currentIndex = 0,
    this.answers = const {},
    this.isSaving = false,
    this.error,
    this.isFinished = false,
  });

  OnboardingState copyWith({
    int? currentIndex,
    Map<String, dynamic>? answers,
    bool? isSaving,
    String? error,
    bool? isFinished,
  }) {
    return OnboardingState(
      currentIndex: currentIndex ?? this.currentIndex,
      answers: answers ?? this.answers,
      isSaving: isSaving ?? this.isSaving,
      error: error,
      isFinished: isFinished ?? this.isFinished,
    );
  }
}

// Notifier
class OnboardingNotifier extends StateNotifier<OnboardingState> {
  final SupabaseClient _supabase;

  OnboardingNotifier(this._supabase) : super(OnboardingState());

  // Tüm Sorular
  final List<QuestionModel> questions = [
    QuestionModel(
      id: 'cleaning_habit',
      text: 'Temizlik senin için ne kadar önemli?',
      description: 'Evdeki düzen ve genel temizlik alışkanlıkların nasıldır?',
      options: [
        AnswerOption(text: 'Biraz Dağınık', value: 1, emoji: '🌪️'),
        AnswerOption(text: 'Rahat', value: 2, emoji: '😌'),
        AnswerOption(text: 'Normal', value: 3, emoji: '🧹'),
        AnswerOption(text: 'Düzenli', value: 4, emoji: '✨'),
        AnswerOption(text: 'Çok Titiz', value: 5, emoji: '🧽'),
      ],
    ),
    QuestionModel(
      id: 'sleep_schedule',
      text: 'Uyku düzenin nasıldır?',
      description: 'Gece kuşu mu yoksa erkenci misin?',
      options: [
        AnswerOption(text: 'Gece Kuşu', value: 1, emoji: '🦉'),
        AnswerOption(text: 'Geç Yatarım', value: 2, emoji: '🌙'),
        AnswerOption(text: 'Değişken', value: 3, emoji: '🤷'),
        AnswerOption(text: 'Erkenci', value: 4, emoji: '☀️'),
        AnswerOption(text: 'Sabah İnsanı', value: 5, emoji: '🐓'),
      ],
    ),
    QuestionModel(
      id: 'social_battery',
      text: 'Sosyal enerjin ne seviyede?',
      description: 'Evdeyken sessizlik mi istersin, yoksa hareket mi?',
      options: [
        AnswerOption(text: 'Tamamen İçe Dönük', value: 1, emoji: '🧘'),
        AnswerOption(text: 'Genelde Sessiz', value: 2, emoji: '🎧'),
        AnswerOption(text: 'Ortamına Göre', value: 3, emoji: '⚖️'),
        AnswerOption(text: 'Sosyal', value: 4, emoji: '☕'),
        AnswerOption(text: 'Parti Sever', value: 5, emoji: '🎉'),
      ],
    ),
    QuestionModel(
      id: 'guest_frequency',
      text: 'Eve misafir gelmesine ne dersin?',
      description: 'Arkadaşlarını veya aileni sık sık ağırlar mısın?',
      options: [
        AnswerOption(text: 'Hiç İstemem', value: 1, emoji: '🚫'),
        AnswerOption(text: 'Nadiren', value: 2, emoji: '🚪'),
        AnswerOption(text: 'Haftada Bir', value: 3, emoji: '🛋️'),
        AnswerOption(text: 'Sık Sık', value: 4, emoji: '🍕'),
        AnswerOption(text: 'Her Gün Gelsinler', value: 5, emoji: '🎊'),
      ],
    ),
    QuestionModel(
      id: 'smoking',
      text: 'Evde sigara kullanımı?',
      description: 'Senin veya başkasının içmesi sorun olur mu?',
      options: [
        AnswerOption(text: 'Kesinlikle Hayır', value: false, emoji: '🚭'),
        AnswerOption(text: 'Sorun Değil', value: true, emoji: '🚬'),
      ],
    ),
    QuestionModel(
      id: 'pets',
      text: 'Evcil hayvanlarla aran nasıldır?',
      description: 'Evde dostlarımıza yer var mı?',
      options: [
        AnswerOption(
            text: 'Alerjim var / İstemem', value: false, emoji: '🐕‍🦺'),
        AnswerOption(text: 'Çok Severim', value: true, emoji: '🐱'),
      ],
    ),
  ];

  void answerCurrentQuestion(dynamic value) {
    final curQuestionId = questions[state.currentIndex].id;
    final newAnswers = Map<String, dynamic>.from(state.answers);
    newAnswers[curQuestionId] = value;

    if (state.currentIndex < questions.length - 1) {
      state = state.copyWith(
        answers: newAnswers,
        currentIndex: state.currentIndex + 1,
      );
    } else {
      // Son sorudayız, cevapları kaydet ve bitir
      state = state.copyWith(answers: newAnswers);
      _saveResultsToSupabase();
    }
  }

  void goBack() {
    if (state.currentIndex > 0) {
      state = state.copyWith(currentIndex: state.currentIndex - 1);
    }
  }

  Future<void> _saveResultsToSupabase() async {
    state = state.copyWith(isSaving: true, error: null);
    try {
      // Mevcut oturumu en güncel haliyle al
      final session = _supabase.auth.currentSession;
      final user = session?.user ?? _supabase.auth.currentUser;

      if (user == null) {
        throw Exception(
            'Kullanıcı oturumu bulunamadı! Lütfen tekrar giriş yapın.');
      }

      // 1. Kişilik sonuçlarını kaydet
      await _supabase.from('personality_results').upsert({
        'profile_id': user.id,
        'traits': state.answers,
        'updated_at': DateTime.now().toIso8601String(),
      });

      state = state.copyWith(isSaving: false, isFinished: true);
    } catch (e) {
      state = state.copyWith(isSaving: false, error: e.toString());
    }
  }
}

// Provider
final onboardingProvider =
    StateNotifierProvider<OnboardingNotifier, OnboardingState>((ref) {
  return OnboardingNotifier(Supabase.instance.client);
});
