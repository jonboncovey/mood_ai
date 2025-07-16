import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

import '../config/app_config.dart';
import '../data/services/database_service.dart';

const String apiBaseUrl = 'https://streaming-availability.p.rapidapi.com';

class StreamingOptionsUpdater {
  // Test method to force clear all timestamps and run sync
  static Future<void> forceUpdateStreamingOptions([List<String>? selectedPlatforms]) async {
    print('Forcing streaming options update...');
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('lastStreamingSyncCursor');
    print('Cleared last sync cursor.');
    
    // Now, call the main update function to start from the beginning
    await updateStreamingOptionsForMovies(forceUpdate: true);
  }

  // Test method to check database state
  static Future<void> checkDatabaseState() async {
    try {
      final db = await DatabaseService.instance.database;
      
      // Check if streaming_options column exists
      print('=== DATABASE STATE CHECK ===');
      
      final tableInfo = await db.rawQuery("PRAGMA table_info(master_movies)");
      print('Table columns:');
      for (final column in tableInfo) {
        print('  ${column['name']}: ${column['type']}');
      }
      
      // Check if streaming_options column exists
      final hasStreamingColumn = tableInfo.any((col) => col['name'] == 'streaming_options');
      print('Has streaming_options column: $hasStreamingColumn');
      
      if (hasStreamingColumn) {
        // Check how many movies have streaming options
        final countResult = await db.rawQuery(
          'SELECT COUNT(*) as count FROM master_movies WHERE streaming_options IS NOT NULL'
        );
        final count = countResult.first['count'] as int;
        print('Movies with streaming options: $count');
        
        // Show some sample data
        final sampleData = await db.rawQuery(
          'SELECT title, streaming_options FROM master_movies WHERE streaming_options IS NOT NULL LIMIT 5'
        );
        print('Sample streaming options data:');
        for (final row in sampleData) {
          print('  ${row['title']}: ${row['streaming_options']}');
        }
      }
      
      // Check metadata table
      final metadataExists = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='streaming_update_metadata'"
      );
      print('Metadata table exists: ${metadataExists.isNotEmpty}');
      
      if (metadataExists.isNotEmpty) {
        final metadataData = await db.query('streaming_update_metadata');
        print('Metadata data: $metadataData');
      }
      
      print('=== END DATABASE STATE CHECK ===');
      
    } catch (e) {
      print('Error checking database state: $e');
    }
  }

  static Future<void> updateStreamingOptionsForMovies(
      {bool forceUpdate = false}) async {
    // Check the feature flag first
    if (!AppConfig.streamingFeatureEnabled) {
      print('Streaming feature is disabled. Skipping update.');
      return;
    }
        
    print('Starting to update streaming options for movies...');
    final prefs = await SharedPreferences.getInstance();
    final db = await DatabaseService.instance.database;

    try {
      final lastSyncCursor = prefs.getString('lastStreamingSyncCursor');
      print('Resuming from cursor: $lastSyncCursor');

      final result = await _fetchAndProcessStreamingDataInBatches(db, cursor: lastSyncCursor);
      final newCursor = result['cursor'];

      if (newCursor != null && newCursor.isNotEmpty) {
        await prefs.setString('lastStreamingSyncCursor', newCursor);
        print('Sync paused. Next cursor saved: $newCursor');
      } else {
        // Reached the end, clear the cursor to start over next time
        await prefs.remove('lastStreamingSyncCursor');
        print('Sync complete. Reached the end of the catalog.');
      }

      print('Finished updating streaming options for this batch.');
    } catch (e) {
      print('An error occurred during movie streaming options update: $e');
    }
  }

  static Future<Map<String, dynamic>> _fetchAndProcessStreamingDataInBatches(
      Database db, {String? cursor}) async {
    final client = http.Client();
    String? nextCursor = cursor;
    int maxPages = 5; // Process 5 pages at a time
    int currentPage = 0;

    while (currentPage < maxPages) {
      final queryParams = {
        'country': 'us',
        'catalogs': 'netflix, hulu',
        'output_language': 'en',
      };

      if (nextCursor != null) {
        queryParams['cursor'] = nextCursor;
      }

      final uri = Uri.parse('$apiBaseUrl/shows/search/filters').replace(queryParameters: queryParams);

      final response = await client.get(
        uri,
        headers: {
          'X-RapidAPI-Key': dotenv.env['MOVIE_OF_THE_NIGHTS_API_KEY']!,
          'X-RapidAPI-Host': 'streaming-availability.p.rapidapi.com',
        },
      );

      if (response.statusCode == 200) {
        final decodedResponse = jsonDecode(response.body);
        print('Decoded response: $decodedResponse');
        final streamingData =
            List<Map<String, dynamic>>.from(decodedResponse['shows'] ?? []);
        print('Streaming data: $streamingData');
        nextCursor = decodedResponse['nextCursor'];

        if (streamingData.isNotEmpty) {
          // ... (logging remains the same)
          print('--- API Results (Page ${currentPage + 1}) ---');
          for (final show in streamingData) {
            final title = show['title'] ?? 'No Title';
            final year = show['year'] ?? 'N/A';
            final imdbId = show['imdbId'] ?? 'No IMDB ID';
            final tmdbId = show['tmdbId'] ?? 'No TMDB ID';
            print('  - Title: $title, Year: $year, IMDB: $imdbId, TMDB: $tmdbId');
          }
          print('------------------------------------');

          print(
              'Fetched API page ${currentPage + 1} with ${streamingData.length} shows.');
          await _updateMoviesWithStreamingOptionsOptimized(db, streamingData);
        } else {
          print('API page ${currentPage + 1} returned 0 shows.');
        }

        currentPage++;

        if (nextCursor == null || nextCursor.isEmpty) {
          print('No next cursor found. Ending sync.');
          break;
        }
      } else {
        print(
            'Failed to fetch streaming data (page ${currentPage + 1}): ${response.statusCode}');
        print('Response body: ${response.body}');
        break;
      }
    }
    client.close();
    return {'cursor': nextCursor};
  }

  static Future<List<Map<String, dynamic>>> _getAllMovies(db) async {
    return await db.query('master_movies', columns: ['id', 'title', 'imdb_id', 'release_date']);
  }

  static Future<void> _updateMoviesWithStreamingOptionsOptimized(
      Database db, List<Map<String, dynamic>> apiShows) async {
    final allLocalMovies = await _getAllMovies(db);
    int updatedCount = 0;
    
    print('Checking ${allLocalMovies.length} local movies against ${apiShows.length} API shows...');

    for (final localMovie in allLocalMovies) {
      final streamingOptions =
          _findStreamingOptionsForMovie(localMovie, apiShows);

      if (streamingOptions != null) {
        final movieId = localMovie['id'];
        final streamingOptionsJson = jsonEncode(streamingOptions);

        // print(
        //     'DB UPDATE PREPARED: Movie ID: $movieId, Options: $streamingOptionsJson');

        await db.update(
          'master_movies',
          {'streaming_options': streamingOptionsJson},
          where: 'id = ?',
          whereArgs: [movieId],
        );
        updatedCount++;
      }
    }
    print('Batch update complete. Updated $updatedCount movies in the database.');
  }

  static Map<String, dynamic>? _findStreamingOptionsForMovie(
    Map<String, dynamic> movie,
    List<Map<String, dynamic>> streamingData,
  ) {
    try {
      // Trim to be safe
      final movieImdbId = (movie['imdb_id'] as String? ?? '').trim();

      // If our local movie has no imdb_id, we can't match it.
      if (movieImdbId.isEmpty) {
        return null;
      }

      for (final show in streamingData) {
        // Trim to be safe
        final showImdbId = (show['imdbId'] as String? ?? '').trim();

        // The user is positive this match should happen. Let's make the comparison the only thing that matters.
        if (movieImdbId == showImdbId) {
          // Add a very clear log when a match is found
          print(
              'IMDB MATCH FOUND: Local: ${movie['title']} (${movieImdbId}) matches API: ${show['title']} (${showImdbId})');
          return _extractStreamingOptions(show);
        }
      }
    } catch (e) {
      print('Error in _findStreamingOptionsForMovie: $e');
    }

    // No match was found for this movie.
    return null;
  }
  
  static String _extractYear(String releaseDate) {
    if (releaseDate.isEmpty) return '';
    final parts = releaseDate.split('-');
    return parts.isNotEmpty ? parts[0] : '';
  }
  
  static bool _isTextMatch(String title1, String title2) {
    // Simple text matching - can be improved with fuzzy matching
    return title1 == title2 || 
           title1.contains(title2) || 
           title2.contains(title1);
  }
  
  static Map<String, dynamic> _extractStreamingOptions(Map<String, dynamic> show) {
    try {
      final streamingOptions = show['streamingOptions'];
      if (streamingOptions is! Map) return {};

      // The user has specified we are only interested in 'us' services.
      final usServices = streamingOptions['us'];
      if (usServices is! List) return {};

      final List<Map<String, String>> services = [];
      for (final serviceInfo in usServices) {
        if (serviceInfo is Map) {
          final serviceName = serviceInfo['service']?['name'] as String? ?? 'N/A';
          final type = serviceInfo['type'] as String? ?? 'N/A';
          final link = serviceInfo['link'] as String? ?? '';
          services.add({
            'service': serviceName,
            'type': type,
            'link': link,
          });
        }
      }
      // Return the list of services under the 'us' key.
      return {'us': services};
    } catch (e) {
      print('Error parsing streaming options: $e');
      return {};
    }
  }
  
  static Future<void> _updateMovieStreamingOptions(
    db, 
    int movieId, 
    Map<String, dynamic> streamingOptions
  ) async {
    final jsonString = jsonEncode(streamingOptions);
    
    await db.update(
      'master_movies',
      {'streaming_options': jsonString},
      where: 'id = ?',
      whereArgs: [movieId],
    );
  }
} 