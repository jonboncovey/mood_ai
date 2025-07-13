import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mood_ai/src/data/repositories/auth_repository.dart';
import 'package:mood_ai/src/data/repositories/content_repository.dart';
import 'package:mood_ai/src/data/services/database_service.dart';
import 'package:mood_ai/src/logic/auth/auth_cubit.dart';
import 'package:mood_ai/src/presentation/screens/app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DatabaseService.instance.database; // Initialize the database

  final authRepository = AuthRepository();
  final contentRepository = ContentRepository();

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
        ],
        child: const App(),
      ),
    ),
  );
}
