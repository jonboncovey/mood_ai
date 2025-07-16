import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:mood_ai/src/data/services/database_service.dart';
import 'package:mood_ai/src/models/models.dart';
import 'package:sqflite/sqflite.dart';

class ContentRepository {
  final DatabaseService _databaseService;

  ContentRepository({required DatabaseService databaseService}) : _databaseService = databaseService;

  static const List<String> allGenres = [
    'Action', 'Science Fiction', 'Adventure', 'Drama', 'Crime', 'Thriller', 'Fantasy', 'Comedy', 'Western', 'War', 'Family', 'Mystery', 'Horror', 'Romance', 'History', 'Animation', 'Music', 'TV Movie', 'Documentary'
    // Cleaned and unique genres from the provided list
  ];

  // Helper method to build streaming platform filter
  String _buildStreamingFilter(List<String> selectedPlatforms) {
    if (selectedPlatforms.isEmpty) {
      return '';
    }
    
    // Build OR conditions for each selected platform
    final conditions = selectedPlatforms.map((platform) => 
      "streaming_options LIKE '%\"$platform\":%'"
    ).join(' OR ');
    
    return "streaming_options IS NOT NULL AND ($conditions)";
  }

  // Helper method to combine WHERE conditions
  String _combineWhereConditions(String baseCondition, String streamingCondition) {
    if (baseCondition.isEmpty && streamingCondition.isEmpty) {
      return '';
    } else if (baseCondition.isEmpty) {
      return streamingCondition;
    } else if (streamingCondition.isEmpty) {
      return baseCondition;
    } else {
      return '$baseCondition AND $streamingCondition';
    }
  }

