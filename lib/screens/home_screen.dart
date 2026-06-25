// lib/screens/home_screen.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/story_provider.dart';
import '../widgets/buddy_widget.dart';
import '../widgets/story_card.dart';
import '../widgets/read_button.dart';
import '../widgets/quiz_widget.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFFFF5F7), // soft warm white
              Color(0xFFEEF4FF), // soft blue tint
              Color(0xFFF0FFF4), // soft green tint
            ],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _TopBar(),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Column(
                      children: [
                        const SizedBox(height: 12),
                        // ── Buddy character ──────────────────────────────
                        const BuddyWidget(),
                        const SizedBox(height: 4),
                        // Buddy name tag
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 5),
                          decoration: BoxDecoration(
                            color: const Color(0xFF5B8DEF).withOpacity(0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '✨ Hi, I\'m Pip! ✨',
                            style: GoogleFonts.nunito(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF3A6BE8),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        // ── Story card ───────────────────────────────────
                        const StoryCard(),
                        const SizedBox(height: 6),
                        // Error message
                        _ErrorBanner(),
                        const SizedBox(height: 20),
                        // ── Read Me a Story button ───────────────────────
                        const ReadButton(),
                        const SizedBox(height: 28),
                        // ── Quiz section ─────────────────────────────────
                        const QuizWidget(),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          // App logo / icon
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF5B8DEF), Color(0xFF3A6BE8)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: const Text('🤖', style: TextStyle(fontSize: 20)),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Peblo',
                style: GoogleFonts.nunito(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF2D3748),
                ),
              ),
              Text(
                'Story Buddy',
                style: GoogleFonts.nunito(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF5B8DEF),
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const Spacer(),
          // Stars earned indicator
          Consumer<StoryProvider>(
            builder: (_, provider, __) => AnimatedOpacity(
              opacity: provider.quizState == QuizState.answered ? 1.0 : 0.3,
              duration: const Duration(milliseconds: 500),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFD700).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: const Color(0xFFFFD700).withOpacity(0.5)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.star_rounded,
                        color: Color(0xFFFFD700), size: 16),
                    const SizedBox(width: 4),
                    Text(
                      provider.quizState == QuizState.answered ? '+10' : '0',
                      style: GoogleFonts.nunito(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFFE6A800),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<StoryProvider>();
    if (provider.audioState != AudioState.error) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFFFEBEE),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFFFCDD2)),
        ),
        child: Row(
          children: [
            const Icon(Icons.info_outline_rounded,
                color: Color(0xFFFF5252), size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                provider.errorMessage.isNotEmpty
                    ? provider.errorMessage
                    : 'Could not start narration. Please try again.',
                style: GoogleFonts.nunito(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFFD32F2F),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
