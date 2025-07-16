import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:mood_ai/src/logic/streaming_platforms/streaming_platforms_cubit.dart';
import 'package:mood_ai/src/presentation/widgets/streaming_platforms_dialog.dart';
import 'package:mood_ai/src/presentation/screens/discovery_screen.dart';
import 'package:mood_ai/src/config/app_config.dart';

class MainScreen extends StatelessWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mood AI'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        elevation: 0,
        actions: [
          // Streaming platforms filter button
          BlocBuilder<StreamingPlatformsCubit, StreamingPlatformsState>(
            builder: (context, state) {
              return IconButton(
                onPressed: () {
                  _showStreamingPlatformsDialog(context);
                },
                icon: Stack(
                  children: [
                    const Icon(Icons.tune),
                    if (state.selectedPlatforms.isNotEmpty)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
                tooltip: 'Filter Streaming Platforms',
              );
            },
          ),
          if (AppConfig.streamingFeatureEnabled)
            IconButton(
              icon: Icon(Icons.stream),
              onPressed: () {
                context.go('/streaming-test');
              },
            ),
        ],
      ),
      body: const DiscoveryScreen(),
    );
  }

  void _showStreamingPlatformsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const StreamingPlatformsDialog(),
    );
  }
} 