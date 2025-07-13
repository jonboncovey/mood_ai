import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseService {
  // Singleton pattern
  DatabaseService._privateConstructor();
  static final DatabaseService instance = DatabaseService._privateConstructor();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    // Get the directory path for both Android and iOS to store database.
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, 'movies_100k.db');

    // Check if the database exists.
    bool dbExists = await databaseExists(path);

    if (!dbExists) {
      // If not, copy from asset.
      try {
        ByteData data = await rootBundle.load(join('assets', 'movies_100k.db'));
        List<int> bytes =
            data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
        await File(path).writeAsBytes(bytes, flush: true);
      } catch (e) {
        // ignore: avoid_print
        print('Error copying database: $e');
      }
    }

    // Open the database.
    return await openDatabase(path, readOnly: true);
  }
}
