// lib/widgets/quiz_widget.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:confetti/confetti.dart';
import '../providers/story_provider.dart';

class QuizWidget extends StatefulWidget {
  const QuizWidget({super.key});

  @override
  State<QuizWidget> createState() => _QuizWidgetState();
}

class _QuizWidgetState extends State<QuizWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _shakeCtrl;
  late Animation<double> _shakeAnim;
  late ConfettiController _confettiCtrl;

  // Track previous answer state to trigger animations once
  AnswerResult _prevResult = AnswerResult.none;

  @override
  void initState() {
    super.initState();

    _shakeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _shakeAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -16.0), weight: 20),
      TweenSequenceItem(tween: Tween(begin: -16.0, end: 16.0), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 16.0, end: -10.0), weight: 20),
      TweenSequenceItem(tween: Tween(begin: -10.0, end: 10.0), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 10.0, end: 0.0), weight: 20),
    ]).animate(CurvedAnimation(parent: _shakeCtrl, curve: Curves.linear));

    _confettiCtrl = ConfettiController(
      duration: const Duration(seconds: 3),
    );
  }

  @override
  void dispose() {
    _shakeCtrl.dispose();
    _confettiCtrl.dispose();
    super.dispose();
  }

  void _triggerShake() {
    HapticFeedback.heavyImpact();
    _shakeCtrl.forward(from: 0);
  }

  void _triggerCelebration() {
    HapticFeedback.mediumImpact();
    _confettiCtrl.play();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<StoryProvider>(
      builder: (context, provider, _) {
        // Trigger side effects when state changes
        if (provider.answerResult != _prevResult) {
          if (provider.answerResult == AnswerResult.wrong) {
            WidgetsBinding.instance
                .addPostFrameCallback((_) => _triggerShake());
          } else if (provider.answerResult == AnswerResult.correct) {
            WidgetsBinding.instance
                .addPostFrameCallback((_) => _triggerCelebration());
          }
          _prevResult = provider.answerResult;
        }

        final quizState = provider.quizState;

        // Slide-in transition when quiz appears
        return AnimatedSlide(
          offset: quizState == QuizState.hidden
              ? const Offset(0, 0.15)
              : Offset.zero,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeOutCubic,
          child: AnimatedOpacity(
            opacity: quizState == QuizState.hidden ? 0.0 : 1.0,
            duration: const Duration(milliseconds: 400),
            child: quizState == QuizState.hidden
                ? const SizedBox.shrink()
                : Stack(
                    alignment: Alignment.topCenter,
                    children: [
                      // Confetti burst
                      ConfettiWidget(
                        confettiController: _confettiCtrl,
                        blastDirectionality: BlastDirectionality.explosive,
                        particleDrag: 0.05,
                        emissionFrequency: 0.08,
                        numberOfParticles: 22,
                        gravity: 0.3,
                        colors: const [
                          Color(0xFFFF6B6B),
                          Color(0xFFFFD700),
                          Color(0xFF5B8DEF),
                          Color(0xFF4CAF50),
                          Color(0xFFFF8E53),
                        ],
                      ),
                      provider.quizState == QuizState.answered
                          ? _SuccessCard()
                          : _QuizCard(
                              shakeAnim: _shakeAnim,
                              shakeCtrl: _shakeCtrl,
                            ),
                    ],
                  ),
          ),
        );
      },
    );
  }
}

// ─── Quiz Card (question + options) ────────────────────────────────────────

class _QuizCard extends StatelessWidget {
  final Animation<double> shakeAnim;
  final AnimationController shakeCtrl;

  const _QuizCard({required this.shakeAnim, required this.shakeCtrl});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<StoryProvider>();
    final quiz = provider.quiz;

    return AnimatedBuilder(
      animation: shakeAnim,
      builder: (_, child) => Transform.translate(
        offset: Offset(shakeAnim.value, 0),
        child: child,
      ),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFFD700).withOpacity(0.25),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Label
            Row(
              children: [
                const Icon(Icons.quiz_rounded,
                    color: Color(0xFFFFB347), size: 20),
                const SizedBox(width: 6),
                Text(
                  'Quick Quiz!',
                  style: GoogleFonts.nunito(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFFFFB347),
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Question — rendered from JSON
            Text(
              quiz.question,
              style: GoogleFonts.nunito(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF2D3748),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            // Options — data-driven: works for 3, 4, or 5 options
            ...List.generate(quiz.options.length, (i) {
              final opt = quiz.options[i];
              final isSelected = provider.selectedOption == opt;
              final isWrong = isSelected &&
                  provider.answerResult == AnswerResult.wrong;

              return _OptionTile(
                label: opt,
                index: i,
                isSelected: isSelected,
                isWrong: isWrong,
              );
            }),
            // Wrong attempt counter
            if (provider.wrongAttempts > 0)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  provider.wrongAttempts == 1
                      ? 'Oops! Try again! 🤔'
                      : 'Keep trying! You\'ve got this! 💪',
                  style: GoogleFonts.nunito(
                    fontSize: 13,
                    color: const Color(0xFFFF6B6B),
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  final String label;
  final int index;
  final bool isSelected;
  final bool isWrong;

  const _OptionTile({
    required this.label,
    required this.index,
    required this.isSelected,
    required this.isWrong,
  });

  static const _letters = ['A', 'B', 'C', 'D', 'E'];

  @override
  Widget build(BuildContext context) {
    final provider = context.read<StoryProvider>();

    final Color bgColor = isWrong
        ? const Color(0xFFFFEBEE)
        : isSelected
            ? const Color(0xFFE3F0FF)
            : const Color(0xFFF7F8FC);

    final Color borderColor = isWrong
        ? const Color(0xFFFF5252)
        : isSelected
            ? const Color(0xFF5B8DEF)
            : const Color(0xFFE2E8F0);

    return GestureDetector(
      onTap: () => provider.submitAnswer(label),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: 2),
        ),
        child: Row(
          children: [
            // Letter badge
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: isWrong
                    ? const Color(0xFFFF5252)
                    : isSelected
                        ? const Color(0xFF5B8DEF)
                        : const Color(0xFFE2E8F0),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                index < _letters.length ? _letters[index] : '${index + 1}',
                style: GoogleFonts.nunito(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: (isSelected || isWrong)
                      ? Colors.white
                      : const Color(0xFF718096),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.nunito(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF2D3748),
                ),
              ),
            ),
            if (isWrong)
              const Icon(Icons.close_rounded, color: Color(0xFFFF5252), size: 20),
          ],
        ),
      ),
    );
  }
}

// ─── Success Card ───────────────────────────────────────────────────────────

class _SuccessCard extends StatefulWidget {
  @override
  State<_SuccessCard> createState() => _SuccessCardState();
}

class _SuccessCardState extends State<_SuccessCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
    _scaleAnim = CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnim,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF4CAF50), Color(0xFF66BB6A)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF4CAF50).withOpacity(0.4),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            const Text('🎉', style: TextStyle(fontSize: 56)),
            const SizedBox(height: 10),
            Text(
              'Amazing Job!',
              style: GoogleFonts.nunito(
                fontSize: 26,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'You got it right! Pip\'s gear was BLUE! 💙',
              textAlign: TextAlign.center,
              style: GoogleFonts.nunito(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.white.withOpacity(0.92),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: () => context.read<StoryProvider>().reset(),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 28, vertical: 13),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Text(
                  'Play Again! 🚀',
                  style: GoogleFonts.nunito(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF4CAF50),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
