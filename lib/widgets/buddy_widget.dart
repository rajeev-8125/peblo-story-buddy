// lib/widgets/buddy_widget.dart

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/story_provider.dart';

class BuddyWidget extends StatefulWidget {
  const BuddyWidget({super.key});

  @override
  State<BuddyWidget> createState() => _BuddyWidgetState();
}

class _BuddyWidgetState extends State<BuddyWidget>
    with TickerProviderStateMixin {
  late AnimationController _floatController;
  late AnimationController _happyController;
  late AnimationController _shakeController;
  late Animation<double> _floatAnim;
  late Animation<double> _scaleAnim;
  late Animation<double> _shakeAnim;

  @override
  void initState() {
    super.initState();

    // Gentle floating idle animation
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);
    _floatAnim = Tween<double>(begin: -8, end: 8).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );

    // Happy bounce on correct answer
    _happyController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _scaleAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.3), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.3, end: 0.9), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 0.9, end: 1.0), weight: 30),
    ]).animate(CurvedAnimation(parent: _happyController, curve: Curves.easeOut));

    // Shake on wrong answer
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _shakeAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0, end: -12), weight: 20),
      TweenSequenceItem(tween: Tween(begin: -12, end: 12), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 12, end: -8), weight: 20),
      TweenSequenceItem(tween: Tween(begin: -8, end: 8), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 8, end: 0), weight: 20),
    ]).animate(CurvedAnimation(parent: _shakeController, curve: Curves.linear));
  }

  @override
  void dispose() {
    _floatController.dispose();
    _happyController.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  void _triggerHappy() {
    _happyController.forward(from: 0);
  }

  void _triggerShake() {
    _shakeController.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<StoryProvider>(
      builder: (context, provider, _) {
        if (provider.isBuddyHappy) {
          WidgetsBinding.instance.addPostFrameCallback((_) => _triggerHappy());
        }
        if (provider.isBuddyShaking) {
          WidgetsBinding.instance.addPostFrameCallback((_) => _triggerShake());
        }

        return AnimatedBuilder(
          animation: Listenable.merge(
              [_floatController, _happyController, _shakeController]),
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(_shakeAnim.value, _floatAnim.value),
              child: Transform.scale(
                scale: _scaleAnim.value,
                child: child,
              ),
            );
          },
          child: _BuddyFace(
            audioState: provider.audioState,
            answerResult: provider.answerResult,
          ),
        );
      },
    );
  }
}

class _BuddyFace extends StatelessWidget {
  final AudioState audioState;
  final AnswerResult answerResult;

  const _BuddyFace({required this.audioState, required this.answerResult});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 140,
      height: 140,
      child: CustomPaint(
        painter: _RobotPainter(
          isHappy: answerResult == AnswerResult.correct,
          isTalking: audioState == AudioState.playing,
          isSad: answerResult == AnswerResult.wrong,
        ),
      ),
    );
  }
}

class _RobotPainter extends CustomPainter {
  final bool isHappy;
  final bool isTalking;
  final bool isSad;

  _RobotPainter({
    required this.isHappy,
    required this.isTalking,
    required this.isSad,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // ── Body ──────────────────────────────────────────────────────────────
    final bodyPaint = Paint()..color = const Color(0xFF5B8DEF);
    final bodyRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.18, h * 0.42, w * 0.64, h * 0.50),
      const Radius.circular(18),
    );
    canvas.drawRRect(bodyRect, bodyPaint);

    // Body highlight
    final highlightPaint = Paint()
      ..color = Colors.white.withOpacity(0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawRRect(bodyRect, highlightPaint);

    // Chest gear
    final gearPaint = Paint()..color = const Color(0xFFFFD700);
    canvas.drawCircle(Offset(w * 0.50, h * 0.66), w * 0.08, gearPaint);
    canvas.drawCircle(
      Offset(w * 0.50, h * 0.66),
      w * 0.05,
      Paint()..color = const Color(0xFFFFF9C4),
    );

    // ── Head ──────────────────────────────────────────────────────────────
    final headPaint = Paint()..color = const Color(0xFF3A6BE8);
    final headRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.14, h * 0.08, w * 0.72, h * 0.40),
      const Radius.circular(22),
    );
    canvas.drawRRect(headRect, headPaint);

    // Antenna
    final antennaPaint = Paint()
      ..color = const Color(0xFFFFD700)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
        Offset(w * 0.50, h * 0.08), Offset(w * 0.50, h * -0.02), antennaPaint);
    canvas.drawCircle(
        Offset(w * 0.50, h * -0.04), 5, Paint()..color = const Color(0xFFFF6B6B));

    // ── Eyes ──────────────────────────────────────────────────────────────
    _drawEye(canvas, Offset(w * 0.33, h * 0.23), w * 0.085);
    _drawEye(canvas, Offset(w * 0.67, h * 0.23), w * 0.085);

    // ── Mouth ─────────────────────────────────────────────────────────────
    final mouthPaint = Paint()
      ..color = isHappy
          ? const Color(0xFF4CAF50)
          : isSad
              ? const Color(0xFFFF5252)
              : const Color(0xFF90CAF9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;

    final mouthPath = Path();
    if (isHappy) {
      // Big smile
      mouthPath.moveTo(w * 0.30, h * 0.36);
      mouthPath.quadraticBezierTo(w * 0.50, h * 0.46, w * 0.70, h * 0.36);
    } else if (isSad) {
      // Frown
      mouthPath.moveTo(w * 0.30, h * 0.40);
      mouthPath.quadraticBezierTo(w * 0.50, h * 0.32, w * 0.70, h * 0.40);
    } else if (isTalking) {
      // Open O mouth
      canvas.drawOval(
        Rect.fromCenter(
            center: Offset(w * 0.50, h * 0.38), width: 18, height: 12),
        Paint()..color = const Color(0xFF90CAF9),
      );
      return;
    } else {
      // Neutral small smile
      mouthPath.moveTo(w * 0.35, h * 0.38);
      mouthPath.quadraticBezierTo(w * 0.50, h * 0.44, w * 0.65, h * 0.38);
    }
    canvas.drawPath(mouthPath, mouthPaint);
  }

  void _drawEye(Canvas canvas, Offset center, double radius) {
    // Eye white
    canvas.drawCircle(center, radius, Paint()..color = Colors.white);
    // Pupil
    final pupilOffset =
        isHappy ? Offset(center.dx, center.dy - 2) : center;
    canvas.drawCircle(
        pupilOffset, radius * 0.52, Paint()..color = const Color(0xFF1A237E));
    // Shine
    canvas.drawCircle(
      Offset(center.dx + radius * 0.25, center.dy - radius * 0.25),
      radius * 0.18,
      Paint()..color = Colors.white,
    );
    // Eyelid if happy (squint)
    if (isHappy) {
      final lidPaint = Paint()
        ..color = const Color(0xFF3A6BE8)
        ..style = PaintingStyle.fill;
      final lidPath = Path()
        ..moveTo(center.dx - radius, center.dy - radius * 0.2)
        ..quadraticBezierTo(
            center.dx, center.dy - radius * 1.1, center.dx + radius, center.dy - radius * 0.2)
        ..close();
      canvas.drawPath(lidPath, lidPaint);
    }
  }

  @override
  bool shouldRepaint(_RobotPainter old) =>
      old.isHappy != isHappy ||
      old.isTalking != isTalking ||
      old.isSad != isSad;
}
