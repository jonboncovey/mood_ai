import 'package:flutter/services.dart' show rootBundle;
import 'package:csv/csv.dart';

class StreamingCache {
  static final StreamingCache _instance = StreamingCache._internal();
  factory StreamingCache() => _instance;
  StreamingCache._internal();

  List<List<dynamic>>? _data;

  Future<void> load() async {
    if (_data != null) return;
    final rawData = await rootBundle.loadString('assets/netflix_movies_from_kaggle.csv');
    _data = const CsvToListConverter().convert(rawData);
  }

  bool isAvailableOnNetflix(String title, int year) {
    if (_data == null) return false;

    // Find movie by title and year
    for (final row in _data!) {
      // Assuming format: Title,Year,Netflix
      if (row.length >= 3 &&
          row[0].toString().toLowerCase() == title.toLowerCase() &&
          row[1] == year) {
        return row[2] == 1; // Check if Netflix column is 1
      }
    }

    return false;
  }
} 