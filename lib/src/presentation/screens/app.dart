import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:mood_ai/src/config/theme/theme.dart';
import 'package:mood_ai/src/logic/auth/auth_cubit.dart';
import 'package:mood_ai/src/logic/auth/auth_state.dart';
import 'package:mood_ai/src/models/movie.dart';
import 'package:mood_ai/src/presentation/screens/content_details_screen.dart';
import 'package:mood_ai/src/presentation/screens/discovery_screen.dart';
import 'package:mood_ai/src/presentation/screens/genre_screen.dart';
import 'package:mood_ai/src/presentation/screens/login_screen.dart';
import 'package:mood_ai/src/presentation/screens/splash_screen.dart';

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  late final GoRouter _router;
  late final AuthCubit _authCubit;

  @override
  void initState() {
    super.initState();
    _authCubit = context.read<AuthCubit>();
    final refreshStream = GoRouterRefreshStream(_authCubit.stream);

    _router = GoRouter(
      refreshListenable: refreshStream,
      initialLocation: '/splash',
      routes: [
        GoRoute(
          path: '/splash',
          builder: (context, state) => const SplashScreen(),
        ),
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/discovery',
          builder: (context, state) => const DiscoveryScreen(),
        ),
        GoRoute(
          path: '/details',
          builder: (context, state) {
            final movie = state.extra as Movie;
            return ContentDetailsScreen(movie: movie);
          },
        ),
        GoRoute(
          path: '/genre/:name',
          builder: (context, state) {
            final genreName = state.pathParameters['name']!;
            return GenreScreen(genre: genreName);
          },
        ),
      ],
      redirect: (BuildContext context, GoRouterState state) {
        final authState = context.read<AuthCubit>().state;
        final location = state.uri.toString();

        if (authState.status == AuthStatus.unauthenticated &&
            location != '/login') {
          return '/login';
        }
        if (authState.status == AuthStatus.authenticated &&
            (location == '/login' || location == '/splash')) {
          return '/discovery';
        }

        return null;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Mood AI',
      theme: AppTheme.darkTheme,
      routerConfig: _router,
      debugShowCheckedModeBanner: false,
    );
  }
}

class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen((_) => notifyListeners());
  }
  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
