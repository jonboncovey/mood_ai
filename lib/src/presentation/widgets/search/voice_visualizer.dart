import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mood_ai/src/logic/discovery/discovery_bloc.dart';
import 'package:mood_ai/src/logic/discovery/discovery_state.dart';

class VoiceVisualizer extends StatefulWidget {
  const VoiceVisualizer({Key? key}) : super(key: key);

  @override
  _VoiceVisualizerState createState() => _VoiceVisualizerState();
}

class _VoiceVisualizerState extends State<VoiceVisualizer> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          BlocBuilder<DiscoveryBloc, DiscoveryState>(
            buildWhen: (p, c) => p.soundLevel != c.soundLevel,
            builder: (context, state) {
              return TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0.0, end: state.soundLevel),
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                builder: (context, soundLevel, child) {
                  return AnimatedBuilder(
                    animation: _animationController,
                    builder: (context, child) {
                      return CustomPaint(
                        size: const Size.square(200),
                        painter: _VisualizerPainter(
                          soundLevel: soundLevel,
                          color: Theme.of(context).colorScheme.primary,
                          animationValue: _animationController.value,
                        ),
                      );
                    },
                  );
                },
              );
            },
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

class _VisualizerPainter extends CustomPainter {
  final double soundLevel;
  final Color color;
  final double animationValue;
  final Paint _paint;
  final int dotCount = 20;
  final double minDotRadius = 5.0;
  final double maxDotRadius = 15.0;

  _VisualizerPainter({
    required this.soundLevel,
    required this.color,
    required this.animationValue,
  }) : _paint = Paint()..color = color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width / 2.5;
    final angleStep = (2 * pi) / dotCount;
    final color2 = Color.lerp(color, Colors.white, 0.4)!;

    final normalizedSound = (soundLevel * 5).clamp(0.0, 1.0);
    final pulseFactor = 0.5 + (sin(animationValue * 2 * pi) * 0.5);
    final currentRadius = maxRadius * normalizedSound * (0.8 + pulseFactor * 0.2);

    for (int i = 0; i < dotCount; i++) {
      final angle = i * angleStep;
      final dotRadius = minDotRadius + (maxDotRadius - minDotRadius) * normalizedSound * pulseFactor;

      final waveFactor = sin(angle * 4 + animationValue * 2 * pi);
      final animatedRadius = dotRadius + waveFactor * 4;

      _paint.color = (i.isEven ? color : color2)
          .withOpacity((normalizedSound * 0.7 + 0.3).clamp(0.3, 1.0));

      final x = center.dx + currentRadius * cos(angle);
      final y = center.dy + currentRadius * sin(angle);

      canvas.drawCircle(Offset(x, y),
          animatedRadius.clamp(minDotRadius, maxDotRadius), _paint);
    }
  }

  @override
  bool shouldRepaint(covariant _VisualizerPainter oldDelegate) {
    return oldDelegate.soundLevel != soundLevel || oldDelegate.animationValue != animationValue;
  }
} 