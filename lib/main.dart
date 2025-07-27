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
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:mood_ai/src/logic/discovery/discovery_bloc.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:mood_ai/src/logic/discovery/discovery_event.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await dotenv.load(fileName: ".env");
  // await DatabaseService.instance.database; // Initialize the database
  // await StreamingCache().load(); // Load the streaming cache

  // final authRepository = AuthRepository();
  // final databaseService = DatabaseService.instance;
  // final contentRepository = ContentRepository(databaseService: databaseService);
  // final speechToText = SpeechToText();

  runApp(
    MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Debug'),
        ),
        body: const Center(
          child: Text('It works!'),
        ),
      ),
    ),
  );
  /*
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
          BlocProvider(
            create: (context) => DiscoveryBloc(
              contentRepository: contentRepository,
              speechToText: speechToText,
              streamingPlatformsCubit:
                  BlocProvider.of<StreamingPlatformsCubit>(context),
            )..add(const FetchDiscoveryData()),
          ),
        ],
        child: const App(),
      ),
    ),
  );
  */
}
