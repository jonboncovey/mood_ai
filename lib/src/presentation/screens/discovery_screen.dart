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
import 'package:mood_ai/src/logic/streaming_platforms/streaming_platforms_cubit.dart';
import 'package:mood_ai/src/models/movie.dart';
import 'package:speech_to_text/speech_to_text.dart';

// Helper widget to report its size to a callback.
class _SizeReportingWidget extends StatefulWidget {
  final Widget child;
  final ValueChanged<Size> onSizeChanged;

  const _SizeReportingWidget({
    Key? key,
    required this.child,
    required this.onSizeChanged,
  }) : super(key: key);

  @override
  State<_SizeReportingWidget> createState() => _SizeReportingWidgetState();
}

class _SizeReportingWidgetState extends State<_SizeReportingWidget> {
  final _widgetKey = GlobalKey();
  Size? _lastReportedSize;

  @override
  void initState() {
    super.initState();
    _reportSize();
  }

  void _reportSize() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final size = _widgetKey.currentContext?.size;
      if (size != null && size != _lastReportedSize) {
        _lastReportedSize = size;
        widget.onSizeChanged(size);
      }
    });
  }

  @override
  void didUpdateWidget(covariant _SizeReportingWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    _reportSize();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      key: _widgetKey,
      child: widget.child,
    );
  }
}


class DiscoveryScreen extends StatelessWidget {
  const DiscoveryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => DiscoveryBloc(
        contentRepository: RepositoryProvider.of<ContentRepository>(context),
        speechToText: SpeechToText(),
        streamingPlatformsCubit: context.read<StreamingPlatformsCubit>(),
      )..add(FetchDiscoveryData()),
      child: const _DiscoveryView(),
    );
  }
}

class _DiscoveryView extends StatefulWidget {
  const _DiscoveryView();

  @override
  State<_DiscoveryView> createState() => _DiscoveryViewState();
}

class _DiscoveryViewState extends State<_DiscoveryView> {
  late final TextEditingController _searchController;
  double _searchBarHeight = 72.0; // Default height (56) + padding

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();

    _searchController.addListener(() {
      if (context.mounted) {
        final bloc = context.read<DiscoveryBloc>();
        if (_searchController.text != bloc.state.recognizedText) {
          bloc.add(SearchQueryChanged(_searchController.text));
        }
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
        if (_searchController.text != state.recognizedText) {
          _searchController.text = state.recognizedText;
          _searchController.selection = TextSelection.fromPosition(
            TextPosition(offset: _searchController.text.length),
          );
        }
      },
      builder: (context, state) {
        final isInSearchMode = state.searchStatus != SearchStatus.initial;

        return Stack(
          fit: StackFit.expand,
          children: [
            // Body
            if (isInSearchMode)
              _SearchResultsBody(
                state: state,
                topPadding: _searchBarHeight,
              )
            else
              const _DiscoveryBody(),

            // Voice Visualizer
            if (state.isListening) const _VoiceVisualizer(),

            // Search Bar
            AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              top: isInSearchMode ? 0 : null,
              left: 16,
              right: isInSearchMode ? 16 : (16 + 56 + 8),
              bottom: isInSearchMode ? null : 24,
              child: _SizeReportingWidget(
                onSizeChanged: (size) =>
                    setState(() => _searchBarHeight = size.height),
                child: _SearchBar(controller: _searchController),
              ),
            ),

            // Mic Button
            AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              bottom: 24,
              right: 16,
              child: const _MicButton(),
            ),
          ],
        );
      },
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({required this.controller});
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DiscoveryBloc, DiscoveryState>(
      buildWhen: (p, c) =>
          p.isListening != c.isListening || p.searchStatus != c.searchStatus,
      builder: (context, state) {
        final isListening = state.isListening;
        final isInSearchMode = state.searchStatus != SearchStatus.initial;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceVariant,
            borderRadius: BorderRadius.circular(28),
            boxShadow: kElevationToShadow[2],
          ),
          child: Row(
            children: [
              const Icon(Icons.search),
              const SizedBox(width: 16),
              Expanded(
                child: TextField(
                  controller: controller,
                  maxLines: null, // Allows the text field to grow
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText:
                        isListening ? 'Listening...' : "What's your mood?",
                    suffixIcon: isInSearchMode
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              controller.clear();
                              context.read<DiscoveryBloc>().add(ClearSearch());
                            },
                          )
                        : null,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _MicButton extends StatefulWidget {
  const _MicButton();
  @override
  State<_MicButton> createState() => _MicButtonState();
}

class _MicButtonState extends State<_MicButton> {
  bool _isButtonPressed = false;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DiscoveryBloc, DiscoveryState>(
      buildWhen: (p, c) => p.isListening != c.isListening,
      builder: (context, state) {
        final isListening = state.isListening;
        return GestureDetector(
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
  final double topPadding;

  const _SearchResultsBody({required this.state, required this.topPadding});

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
          // Add dynamic padding to avoid being obscured by the search bar
          padding: EdgeInsets.only(
            top: topPadding + MediaQuery.of(context).padding.top + 16,
            bottom: 24,
          ),
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
              subtitle: Text(movie.overview ?? '',
                  maxLines: 2, overflow: TextOverflow.ellipsis),
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
              child: Column(
                children: [
                  // Streaming platforms filter indicator
                  BlocBuilder<StreamingPlatformsCubit, StreamingPlatformsState>(
                    builder: (context, platformsState) {
                      if (platformsState.selectedPlatforms.isEmpty) {
                        return const SizedBox.shrink();
                      }
                      return Container(
                        margin: const EdgeInsets.all(8.0),
                        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.filter_list,
                              size: 16,
                              color: Theme.of(context).colorScheme.onPrimaryContainer,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Filtered by: ${platformsState.selectedPlatforms.map((p) => p.name).join(', ')}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context).colorScheme.onPrimaryContainer,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  Expanded(
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
                  ),
                ],
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
