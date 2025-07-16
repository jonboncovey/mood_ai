import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_router/go_router.dart';
import 'package:mood_ai/src/config/app_config.dart';
import 'package:mood_ai/src/logic/streaming_platforms/streaming_platforms_cubit.dart';
import 'package:mood_ai/src/utils/streaming_options_updater.dart';
import 'package:mood_ai/src/logic/auth/auth_cubit.dart';
import 'package:mood_ai/src/logic/auth/auth_state.dart';

class LoadingScreen extends StatefulWidget {
  const LoadingScreen({Key? key}) : super(key: key);

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _rotationController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _rotationAnimation;

  String _statusMessage = 'Loading...';
  bool _isComplete = false;

  @override
  void initState() {
    super.initState();
    
    // Initialize animations
    _pulseController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );
    
    _rotationController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );
    
    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    
    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _rotationController,
      curve: Curves.linear,
    ));
    
    // Start animations
    _pulseController.repeat(reverse: true);
    _rotationController.repeat();
    
    // Start the loading process
    _performLoadingTasks();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rotationController.dispose();
    super.dispose();
  }

  Future<void> _performLoadingTasks() async {
    try {
      // Load streaming platforms
      setState(() {
        _statusMessage = 'Loading streaming platforms...';
      });
      
      await context.read<StreamingPlatformsCubit>().loadPlatforms();
      
      // Check if streaming update is needed
      setState(() {
        _statusMessage = 'Checking for streaming updates...';
      });
      
      await _checkAndUpdateStreaming();
      
      // Final step
      setState(() {
        _statusMessage = 'Finalizing...';
      });
      
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Complete
      setState(() {
        _statusMessage = 'Ready!';
        _isComplete = true;
      });
      
      // Stop animations
      _pulseController.stop();
      _rotationController.stop();
      
      // Navigate based on auth state
      await Future.delayed(const Duration(milliseconds: 800));
      if (mounted) {
        final authStatus = context.read<AuthCubit>().state.status;
        if (authStatus == AuthStatus.authenticated) {
          context.go('/main');
        } else {
          context.go('/login');
        }
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'Error: $e';
      });
    }
  }

  Future<void> _checkAndUpdateStreaming() async {
    // This logic is now handled by a manual button, but we leave the hook here.
    // We check the feature flag before doing anything.
    if (!AppConfig.streamingFeatureEnabled) {
      return;
    }
    // The automatic update logic has been removed.
    // You could re-add it here if needed in the future.
    print('Automatic streaming update is currently disabled.');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.primary.withOpacity(0.1),
              Theme.of(context).colorScheme.background,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo with animations
              AnimatedBuilder(
                animation: Listenable.merge([_pulseAnimation, _rotationAnimation]),
                builder: (context, child) {
                  return Transform.scale(
                    scale: _pulseAnimation.value,
                    child: Transform.rotate(
                      angle: _rotationAnimation.value * 2 * 3.14159,
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              Theme.of(context).colorScheme.primary,
                              Theme.of(context).colorScheme.primaryContainer,
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                              blurRadius: 20,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.movie,
                          color: Colors.white,
                          size: 60,
                        ),
                      ),
                    ),
                  );
                },
              ),
              
              const SizedBox(height: 40),
              
              // App name
              Text(
                'Mood AI',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              
              const SizedBox(height: 60),
              
              // Status message
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Text(
                  _statusMessage,
                  key: ValueKey(_statusMessage),
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Progress indicator
              if (!_isComplete)
                SizedBox(
                  width: 200,
                  child: LinearProgressIndicator(
                    backgroundColor: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Theme.of(context).colorScheme.primary,
                    ),
                  ),
                )
              else
                Icon(
                  Icons.check_circle,
                  color: Theme.of(context).colorScheme.primary,
                  size: 32,
                ),
              
              const SizedBox(height: 40),
              
              // Subtitle
              Text(
                'Finding the perfect movies for your mood',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
} 