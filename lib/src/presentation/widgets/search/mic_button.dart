import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mood_ai/src/logic/discovery/discovery_bloc.dart';
import 'package:mood_ai/src/logic/discovery/discovery_event.dart';
import 'package:mood_ai/src/logic/discovery/discovery_state.dart';

class MicButton extends StatefulWidget {
  const MicButton({Key? key}) : super(key: key);
  @override
  _MicButtonState createState() => _MicButtonState();
}

class _MicButtonState extends State<MicButton> {
  bool _isButtonPressed = false;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DiscoveryBloc, DiscoveryState>(
      buildWhen: (p, c) => p.isListening != c.isListening,
      builder: (context, state) {
        final isListening = state.isListening;
        return GestureDetector(
          onLongPressStart: (_) {
            setState(() => _isButtonPressed = true);
            context.read<DiscoveryBloc>().add(StartVoiceSearch());
          },
          onLongPressEnd: (_) {
            setState(() => _isButtonPressed = false);
            context.read<DiscoveryBloc>().add(StopVoiceSearch());
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isListening
                  ? Colors.red.withOpacity(0.7)
                  : Theme.of(context).colorScheme.primary,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 8,
                  spreadRadius: 2,
                  offset: const Offset(0, 4),
                ),
                if (_isButtonPressed || isListening)
                  BoxShadow(
                    color: Colors.white.withOpacity(0.4),
                    blurRadius: 10,
                    spreadRadius: 2,
                  )
              ],
            ),
            child: Icon(
              isListening ? Icons.mic : Icons.mic_none,
              color: Colors.white,
              size: 32,
            ),
          ),
        );
      },
    );
  }
} 