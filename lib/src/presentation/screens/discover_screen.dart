import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:mood_ai/src/data/mood_data.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:mood_ai/src/data/repositories/content_repository.dart';
import 'package:mood_ai/src/logic/discovery/discovery_bloc.dart';
import 'package:mood_ai/src/logic/discovery/discovery_event.dart';
import 'package:mood_ai/src/logic/discovery/discovery_state.dart';
import 'package:mood_ai/src/logic/streaming_platforms/streaming_platforms_cubit.dart';
import 'package:mood_ai/src/models/mood_filter.dart';
import 'package:mood_ai/src/models/movie.dart';
import 'package:flutter/material.dart';
import 'package:mood_ai/src/presentation/widgets/movie_card/expanded_movie_card.dart';
import 'package:mood_ai/src/presentation/widgets/movie_card/movie_poster_card.dart';
import 'package:speech_to_text/speech_to_text.dart';

class DiscoverScreen extends StatefulWidget {
  final double bottomPadding;
  const DiscoverScreen({required this.bottomPadding, Key? key}) : super(key: key);

  @override
  _DiscoverScreenState createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen>
    with AutomaticKeepAliveClientMixin {
  MoodFilter? _selectedMood;
  List<Movie> _moodResults = [];
  bool _isLoading = false;
  String? _errorMessage;
  int? _expandedMovieIndex;

  @override
  void initState() {
    super.initState();
    _loadMoodPreviews();
  }

  Future<void> _loadMoodPreviews() async {
    setState(() => _isLoading = true);
    final repo = context.read<ContentRepository>();
    for (var mood in moodFilters) {
      final movies = await repo.getMoviesForMoodPreview(mood.query);
      if (mounted) {
        setState(() {
          mood.movies = movies;
        });
      }
    }
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  void _onMoodSelected(MoodFilter mood) async {
    setState(() {
      _selectedMood = mood;
      _isLoading = true;
      _errorMessage = null;
      _expandedMovieIndex = null;
    });

    try {
      final movies = await context
          .read<ContentRepository>()
          .getMoviesByMood(mood.query);
      setState(() {
        _moodResults = movies;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = "Failed to load movies for this mood.";
        _isLoading = false;
      });
    }
  }

  void _clearMoodSelection() {
    setState(() {
      _selectedMood = null;
      _moodResults = [];
      _expandedMovieIndex = null;
    });
  }

  void _toggleMovieExpanded(int index) {
    setState(() {
      if (_expandedMovieIndex == index) {
        _expandedMovieIndex = null;
      } else {
        _expandedMovieIndex = index;
      }
    });
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context); // Important for AutomaticKeepAliveClientMixin
    return Scaffold(
      appBar: AppBar(
        title: Text(_selectedMood?.name ?? 'Discover Moods'),
        leading: _selectedMood != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: _clearMoodSelection,
              )
            : null,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text(_errorMessage!),
        const SizedBox(height: 16),
        ElevatedButton(onPressed: _clearMoodSelection, child: const Text("Go Back"))
      ]));
    }

    if (_selectedMood == null) {
      return _buildMoodGrid();
    } else {
      return _buildResultsGrid();
    }
  }
// whatre you in thee mood for?
// swap content discover/home
  Widget _buildMoodGrid() {
    return GridView.builder(
      padding: EdgeInsets.fromLTRB(16, 16, 16, widget.bottomPadding + 16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1, // Changed for a square-like card
      ),
      itemCount: moodFilters.length,
      itemBuilder: (context, index) {
        final mood = moodFilters[index];
        return GestureDetector(
          onTap: () => _onMoodSelected(mood),
          child: Card(
            clipBehavior: Clip.antiAlias,
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  flex: 1,
                  child: mood.movies.length < 2
                      ? Container(
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                          child: const Center(child: Icon(Icons.movie, size: 40, color: Colors.white24)))
                      : Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              child: mood.movies[0].posterPath != null &&
                                      mood.movies[0].posterPath!.isNotEmpty
                                  ? Image.network(
                                      'https://image.tmdb.org/t/p/w200${mood.movies[0].posterPath}',
                                      fit: BoxFit.cover,
                                    )
                                  : Container(color: Colors.grey[800]),
                            ),
                            Expanded(
                              child: mood.movies[1].posterPath != null &&
                                      mood.movies[1].posterPath!.isNotEmpty
                                  ? Image.network(
                                      'https://image.tmdb.org/t/p/w200${mood.movies[1].posterPath}',
                                      fit: BoxFit.cover,
                                    )
                                  : Container(color: Colors.grey[800]),
                            ),
                          ],
                        ),
                ),
                Expanded(
                  flex: 1,
                  child: ClipRect(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            mood.name,
                            textAlign: TextAlign.center,
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            mood.description,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 11),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildResultsGrid() {
    if (_moodResults.isEmpty) {
      return const Center(child: Text("No movies found for this mood."));
    }

    final List<StaggeredGridTile> tiles = [];
    for (int i = 0; i < _moodResults.length; i += 2) {
      final int leftIndex = i;
      final int rightIndex = i + 1;
      final bool hasRightItem = rightIndex < _moodResults.length;
      final Movie leftMovie = _moodResults[leftIndex];
      final Movie? rightMovie = hasRightItem ? _moodResults[rightIndex] : null;
      final bool leftIsExpanded = _expandedMovieIndex == leftIndex;
      final bool rightIsExpanded =
          hasRightItem && _expandedMovieIndex == rightIndex;

      if (leftIsExpanded) {
        tiles.add(_buildExpandedTile(leftMovie, leftIndex));
      } else if (rightIsExpanded) {
        tiles.add(_buildExpandedTile(rightMovie!, rightIndex));
      } else {
        tiles.add(_buildCollapsedTile(leftMovie, leftIndex));
        if (hasRightItem) {
          tiles.add(_buildCollapsedTile(rightMovie!, rightIndex));
        }
      }
    }

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(16, MediaQuery.of(context).padding.top + 16, 16, widget.bottomPadding + 16),
      child: StaggeredGrid.count(
        crossAxisCount: 2,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        children: tiles,
      ),
    );
  }

  StaggeredGridTile _buildExpandedTile(Movie movie, int index) {
    return StaggeredGridTile.count(
      crossAxisCellCount: 2,
      mainAxisCellCount: 1.5,
      child: ExpandedMovieCard(
        movie: movie,
        onCollapse: () => _toggleMovieExpanded(index),
        onViewDetails: () => context.push('/details', extra: movie),
      ),
    );
  }

  StaggeredGridTile _buildCollapsedTile(Movie movie, int index) {
    return StaggeredGridTile.count(
      crossAxisCellCount: 1,
      mainAxisCellCount: 1.5,
      child: GestureDetector(
        onTap: () => _toggleMovieExpanded(index),
        child: MoviePosterCard(movie: movie),
      ),
    );
  }
} 