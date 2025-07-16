import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:mood_ai/src/data/repositories/auth_repository.dart';
import 'package:mood_ai/src/data/repositories/content_repository.dart';
import 'package:mood_ai/src/data/services/database_service.dart';
import 'package:mood_ai/src/logic/auth/auth_cubit.dart';
import 'package:mood_ai/src/logic/streaming_platforms/streaming_platforms_cubit.dart';
import 'package:mood_ai/src/presentation/screens/app.dart';
import 'package:mood_ai/src/utils/streaming_cache.dart';

Future<void> main() async {
  await dotenv.load(fileName: ".env");
  WidgetsFlutterBinding.ensureInitialized();
  await DatabaseService.instance.database; // Initialize the database
  await StreamingCache().load(); // Load the streaming cache

  final authRepository = AuthRepository();
  final databaseService = DatabaseService.instance;
  final contentRepository = ContentRepository(databaseService: databaseService);

  runApp(
    MultiRepositoryProvider(
      providers: [
        RepositoryProvider.value(value: authRepository),
        RepositoryProvider.value(value: contentRepository),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (context) =>
                AuthCubit(authRepository: authRepository)..checkAuthStatus(),
          ),
          BlocProvider(
            create: (context) => StreamingPlatformsCubit(),
          ),
        ],
        child: const App(),
      ),
    ),
  );
}
