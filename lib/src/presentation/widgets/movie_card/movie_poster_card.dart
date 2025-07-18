import 'package:flutter/material.dart';
import 'package:mood_ai/src/models/movie.dart';

class MoviePosterCard extends StatelessWidget {
  const MoviePosterCard({required this.movie, Key? key}) : super(key: key);
  final Movie movie;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: movie.posterPath != null && movie.posterPath!.isNotEmpty
          ? Image.network(
              'https://image.tmdb.org/t/p/w500${movie.posterPath}',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  const Center(child: Icon(Icons.movie)),
            )
          : const Center(child: Icon(Icons.movie)),
    );
  }
} 