import 'package:flutter/material.dart';
import 'package:mood_ai/src/models/movie.dart';

class ExpandedMovieCard extends StatelessWidget {
  const ExpandedMovieCard({
    required this.movie,
    required this.onCollapse,
    required this.onViewDetails,
    Key? key,
  }) : super(key: key);

  final Movie movie;
  final VoidCallback onCollapse;
  final VoidCallback onViewDetails;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: GestureDetector(
        onTap: onCollapse,
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 2,
                        child: movie.posterPath != null &&
                                movie.posterPath!.isNotEmpty
                            ? Image.network(
                                'https://image.tmdb.org/t/p/w500${movie.posterPath}',
                                fit: BoxFit.cover,
                                height: double.infinity,
                              )
                            : const Center(child: Icon(Icons.movie)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 3,
                        child: Padding(
                          padding: const EdgeInsets.only(top: 12.0, right: 12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                movie.title ?? 'Unknown Title',
                                style: Theme.of(context).textTheme.titleMedium,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 8),
                              Expanded(
                                child: SingleChildScrollView(
                                  child: Text(
                                    movie.overview ?? 'No overview available.',
                                    style:
                                        Theme.of(context).textTheme.bodySmall,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: (movie.genres ?? [])
                                .map((genre) => Padding(
                                      padding:
                                          const EdgeInsets.only(right: 4.0),
                                      child: Chip(
                                        label: Text(genre),
                                        materialTapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap,
                                        labelStyle:
                                            const TextStyle(fontSize: 10),
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 4),
                                      ),
                                    ))
                                .toList(),
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: onViewDetails,
                        child: const Text('View Details'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Positioned(
              top: 4,
              right: 4,
              child: Material(
                color: Colors.transparent,
                child: IconButton(
                  icon: const Icon(Icons.close),
                  iconSize: 20,
                  onPressed: onCollapse,
                  splashRadius: 18,
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 