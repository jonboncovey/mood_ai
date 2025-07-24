import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:go_router/go_router.dart';
import 'package:mood_ai/src/data/repositories/content_repository.dart';
import 'package:mood_ai/src/logic/discovery/discovery_bloc.dart';
import 'package:mood_ai/src/logic/discovery/discovery_event.dart';
import 'package:mood_ai/src/logic/discovery/discovery_state.dart';
import 'package:mood_ai/src/logic/streaming_platforms/streaming_platforms_cubit.dart';
import 'package:mood_ai/src/models/movie.dart';

class HomeScreen extends StatelessWidget {
  final double bottomPadding;
  const HomeScreen({required this.bottomPadding, super.key});

  @override
  Widget build(BuildContext context) {
    return _HomeBody(bottomPadding: bottomPadding);
  }
}

class _HomeBody extends StatelessWidget {
  final double bottomPadding;
  const _HomeBody({required this.bottomPadding});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DiscoveryBloc, DiscoveryState>(
      buildWhen: (previous, current) =>
          previous.fetchStatus != current.fetchStatus ||
          previous.moviesByGenre != current.moviesByGenre,
      builder: (context, state) {
        switch (state.fetchStatus) {
          case FetchStatus.initial:
          case FetchStatus.loading:
            return const Center(child: CircularProgressIndicator());
          case FetchStatus.failure:
            return Center(
                child: Text(state.errorMessage ?? 'An error occurred.'));
          case FetchStatus.success:
            final genres = state.moviesByGenre.keys.toList();
            return RefreshIndicator(
              onRefresh: () async {
                context
                    .read<DiscoveryBloc>()
                    .add(const FetchDiscoveryData(forceRefresh: true));
              },
              child: ListView.builder(
                padding: EdgeInsets.only(
                    top: MediaQuery.of(context).padding.top + 16,
                    bottom: bottomPadding + 16),
                itemCount: genres.length,
                itemBuilder: (context, index) {
                  final genre = genres[index];
                  final movies = state.moviesByGenre[genre]!;
                  if (index == 1) {
                    return _GenreGrid(genre: genre, movies: movies);
                  }
                  return _GenreCarousel(genre: genre, movies: movies);
                },
              ),
            );
        }
      },
    );
  }
}

class _GenreCarousel extends StatelessWidget {
  const _GenreCarousel({required this.genre, required this.movies});

  final String genre;
  final List<Movie> movies;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  genre,
                  style: Theme.of(context).textTheme.headlineSmall,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              TextButton(
                onPressed: () => context.push('/genre/$genre'),
                child: const Text('See More'),
              )
            ],
          ),
        ),
        SizedBox(
          height: 200,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: movies.length,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemBuilder: (context, index) {
              final movie = movies[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: GestureDetector(
                  onTap: () {
                    context.push('/details', extra: movie);
                  },
                  child: AspectRatio(
                    aspectRatio: 2 / 3,
                    child: Card(
                      clipBehavior: Clip.antiAlias,
                      child: movie.posterPath != null &&
                              movie.posterPath!.isNotEmpty
                          ? Image.network(
                              'https://image.tmdb.org/t/p/w500${movie.posterPath}',
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Center(child: Icon(Icons.movie)),
                            )
                          : const Center(child: Icon(Icons.movie)),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _GenreGrid extends StatelessWidget {
  const _GenreGrid({required this.genre, required this.movies});

  final String genre;
  final List<Movie> movies;

  @override
  Widget build(BuildContext context) {
    // Limit the number of movies to display in the grid
    final gridMovies = movies.length > 6 ? movies.sublist(0, 6) : movies;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  genre,
                  style: Theme.of(context).textTheme.headlineSmall,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              TextButton(
                onPressed: () => context.push('/genre/$genre'),
                child: const Text('See More'),
              ),
            ],
          ),
        ),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: gridMovies.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: 2 / 3,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemBuilder: (context, index) {
            final movie = gridMovies[index];
            return GestureDetector(
              onTap: () {
                context.push('/details', extra: movie);
              },
              child: Card(
                clipBehavior: Clip.antiAlias,
                child: movie.posterPath != null && movie.posterPath!.isNotEmpty
                    ? Image.network(
                        'https://image.tmdb.org/t/p/w500${movie.posterPath}',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const Center(child: Icon(Icons.movie)),
                      )
                    : const Center(child: Icon(Icons.movie)),
              ),
            );
          },
        ),
      ],
    );
  }
}
