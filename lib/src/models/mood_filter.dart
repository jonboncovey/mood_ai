import 'package:mood_ai/src/models/movie.dart';

class MoodFilter {
  final String name;
  final String description;
  final String query;
  List<Movie> movies;

  MoodFilter({
    required this.name,
    required this.description,
    required this.query,
    this.movies = const [],
  });
} 