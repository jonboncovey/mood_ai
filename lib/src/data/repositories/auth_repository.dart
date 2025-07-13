import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:mood_ai/src/models/models.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthRepository {
  static const String _loggedInUserKey = 'logged_in_user_email';
  static const String _userDatabaseKey = 'user_database';

  // Simulates checking if a user is logged in
  Future<User?> checkAuthStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final userEmail = prefs.getString(_loggedInUserKey);
    if (userEmail != null) {
      return User(id: userEmail, email: userEmail, name: 'User');
    }
    return null;
  }

  // Gets the simulated user database
  Future<Map<String, dynamic>> _getUserDatabase() async {
    final prefs = await SharedPreferences.getInstance();
    final dbString = prefs.getString(_userDatabaseKey);
    if (dbString != null && dbString.isNotEmpty) {
      return json.decode(dbString) as Map<String, dynamic>;
    }
    return {};
  }

  // Saves the simulated user database
  Future<void> _saveUserDatabase(Map<String, dynamic> db) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userDatabaseKey, json.encode(db));
  }

  // Hashes the password
  String _hashPassword(String password) {
    final bytes = utf8.encode(password); // data being hashed
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  Future<User> signUp(String email, String password) async {
    final db = await _getUserDatabase();
    if (db.containsKey(email)) {
      throw Exception('Email already exists. Please sign in.');
    }

    final hashedPassword = _hashPassword(password);
    db[email] = hashedPassword;
    await _saveUserDatabase(db);

    // Automatically log in after sign up
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_loggedInUserKey, email);

    return User(id: email, email: email, name: 'User');
  }

  Future<User> logIn(String email, String password) async {
    final db = await _getUserDatabase();
    if (!db.containsKey(email)) {
      throw Exception('User not found. Please sign up.');
    }

    final storedPasswordHash = db[email];
    final providedPasswordHash = _hashPassword(password);

    if (storedPasswordHash != providedPasswordHash) {
      throw Exception('Invalid password.');
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_loggedInUserKey, email);

    return User(id: email, email: email, name: 'User');
  }

  Future<void> logOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_loggedInUserKey);
  }
}
