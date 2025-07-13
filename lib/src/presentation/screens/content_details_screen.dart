import 'package:flutter/material.dart';
import 'package:mood_ai/src/models/movie.dart';

class ContentDetailsScreen extends StatelessWidget {
  final Movie movie;

  const ContentDetailsScreen({super.key, required this.movie});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 250.0,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                movie.title ?? 'Details',
                style: const TextStyle(
                  shadows: [Shadow(blurRadius: 8, color: Colors.black)],
                ),
              ),
              background: movie.backdropPath != null
                  ? Image.network(
                      movie.fullBackdropUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          const Center(child: Icon(Icons.movie)),
                    )
                  : Container(color: Colors.grey),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (movie.posterPath != null)
                        SizedBox(
                          width: 100,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8.0),
                            child: Image.network(
                              movie.fullPosterUrl,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Text(
                              movie.title ?? 'No Title',
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                            if (movie.tagline != null &&
                                movie.tagline!.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 4.0),
                                child: Text(
                                  movie.tagline!,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(fontStyle: FontStyle.italic),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  _buildInfoRow(context),
                  const Divider(),
                  const SizedBox(height: 16),
                  Text('Overview',
                      style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  Text(movie.overview ?? 'No overview available.',
                      style: Theme.of(context).textTheme.bodyMedium),
                  const SizedBox(height: 16),
                  if (movie.genres.isNotEmpty) ...[
                    Text('Genres',
                        style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8.0,
                      runSpacing: 4.0,
                      children: movie.genres
                          .map((genre) => Chip(label: Text(genre)))
                          .toList(),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          if (movie.releaseDate != null && movie.releaseDate!.isNotEmpty)
            _buildInfoItem(
              context,
              Icons.calendar_today,
              movie.releaseDate!.split('-').first, // Just the year
            ),
          if (movie.voteAverage != null && movie.voteAverage! > 0)
            _buildInfoItem(
              context,
              Icons.star,
              '${movie.voteAverage!.toStringAsFixed(1)} / 10',
            ),
          if (movie.runtime != null && movie.runtime! > 0)
            _buildInfoItem(
              context,
              Icons.timer,
              '${movie.runtime} min',
            ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(BuildContext context, IconData icon, String text) {
    return Column(
      children: [
        Icon(icon, size: 28),
        const SizedBox(height: 4),
        Text(text, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
