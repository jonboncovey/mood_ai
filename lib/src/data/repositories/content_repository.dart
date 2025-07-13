import 'package:mood_ai/src/data/services/database_service.dart';
import 'package:mood_ai/src/models/models.dart';
import 'package:sqflite/sqflite.dart';

class ContentRepository {
  final DatabaseService _databaseService = DatabaseService.instance;

  Future<List<Movie>> getPopularMovies({int limit = 20}) async {
    try {
      final db = await _databaseService.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'movies',
        orderBy: 'popularity DESC',
        limit: limit,
      );

      // ignore: avoid_print
      print('Found ${maps.length} popular movies.');

      if (maps.isEmpty) {
        return [];
      }

      return List.generate(maps.length, (i) {
        return Movie.fromMap(maps[i]);
      });
    } on DatabaseException catch (e) {
      // ignore: avoid_print
      print('Database error in getPopularMovies: $e');
      rethrow;
    } catch (e) {
      // ignore: avoid_print
      print('Generic error in getPopularMovies: $e');
      rethrow;
    }
  }

  Future<List<Movie>> getMoviesByGenre(
    String genre, {
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final db = await _databaseService.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'movies',
        where: "genres LIKE ?",
        whereArgs: ['%$genre%'],
        orderBy: 'popularity DESC',
        limit: limit,
        offset: (page - 1) * limit,
      );

      // ignore: avoid_print
      print('Found ${maps.length} movies for genre: $genre, page: $page');

      if (maps.isEmpty) {
        return [];
      }
      return List.generate(maps.length, (i) => Movie.fromMap(maps[i]));
    } catch (e) {
      // ignore: avoid_print
      print('Error fetching movies by genre: $e');
      rethrow;
    }
  }

  Future<List<Movie>> searchMoviesByTitle(String query, {int limit = 5}) async {
    if (query.isEmpty) {
      return [];
    }
    try {
      final db = await _databaseService.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'movies',
        where: "title LIKE ?",
        whereArgs: ['%$query%'],
        orderBy: 'popularity DESC',
        limit: limit,
      );

      // ignore: avoid_print
      print('Found ${maps.length} movies for search query: $query');

      if (maps.isEmpty) {
        return [];
      }
      return List.generate(maps.length, (i) => Movie.fromMap(maps[i]));
    } catch (e) {
      // ignore: avoid_print
      print('Error searching movies: $e');
      rethrow;
    }
  }
}