  Future<List<Movie>> getPopularMovies({int limit = 20, List<String>? selectedPlatforms}) async {
    try {
      final db = await _databaseService.database;
      final streamingFilter = _buildStreamingFilter(selectedPlatforms ?? []);
      
      final List<Map<String, dynamic>> maps = await db.query(
        'master_movies',
        where: streamingFilter.isNotEmpty ? streamingFilter : null,
        orderBy: 'popularity DESC',
        limit: limit,
      );

      // ignore: avoid_print
      print('Found ${maps.length} popular movies with streaming filter: ${selectedPlatforms?.join(", ") ?? "none"}');

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

  Future<List<Movie>> getHiddenGems({int limit = 10, List<String>? selectedPlatforms}) async {
    try {
      final db = await _databaseService.database;
      final baseCondition = 'vote_average > 7.5 AND vote_count > 100 AND popularity < 50';
      final streamingFilter = _buildStreamingFilter(selectedPlatforms ?? []);
      final whereCondition = _combineWhereConditions(baseCondition, streamingFilter);
      
      final List<Map<String, dynamic>> maps = await db.query(
        'master_movies',
        where: whereCondition.isNotEmpty ? whereCondition : null,
        orderBy: 'popularity DESC',
        limit: limit,
      );
      
      print('Found ${maps.length} hidden gems with streaming filter: ${selectedPlatforms?.join(", ") ?? "none"}');
      
      if (maps.isEmpty) return [];
      return List.generate(maps.length, (i) => Movie.fromMap(maps[i]));
    } catch (e) {
      // ignore: avoid_print
      print('Error fetching hidden gems: $e');
      rethrow;
    }
  }

  Future<List<Movie>> getIndieDarlings({int limit = 10, List<String>? selectedPlatforms}) async {
    try {
      final db = await _databaseService.database;
      final baseCondition = 'budget > 0 AND budget < 1000000 AND popularity > 10';
      final streamingFilter = _buildStreamingFilter(selectedPlatforms ?? []);
      final whereCondition = _combineWhereConditions(baseCondition, streamingFilter);
      
      final List<Map<String, dynamic>> maps = await db.query(
        'master_movies',
        where: whereCondition.isNotEmpty ? whereCondition : null,
        orderBy: 'popularity DESC',
        limit: limit,
      );
      
      print('Found ${maps.length} indie darlings with streaming filter: ${selectedPlatforms?.join(", ") ?? "none"}');
      
      if (maps.isEmpty) return [];
      return List.generate(maps.length, (i) => Movie.fromMap(maps[i]));
    } catch (e) {
      // ignore: avoid_print
      print('Error fetching indie darlings: $e');
      rethrow;
    }
  }

  Future<List<Movie>> getCriticallyAcclaimed({int limit = 10, List<String>? selectedPlatforms}) async {
    try {
      final db = await _databaseService.database;
      final baseCondition = 'vote_average > 8.0 AND vote_count > 500';
      final streamingFilter = _buildStreamingFilter(selectedPlatforms ?? []);
      final whereCondition = _combineWhereConditions(baseCondition, streamingFilter);
      
      final List<Map<String, dynamic>> maps = await db.query(
        'master_movies',
        where: whereCondition.isNotEmpty ? whereCondition : null,
        orderBy: 'vote_average DESC',
        limit: limit,
      );
      
      print('Found ${maps.length} critically acclaimed movies with streaming filter: ${selectedPlatforms?.join(", ") ?? "none"}');
      
      if (maps.isEmpty) return [];
      return List.generate(maps.length, (i) => Movie.fromMap(maps[i]));
    } catch (e) {
      // ignore: avoid_print
      print('Error fetching critically acclaimed movies: $e');
      rethrow;
    }
  }

  Future<List<Movie>> getMoviesByGenre(
    String genre, {
    int page = 1,
    int limit = 20,
    List<String>? selectedPlatforms,
  }) async {
    try {
      final db = await _databaseService.database;
      final baseCondition = "genres LIKE '%$genre%'";
      final streamingFilter = _buildStreamingFilter(selectedPlatforms ?? []);
      final whereCondition = _combineWhereConditions(baseCondition, streamingFilter);
      
      final List<Map<String, dynamic>> maps = await db.query(
        'master_movies',
        where: whereCondition.isNotEmpty ? whereCondition : null,
        orderBy: 'popularity DESC',
        limit: limit,
        offset: (page - 1) * limit,
      );

      // ignore: avoid_print
      print('Found ${maps.length} movies for genre: $genre, page: $page, streaming filter: ${selectedPlatforms?.join(", ") ?? "none"}');

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

  Future<List<Movie>> searchMoviesByQuery(String query, {List<String>? selectedPlatforms}) async {
    if (query.isEmpty) return [];

    try {
      final prompt = '''
You are a SQL expert. Given a user's movie request, your task is to generate a JSON object containing a SQL WHERE clause to find matching movies from a database with a table named 'master_movies'.

The 'master_movies' table has the following relevant columns:
- `genres`: A string containing one or more genres, like "Action, Drama, Comedy".
- `overview`: A text description of the movie.
- `title`: The movie title.
- `popularity`: A numeric score.

Based on the user query: "$query"

Generate a JSON object with a single key "where_clause". The value should be a SQL WHERE clause that:
1. Attempts to filter by one or two relevant `genres` using the LIKE operator.
2. Filters by keywords or concepts from the user's query, using the LIKE operator on the `overview` or `title` columns.
3. Ensures `popularity` is greater than 25.
4. Do NOT include the "WHERE" keyword itself in the string. Only provide the conditions.

Example User Query: "I want a funny sci-fi movie about aliens"
Example JSON Output:
{
  "where_clause": "genres LIKE '%Comedy%' AND genres LIKE '%Science Fiction%' AND overview LIKE '%alien%' AND popularity > 25"
}

User Query: "I'm in the mood for a heartwarming story"
JSON Output:
{
  "where_clause": "(overview LIKE '%heartwarming%' OR title LIKE '%heartwarming%') AND popularity > 25"
}
''';

      final responseJson = await _callAzureOpenAI(prompt);
      final json = jsonDecode(responseJson);
      final whereClause = json['where_clause'] as String?;

      if (whereClause == null || whereClause.isEmpty) {
        // ignore: avoid_print
        print('AI did not return a valid where_clause.');
        return [];
      }

      // ignore: avoid_print
      print('Using AI-generated WHERE clause: $whereClause');

      final db = await _databaseService.database;
      final streamingFilter = _buildStreamingFilter(selectedPlatforms ?? []);
      final combinedWhereClause = _combineWhereConditions(whereClause, streamingFilter);
      
      final List<Map<String, dynamic>> maps = await db.query(
        'master_movies',
        where: combinedWhereClause.isNotEmpty ? combinedWhereClause : null,
        orderBy: 'popularity DESC',
        limit: 20, // Limit final results
      );

      print('Found ${maps.length} search results with streaming filter: ${selectedPlatforms?.join(", ") ?? "none"}');

      final List<Movie> filteredMovies = maps.map(Movie.fromMap).toList();

      return filteredMovies;
    } catch (e) {
      // ignore: avoid_print
      print('Error in AI search: $e');
      return [];
    }
  }

  Future<String> _callAzureOpenAI(String prompt) async {
    final key = dotenv.env['FOUNDRY_API_KEY'] ?? '';
    final endpoint = dotenv.env['AZURE_OPENAI_ENDPOINT'] ?? 'https://your-resource.openai.azure.com/';
    final deployment = dotenv.env['AZURE_OPENAI_DEPLOYMENT'] ?? 'gpt-35-turbo';
    final url = Uri.parse('$endpoint/openai/deployments/$deployment/chat/completions?api-version=2024-02-15-preview');

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'api-key': key,
      },
      body: jsonEncode({
        'messages': [
          {'role': 'system', 'content': 'You are a helpful assistant that responds in JSON.'},
          {'role': 'user', 'content': prompt},
        ],
        'temperature': 0.5,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['choices'][0]['message']['content'];
    } else {
      throw Exception('Failed to call Azure OpenAI: ${response.statusCode}. Body: ${response.body}');
    }
  }

  // Update the existing search method to use the new AI search
  Future<List<Movie>> searchMoviesByTitle(String query, {int limit = 20, List<String>? selectedPlatforms}) async {
    return searchMoviesByQuery(query, selectedPlatforms: selectedPlatforms);
  }
}
