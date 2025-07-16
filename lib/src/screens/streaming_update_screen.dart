import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mood_ai/src/logic/streaming_platforms/streaming_platforms_cubit.dart';
import 'package:mood_ai/src/data/repositories/content_repository.dart';
import '../config/app_config.dart';
import '../utils/streaming_options_updater.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'dart:io';
import 'package:share_plus/share_plus.dart';

// A simple stateful screen to manage streaming options
class StreamingUpdateScreen extends StatefulWidget {
  const StreamingUpdateScreen({Key? key}) : super(key: key);

  @override
  State<StreamingUpdateScreen> createState() => _StreamingUpdateScreenState();
}

class _StreamingUpdateScreenState extends State<StreamingUpdateScreen> {
  bool _isUpdating = false;
  String _statusMessage = 'Ready to update streaming options';

  Future<void> _updateStreamingOptions() async {
    setState(() {
      _isUpdating = true;
      _statusMessage = 'Updating streaming options...';
    });

    try {
      await StreamingOptionsUpdater.updateStreamingOptionsForMovies();
      setState(() {
        _statusMessage = 'Streaming options updated successfully!';
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Error updating streaming options: $e';
      });
    } finally {
      setState(() {
        _isUpdating = false;
      });
    }
  }

  Future<void> _testStreamingFilter() async {
    setState(() {
      _isUpdating = true;
      _statusMessage = 'Testing streaming filter...';
    });

    try {
      // Get selected platforms
      final streamingCubit = context.read<StreamingPlatformsCubit>();
      final selectedPlatforms = streamingCubit.selectedPlatformIds;
      
      // Test the repository with streaming filter
      final contentRepository = context.read<ContentRepository>();
      
      // Test popular movies with filter
      final popularMovies = await contentRepository.getPopularMovies(
        limit: 5,
        selectedPlatforms: selectedPlatforms,
      );
      
      // Test genre movies with filter
      final genreMovies = await contentRepository.getMoviesByGenre(
        'Action',
        limit: 5,
        selectedPlatforms: selectedPlatforms,
      );

      setState(() {
        _statusMessage = 'Filter test completed!\n'
            'Selected platforms: ${selectedPlatforms.join(", ")}\n'
            'Popular movies found: ${popularMovies.length}\n'
            'Action movies found: ${genreMovies.length}\n'
            'First popular movie: ${popularMovies.isNotEmpty ? popularMovies.first.title : "None"}\n'
            'First action movie: ${genreMovies.isNotEmpty ? genreMovies.first.title : "None"}';
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Error testing filter: $e';
      });
    } finally {
      setState(() {
        _isUpdating = false;
      });
    }
  }

  Future<void> _exportDatabase() async {
    try {
      print('1. Starting database export...');
      setState(() {
        _statusMessage = 'Exporting database...';
      });

      // Get the app's database path
      final dbPath = await _getDatabasePath();
      print('2. Live database path: $dbPath');
      final dbFile = File(dbPath);

      if (!await dbFile.exists()) {
        print('3. ERROR: Database file does not exist at path.');
        setState(() {
          _statusMessage = 'Database file not found!';
        });
        return;
      }
      print('3. Database file exists.');

      // Get the app's documents directory for export
      final directory = await getApplicationDocumentsDirectory();
      final exportPath = '${directory.path}/exported_big_movies.db';
      print('4. Export path set to: $exportPath');

      // Copy the database to the export location
      await dbFile.copy(exportPath);
      print('5. Database file copied successfully.');

      // Share the file using the native share dialog
      await Share.shareXFiles(
        [XFile(exportPath)],
        text: 'Mood AI - Enriched Database',
        subject: 'big_movies.db',
      );
      print('6. Share dialog initiated.');

      setState(() {
        _statusMessage = 'Database shared successfully!';
      });

    } catch (e) {
      print('EXPORT FAILED WITH ERROR: $e');
      setState(() {
        _statusMessage = 'Export failed: $e';
      });
      print('Export error: $e');
    } finally {
      setState(() {
        _isUpdating = false;
      });
    }
  }

  Future<String> _getDatabasePath() async {
    // This MUST match the path used in DatabaseService
    final directory = await getApplicationDocumentsDirectory();
    return '${directory.path}/big_movies.db';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Streaming Options Update'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Streaming Options Updater',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Text(
              _statusMessage,
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            if (_isUpdating)
              const CircularProgressIndicator()
            else
              Column(
                children: [
                  if (AppConfig.streamingFeatureEnabled)
                    ElevatedButton(
                      onPressed: _updateStreamingOptions,
                      child: const Text('Update Streaming Options'),
                    ),
                  if (AppConfig.streamingFeatureEnabled)
                    SizedBox(height: 10),
                  if (AppConfig.streamingFeatureEnabled)
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.tertiary,
                      ),
                      onPressed: () async {
                        setState(() {
                          _isUpdating = true;
                        });
                        // This method clears the cursor and starts from scratch
                        await StreamingOptionsUpdater.forceUpdateStreamingOptions();
                        setState(() {
                          _isUpdating = false;
                          _statusMessage = 'Forced resync initiated.';
                        });
                      },
                      child: const Text('Force Full Resync'),
                    ),
                  if (AppConfig.streamingFeatureEnabled)
                    const SizedBox(height: 10),
                  if (AppConfig.streamingFeatureEnabled)
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.secondary,
                      ),
                      onPressed: () {
                        print('Export Database button pressed.');
                        setState(() {
                          _isUpdating = true;
                        });
                        _exportDatabase();
                      },
                      child: const Text('Export Database'),
                    ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: _testStreamingFilter,
                    child: const Text('Test Streaming Filter'),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () async {
                      await StreamingOptionsUpdater.checkDatabaseState();
                    },
                    child: const Text('Check Database State'),
                  ),
                ],
              ),
            const SizedBox(height: 20),
            const Text(
              'This will:\n'
              '• Add streaming_options column to database\n'
              '• Create metadata table for tracking updates\n'
              '• Perform initial sync (first run) or incremental update\n'
              '• Match movies with streaming services\n'
              '• Update database with streaming information\n\n'
              'Initial sync: Fetches all movies (may take several minutes)\n'
              'Incremental update: Only fetches recent changes (much faster)',
              style: TextStyle(fontSize: 14),
              textAlign: TextAlign.left,
            ),
          ],
        ),
      ),
    );
  }
} 