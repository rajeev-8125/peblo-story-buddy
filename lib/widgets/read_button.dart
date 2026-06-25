// lib/widgets/read_button.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/story_provider.dart';

class ReadButton extends StatefulWidget {
  const ReadButton({super.key});

  @override
  State<ReadButton> createState() => _ReadButtonState();
}

class _ReadButtonState extends State<ReadButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.07).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<StoryProvider>();
    final state = provider.audioState;

    final bool isIdle = state == AudioState.idle || state == AudioState.finished;
    final bool isLoading = state == AudioState.loading;
    final bool isPlaying = state == AudioState.playing;
    final bool isError = state == AudioState.error;

    Widget child;
    VoidCallback? onTap;

    if (isError) {
      child = _buttonContent(
        icon: Icons.refresh_rounded,
        label: 'Try Again',
        color: const Color(0xFFFF6B6B),
      );
      onTap = () {
        HapticFeedback.mediumImpact();
        provider.retry();
      };
    } else if (isLoading) {
      child = _buttonContent(
        loading: true,
        label: 'Preparing...',
        color: const Color(0xFFFFB347),
      );
      onTap = null;
    } else if (isPlaying) {
      child = _buttonContent(
        icon: Icons.volume_up_rounded,
        label: 'Listening...',
        color: const Color(0xFF5B8DEF),
      );
      onTap = null;
    } else {
      // idle or finished — show "Read Me a Story"
      child = _buttonContent(
        icon: Icons.auto_stories_rounded,
        label: 'Read Me a Story!',
        color: const Color(0xFFFF6B6B),
      );
      onTap = () {
        HapticFeedback.mediumImpact();
        provider.readStory();
      };
    }

    return AnimatedBuilder(
      animation: _pulseAnim,
      builder: (context, c) => Transform.scale(
        scale: (isIdle && !isError) ? _pulseAnim.value : 1.0,
        child: c,
      ),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isError
                  ? [const Color(0xFFFF6B6B), const Color(0xFFFF8E53)]
                  : isPlaying || isLoading
                      ? [const Color(0xFF5B8DEF), const Color(0xFF7BA7F5)]
                      : [const Color(0xFFFF6B6B), const Color(0xFFFF8E53)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(36),
            boxShadow: [
              BoxShadow(
                color: (isPlaying
                        ? const Color(0xFF5B8DEF)
                        : const Color(0xFFFF6B6B))
                    .withOpacity(0.40),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _buttonContent({
    IconData? icon,
    required String label,
    required Color color,
    bool loading = false,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (loading)
          const SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
                color: Colors.white, strokeWidth: 2.5),
          )
        else if (icon != null)
          Icon(icon, color: Colors.white, size: 24),
        const SizedBox(width: 10),
        Text(
          label,
          style: GoogleFonts.nunito(
            color: Colors.white,
            fontSize: 17,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }
}
