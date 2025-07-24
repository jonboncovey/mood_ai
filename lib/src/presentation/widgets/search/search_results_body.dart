import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:go_router/go_router.dart';
import 'package:mood_ai/src/logic/discovery/discovery_bloc.dart';
import 'package:mood_ai/src/logic/discovery/discovery_event.dart';
import 'package:mood_ai/src/logic/discovery/discovery_state.dart';
import 'package:mood_ai/src/models/movie.dart';
import 'package:mood_ai/src/presentation/widgets/movie_card/expanded_movie_card.dart';
import 'package:mood_ai/src/presentation/widgets/movie_card/movie_poster_card.dart';

class SearchResultsBody extends StatelessWidget {
  final DiscoveryState state;
  final double bottomPadding;

  const SearchResultsBody(
      {required this.state, required this.bottomPadding, Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    switch (state.searchStatus) {
      case SearchStatus.initial:
        return const SizedBox.shrink();
      case SearchStatus.loading:
        return const Center(child: CircularProgressIndicator());
      case SearchStatus.failure:
        return Center(
            child: Text(state.errorMessage ?? 'An error occurred.'));
      case SearchStatus.success:
        if (state.searchResults.isEmpty) {
          return const Center(child: Text('No results found.'));
        }

        final tiles = _buildTiles(context, state.searchResults, state.expandedMovieIndex);

        return Material(
          color: Theme.of(context).scaffoldBackgroundColor,
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              12,
              MediaQuery.of(context).padding.top + 12,
              12,
              bottomPadding + 12,
            ),
            child: StaggeredGrid.count(
              crossAxisCount: 2,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              children: tiles,
            ),
          ),
        );
    }
  }

  List<StaggeredGridTile> _buildTiles(
      BuildContext context, List<Movie> movies, int? expandedIndex) {
    final List<StaggeredGridTile> tiles = [];
    for (int i = 0; i < movies.length; i++) {
      final movie = movies[i];
      final isExpanded = expandedIndex == i;

      if (isExpanded) {
        // When a tile is expanded, it takes the full width.
        // We also check if the *next* tile was the one that was expanded,
        // and if so, we skip rendering the current tile to avoid an empty space.
        if (expandedIndex == i + 1 && i.isEven) {
          continue;
        }
        tiles.add(_buildExpandedTile(context, movie, i));
      } else {
        tiles.add(_buildCollapsedTile(context, movie, i));
      }
    }
    return tiles;
  }

  StaggeredGridTile _buildExpandedTile(
      BuildContext context, Movie movie, int index) {
    return StaggeredGridTile.count(
      crossAxisCellCount: 2,
      mainAxisCellCount: 1.5,
      child: ExpandedMovieCard(
        movie: movie,
        onCollapse: () =>
            context.read<DiscoveryBloc>().add(ToggleMovieExpanded(index)),
        onViewDetails: () => context.push('/details', extra: movie),
      ),
    );
  }

  StaggeredGridTile _buildCollapsedTile(
      BuildContext context, Movie movie, int index) {
    return StaggeredGridTile.count(
      crossAxisCellCount: 1,
      mainAxisCellCount: 1.5,
      child: GestureDetector(
        onTap: () =>
            context.read<DiscoveryBloc>().add(ToggleMovieExpanded(index)),
        child: MoviePosterCard(movie: movie),
      ),
    );
  }
} 