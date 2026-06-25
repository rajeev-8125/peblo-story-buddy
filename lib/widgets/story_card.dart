// lib/widgets/story_card.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/story_provider.dart';

class StoryCard extends StatelessWidget {
  const StoryCard({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<StoryProvider>();

    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF5B8DEF).withOpacity(0.18),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: provider.audioState == AudioState.playing
              ? const Color(0xFF5B8DEF).withOpacity(0.6)
              : Colors.transparent,
          width: 2,
        ),
      ),
      child: Column(
        children: [
          // Stars decoration
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              5,
              (i) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Icon(
                  Icons.star_rounded,
                  size: 14,
                  color: const Color(0xFFFFD700).withOpacity(0.7),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            StoryProvider.storyText,
            style: GoogleFonts.nunito(
              fontSize: 16,
              height: 1.65,
              color: const Color(0xFF2D3748),
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          // Animated sound wave when playing
          if (provider.audioState == AudioState.playing) ...[
            const SizedBox(height: 14),
            const _SoundWave(),
          ],
        ],
      ),
    );
  }
}

class _SoundWave extends StatefulWidget {
  const _SoundWave();

  @override
  State<_SoundWave> createState() => _SoundWaveState();
}

class _SoundWaveState extends State<_SoundWave>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: List.generate(5, (i) {
            final phase = (i / 5) * 3.14159;
            final height = 6 +
                18 * ((0.5 + 0.5 * _ctrl.value) *
                    (0.5 + 0.5 * ((i % 2 == 0) ? _ctrl.value : 1 - _ctrl.value)));
            return Container(
              width: 5,
              height: height.clamp(6.0, 24.0),
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                color: const Color(0xFF5B8DEF),
                borderRadius: BorderRadius.circular(4),
              ),
            );
          }),
        );
      },
    );
  }
}
