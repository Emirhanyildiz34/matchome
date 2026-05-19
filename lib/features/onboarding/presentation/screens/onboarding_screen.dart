import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/onboarding_provider.dart';
import '../../../../core/widgets/glass_container.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  @override
  Widget build(BuildContext context) {
    final onboardingState = ref.watch(onboardingProvider);
    final onboardingNotifier = ref.read(onboardingProvider.notifier);

    // Eğer işlem başarıyla bitmişse /discover sayfasına yönlendir.
    ref.listen<OnboardingState>(onboardingProvider, (previous, next) {
      if (next.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Hata: ${next.error}'),
              backgroundColor: Colors.redAccent),
        );
      }
      if (next.isFinished) {
        // Form ve Kayıt bitti
        context.go('/discover');
      }
    });

    final currentQuestion = onboardingNotifier.questions[
        // Hata durumlarını engellemek için bounds checking
        onboardingState.currentIndex
            .clamp(0, onboardingNotifier.questions.length - 1)];

    final progress = (onboardingState.currentIndex + 1) /
        onboardingNotifier.questions.length;

    return Scaffold(
      body: Stack(
        children: [
          // Arka plan rengi ve gradientler (Aynı Tema)
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF0F0C29),
                  Color(0xFF302B63),
                  Color(0xFF24243E)
                ],
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
              ),
            ),
          ),

          Positioned(
            top: 50,
            right: -50,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Colors.orangeAccent.withValues(alpha: 0.5),
                    Colors.transparent
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -50,
            left: -50,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Colors.deepPurpleAccent.withValues(alpha: 0.5),
                    Colors.transparent
                  ],
                ),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // AppBar Tarzı Üst Alan
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 8.0),
                  child: Row(
                    children: [
                      if (onboardingState.currentIndex > 0 &&
                          !onboardingState.isSaving)
                        IconButton(
                          icon: const Icon(Icons.arrow_back_ios,
                              color: Colors.white70),
                          onPressed: () => onboardingNotifier.goBack(),
                        )
                      else
                        const SizedBox(width: 48), // Denge için

                      const Spacer(),
                      Text(
                        'Kişilik Analizi',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      const SizedBox(width: 48),
                    ],
                  ),
                ),

                // İlerleme Çubuğu (Progress)
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 32.0, vertical: 16.0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: TweenAnimationBuilder<double>(
                      tween: Tween<double>(begin: 0, end: progress),
                      duration: const Duration(milliseconds: 300),
                      builder: (context, value, _) {
                        return LinearProgressIndicator(
                          value: value,
                          backgroundColor: Colors.white.withValues(alpha: 0.1),
                          color: Colors.orangeAccent,
                          minHeight: 8,
                        );
                      },
                    ),
                  ),
                ),

                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 400),
                    transitionBuilder: (child, animation) {
                      return SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(1, 0),
                          end: Offset.zero,
                        ).animate(animation),
                        child: FadeTransition(opacity: animation, child: child),
                      );
                    },
                    child: onboardingState.isSaving
                        ? _buildLoadingScreen()
                        : _buildQuestionCard(
                            currentQuestion, onboardingState.currentIndex),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Yükleme (Analiz Ediliyor) Ekranı
  Widget _buildLoadingScreen() {
    return Center(
      key: const ValueKey('loading'),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 80,
            height: 80,
            child: CircularProgressIndicator(
                color: Colors.orangeAccent, strokeWidth: 6),
          ),
          const SizedBox(height: 32),
          Text(
            'Sonuçların Hesaplanıyor...',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Uyumlu ev arkadaşlarınla tanışmaya hazır ol!',
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6), fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionCard(QuestionModel question, int index) {
    return SingleChildScrollView(
      key: ValueKey(question.id), // Anahtar, AnimatedSwitcher için gerekli
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
      child: GlassContainer(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
        child: Column(
          children: [
            // Soru Simgesi/Numarası
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orangeAccent.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Text(
                '${index + 1}',
                style: const TextStyle(
                  color: Colors.orangeAccent,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Soru Başlığı
            Text(
              question.text,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            // Soru Açıklaması
            Text(
              question.description,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 48),

            // Soru Seçenekleri (Butonlar)
            ...question.options.map((option) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: InkWell(
                  onTap: () {
                    ref
                        .read(onboardingProvider.notifier)
                        .answerCurrentQuestion(option.value);
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        vertical: 20, horizontal: 24),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      children: [
                        Text(option.emoji,
                            style: const TextStyle(fontSize: 24)),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            option.text,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Icon(Icons.arrow_forward_ios,
                            color: Colors.white.withValues(alpha: 0.3),
                            size: 16),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
