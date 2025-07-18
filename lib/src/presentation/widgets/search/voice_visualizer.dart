import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mood_ai/src/logic/discovery/discovery_bloc.dart';
import 'package:mood_ai/src/logic/discovery/discovery_state.dart';

class VoiceVisualizer extends StatelessWidget {
  const VoiceVisualizer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          BlocBuilder<DiscoveryBloc, DiscoveryState>(
            buildWhen: (p, c) => p.soundLevel != c.soundLevel,
            builder: (context, state) {
              return CustomPaint(
                size: const Size.square(200),
                painter: _VisualizerPainter(
                  soundLevel: state.soundLevel,
                  color: Theme.of(context).colorScheme.primary,
                ),
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
  final Paint _paint;
  final int dotCount = 20;
  final double minDotRadius = 5.0;
  final double maxDotRadius = 15.0;

  _VisualizerPainter({required this.soundLevel, required this.color})
      : _paint = Paint()..color = color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width / 2.5;
    final angleStep = (2 * pi) / dotCount;
    final color2 = Color.lerp(color, Colors.white, 0.4)!;

    final normalizedSound = (soundLevel * 5).clamp(0.0, 1.0);
    final currentRadius = maxRadius * normalizedSound;

    for (int i = 0; i < dotCount; i++) {
      final angle = i * angleStep;
      final dotRadius =
          minDotRadius + (maxDotRadius - minDotRadius) * normalizedSound;

      final waveFactor =
          sin(angle * 4 + DateTime.now().millisecondsSinceEpoch * 0.005);
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
    return true;
  }
} 