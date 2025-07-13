import 'dart:math';

import 'package:audio_flux/audio_flux.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_recorder/flutter_recorder.dart' as recorder;
import 'package:go_router/go_router.dart';
import 'package:mood_ai/src/data/repositories/content_repository.dart';
import 'package:mood_ai/src/logic/discovery/discovery_bloc.dart';
import 'package:mood_ai/src/logic/discovery/discovery_event.dart';
import 'package:mood_ai/src/logic/discovery/discovery_state.dart';
import 'package:mood_ai/src/models/movie.dart';
import 'package:speech_to_text/speech_to_text.dart';

class DiscoveryScreen extends StatelessWidget {
  const DiscoveryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => DiscoveryBloc(
        contentRepository: RepositoryProvider.of<ContentRepository>(context),
        speechToText: SpeechToText(),
      )..add(FetchDiscoveryData()),
      child: const _DiscoveryView(),
    );
  }
}

class _DiscoveryView extends StatelessWidget {
  const _DiscoveryView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          BlocBuilder<DiscoveryBloc, DiscoveryState>(
            builder: (context, state) {
              if (state.searchStatus != SearchStatus.initial || state.searchResults.isNotEmpty) {
                return _SearchResultsBody(state: state);
              } else {
                return const _DiscoveryBody();
              }
            },
          ),
          BlocBuilder<DiscoveryBloc, DiscoveryState>(
            buildWhen: (p, c) => p.isListening != c.isListening,
            builder: (context, state) {
              if (!state.isListening) return const SizedBox.shrink();
              return const _VoiceVisualizer();
            },
          ),
          BlocBuilder<DiscoveryBloc, DiscoveryState>(
            builder: (context, state) {
              final isInSearchMode = state.searchStatus != SearchStatus.initial;
              return AnimatedPositioned(
                duration: const Duration(milliseconds: 300),
                left: 16,
                right: 16,
                bottom: isInSearchMode ? null : 24.0,
                top: isInSearchMode ? 24.0 : null,
                child: const _SearchWidget(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _SearchWidget extends StatefulWidget {
  const _SearchWidget();

  @override
  State<_SearchWidget> createState() => _SearchWidgetState();
}

class _SearchWidgetState extends State<_SearchWidget> {
  late final TextEditingController _searchController;
  bool _isButtonPressed = false;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();

    _searchController.addListener(() {
      final bloc = context.read<DiscoveryBloc>();
      if (_searchController.text != bloc.state.recognizedText) {
        bloc.add(SearchQueryChanged(_searchController.text));
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<DiscoveryBloc, DiscoveryState>(
      listenWhen: (p, c) => p.recognizedText != c.recognizedText,
      listener: (context, state) {
        _searchController.text = state.recognizedText;
        _searchController.selection = TextSelection.fromPosition(
          TextPosition(offset: _searchController.text.length),
        );
      },
      buildWhen: (p, c) =>
          p.isListening != c.isListening || p.recognizedText != c.recognizedText || p.searchStatus != c.searchStatus,
      builder: (context, state) {
        final isListening = state.isListening;
        final isInSearchMode = state.searchStatus != SearchStatus.initial;
        return Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.search),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        minLines: 1,
                        maxLines: 3,
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText:
                              isListening ? 'Listening...' : "What's your mood?",
                          suffixIcon: isInSearchMode
                              ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    _searchController.clear();
                                    context.read<DiscoveryBloc>().add(ClearSearch());
                                  },
                                )
                              : null,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onLongPressStart: (_) {
                setState(() => _isButtonPressed = true);
                context.read<DiscoveryBloc>().add(StartVoiceSearch());
              },
              onLongPressEnd: (_) {
                setState(() => _isButtonPressed = false);
                context.read<DiscoveryBloc>().add(StopVoiceSearch());
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isListening
                      ? Colors.red.withOpacity(0.7)
                      : Theme.of(context).colorScheme.primary,
                  boxShadow: [
                    if (_isButtonPressed || isListening)
                      BoxShadow(
                        color: Colors.white.withOpacity(0.4),
                        blurRadius: 10,
                        spreadRadius: 2,
                      )
                  ],
                ),
                child: Icon(
                  isListening ? Icons.mic : Icons.mic_none,
                  color: Colors.white,
                  size: 32,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _VoiceVisualizer extends StatelessWidget {
  const _VoiceVisualizer();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          BlocBuilder<DiscoveryBloc, DiscoveryState>(
            buildWhen: (p, c) => p.soundLevel != c.soundLevel,
            builder: (context, state) {
              return CustomPaint(
                size: const Size.square(200),
                painter: _VisualizerPainter(
                  soundLevel: state.soundLevel,
                  color: Theme.of(context).colorScheme.primary,
                ),
              );
            },
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

class _VisualizerPainter extends CustomPainter {
  final double soundLevel;
  final Color color;
  final Paint _paint;
  final int dotCount = 20;
  final double minDotRadius = 5.0;
  final double maxDotRadius = 15.0;

  _VisualizerPainter({required this.soundLevel, required this.color})
      : _paint = Paint()..color = color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width / 2.5;
    final angleStep = (2 * pi) / dotCount;
    final color2 = Color.lerp(color, Colors.white, 0.4)!;

    final normalizedSound = (soundLevel * 5).clamp(0.0, 1.0);
    final currentRadius = maxRadius * normalizedSound;

    for (int i = 0; i < dotCount; i++) {
      final angle = i * angleStep;
      final dotRadius =
          minDotRadius + (maxDotRadius - minDotRadius) * normalizedSound;

      final waveFactor = sin(angle * 4 + DateTime.now().millisecondsSinceEpoch * 0.005);
      final animatedRadius = dotRadius + waveFactor * 4;
      
      _paint.color = (i.isEven ? color : color2)
          .withOpacity((normalizedSound * 0.7 + 0.3).clamp(0.3, 1.0));

      final x = center.dx + currentRadius * cos(angle);
      final y = center.dy + currentRadius * sin(angle);

      canvas.drawCircle(Offset(x, y),
          animatedRadius.clamp(minDotRadius, maxDotRadius), _paint);
    }
  }

  @override
  bool shouldRepaint(covariant _VisualizerPainter oldDelegate) {
    return true;
  }
}

class _SearchResultsBody extends StatelessWidget {
  final DiscoveryState state;

  const _SearchResultsBody({required this.state});

  @override
  Widget build(BuildContext context) {
    switch (state.searchStatus) {
      case SearchStatus.initial:
      case SearchStatus.loading:
        return const Center(child: CircularProgressIndicator());
      case SearchStatus.failure:
        return Center(
            child: Text(state.errorMessage ?? 'An error occurred.'));
      case SearchStatus.success:
        if (state.searchResults.isEmpty) {
          return const Center(child: Text('No results found.'));
        }
        return ListView.builder(
          padding: const EdgeInsets.only(top: 80, bottom: 24),
          itemCount: state.searchResults.length,
          itemBuilder: (context, index) {
            final movie = state.searchResults[index];
            return ListTile(
              leading: movie.posterPath != null && movie.posterPath!.isNotEmpty
                  ? Image.network(
                      'https://image.tmdb.org/t/p/w200${movie.posterPath}',
                      width: 50,
                      fit: BoxFit.cover,
                    )
                  : const Icon(Icons.movie, size: 50),
              title: Text(movie.title ?? 'Unknown Title'),
              subtitle: Text(movie.overview ?? '', maxLines: 2, overflow: TextOverflow.ellipsis),
              onTap: () => context.push('/details', extra: movie),
            );
          },
        );
    }
  }
}

class _DiscoveryBody extends StatelessWidget {
  const _DiscoveryBody();

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
                context.read<DiscoveryBloc>().add(FetchDiscoveryData());
              },
              child: ListView.builder(
                // Added padding to ensure the last list item isn't hidden by the search bar.
                padding: const EdgeInsets.only(bottom: 100),
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
