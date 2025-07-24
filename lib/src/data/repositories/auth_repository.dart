import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:mood_ai/src/models/models.dart';

class AuthRepository {
  final firebase_auth.FirebaseAuth _firebaseAuth;

  AuthRepository({firebase_auth.FirebaseAuth? firebaseAuth})
      : _firebaseAuth = firebaseAuth ?? firebase_auth.FirebaseAuth.instance;

  Future<User?> checkAuthStatus() async {
    final firebaseUser = _firebaseAuth.currentUser;
    if (firebaseUser != null) {
      return User(
        id: firebaseUser.uid,
        email: firebaseUser.email ?? 'No email',
        name: firebaseUser.displayName ?? 'No name',
      );
    }
    return null;
  }

  Future<User> signUp(String email, String password) async {
    try {
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final firebaseUser = credential.user;
      if (firebaseUser != null) {
        return User(
          id: firebaseUser.uid,
          email: firebaseUser.email ?? 'No email',
          name: firebaseUser.displayName ?? 'No name',
        );
      }
      throw Exception('Sign up failed: User is null.');
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw Exception('Sign up failed: ${e.message}');
    }
  }

  Future<User> logIn(String email, String password) async {
    try {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final firebaseUser = credential.user;
      if (firebaseUser != null) {
        return User(
          id: firebaseUser.uid,
          email: firebaseUser.email ?? 'No email',
          name: firebaseUser.displayName ?? 'No name',
        );
      }
      throw Exception('Log in failed: User is null.');
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw Exception('Log in failed: ${e.message}');
    }
  }

  Future<void> logOut() async {
    await _firebaseAuth.signOut();
  }
}
