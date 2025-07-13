import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mood_ai/src/data/repositories/auth_repository.dart';
import 'package:mood_ai/src/models/models.dart';
import 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final AuthRepository _authRepository;

  AuthCubit({required AuthRepository authRepository})
      : _authRepository = authRepository,
        super(const AuthState.unknown());

  Future<void> checkAuthStatus() async {
    try {
      final user = await _authRepository.checkAuthStatus();
      if (user != null) {
        emit(AuthState.authenticated(user));
      } else {
        emit(const AuthState.unauthenticated());
      }
    } catch (e) {
      emit(const AuthState.unauthenticated());
    }
  }

  Future<void> signUp(String email, String password) async {
    try {
      final user = await _authRepository.signUp(email, password);
      emit(AuthState.authenticated(user));
    } on Exception catch (e) {
      emit(AuthState.failure(e.toString().replaceFirst("Exception: ", "")));
    }
  }

  Future<void> logIn(String email, String password) async {
    try {
      final user = await _authRepository.logIn(email, password);
      emit(AuthState.authenticated(user));
    } on Exception catch (e) {
      emit(AuthState.failure(e.toString().replaceFirst("Exception: ", "")));
    }
  }

  Future<void> logOut() async {
    await _authRepository.logOut();
    emit(const AuthState.unauthenticated());
  }
}
