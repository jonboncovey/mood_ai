import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:mood_ai/src/config/app_config.dart';
import 'package:mood_ai/src/logic/auth/auth_cubit.dart';
import 'package:mood_ai/src/logic/streaming_platforms/streaming_platforms_cubit.dart';
import 'package:mood_ai/src/presentation/widgets/streaming_platforms_dialog.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
      ),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Settings'),
            onTap: () {
              // Navigate to a settings screen or show a dialog
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.tune),
            title: const Text('Filter Streaming Platforms'),
            trailing:
                BlocBuilder<StreamingPlatformsCubit, StreamingPlatformsState>(
              builder: (context, state) {
                if (state.selectedPlatforms.isNotEmpty) {
                  return Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
            onTap: () {
              _showStreamingPlatformsDialog(context);
            },
          ),
          if (AppConfig.streamingFeatureEnabled)
            ListTile(
              leading: const Icon(Icons.stream),
              title: const Text('Streaming Test'),
              onTap: () {
                context.go('/streaming-test');
              },
            ),
          const Divider(),
          ListTile(
            leading: Icon(Icons.logout, color: Colors.red.shade400),
            title: Text('Sign Out', style: TextStyle(color: Colors.red.shade400)),
            onTap: () {
              context.read<AuthCubit>().logOut();
            },
          ),
        ],
      ),
    );
  }

  void _showStreamingPlatformsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const StreamingPlatformsDialog(),
    );
  }
}
