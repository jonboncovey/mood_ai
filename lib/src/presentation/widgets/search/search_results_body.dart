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
  final double topPadding;

  const SearchResultsBody(
      {required this.state, required this.topPadding, Key? key})
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
        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            12,
            topPadding + MediaQuery.of(context).padding.top + 12,
            12,
            92, // For mic button and safe area
          ),
          child: StaggeredGrid.count(
            crossAxisCount: 2,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            children: List.generate(state.searchResults.length, (index) {
              final movie = state.searchResults[index];
              final isExpanded = state.expandedMovieIndex == index;

              final child = isExpanded
                  ? ExpandedMovieCard(
                      movie: movie,
                      onCollapse: () => context
                          .read<DiscoveryBloc>()
                          .add(ToggleMovieExpanded(index)),
                      onViewDetails: () => context.push('/details', extra: movie),
                    )
                  : GestureDetector(
                      onTap: () => context
                          .read<DiscoveryBloc>()
                          .add(ToggleMovieExpanded(index)),
                      child: MoviePosterCard(movie: movie),
                    );

              return StaggeredGridTile.count(
                crossAxisCellCount: isExpanded ? 2 : 1,
                mainAxisCellCount: isExpanded ? 2 : 1.5,
                child: child,
              );
            }),
          ),
        );
    }
  }
} 