import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mood_ai/src/data/repositories/content_repository.dart';
import 'package:mood_ai/src/logic/genre/genre_cubit.dart';
import 'package:mood_ai/src/logic/streaming_platforms/streaming_platforms_cubit.dart';
import 'package:mood_ai/src/models/models.dart';

class GenreScreen extends StatelessWidget {
  final String genre;

  const GenreScreen({super.key, required this.genre});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => GenreCubit(
        contentRepository: context.read<ContentRepository>(),
        genre: genre,
        streamingPlatformsCubit: context.read<StreamingPlatformsCubit>(),
      )..fetchMovies(),
      child: GenreView(genre: genre),
    );
  }
}

class GenreView extends StatefulWidget {
  const GenreView({super.key, required this.genre});
  final String genre;

  @override
  State<GenreView> createState() => _GenreViewState();
}

class _GenreViewState extends State<GenreView> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.genre),
      ),
      body: BlocBuilder<GenreCubit, GenreState>(
        builder: (context, state) {
          switch (state.status) {
            case GenreStatus.failure:
              return const Center(child: Text('Failed to fetch movies.'));
            case GenreStatus.success:
              if (state.movies.isEmpty) {
                return const Center(child: Text('No movies found.'));
              }
              return ListView.builder(
                itemBuilder: (BuildContext context, int index) {
                  return index >= state.movies.length
                      ? const BottomLoader()
                      : MovieListItem(movie: state.movies[index]);
                },
                itemCount: state.hasReachedMax
                    ? state.movies.length
                    : state.movies.length + 1,
                controller: _scrollController,
              );
            case GenreStatus.loading:
              if (state.movies.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }
              return ListView.builder(
                itemBuilder: (BuildContext context, int index) {
                  return index >= state.movies.length
                      ? const BottomLoader()
                      : MovieListItem(movie: state.movies[index]);
                },
                itemCount: state.hasReachedMax
                    ? state.movies.length
                    : state.movies.length + 1,
                controller: _scrollController,
              );
            default:
              return const Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_isBottom) context.read<GenreCubit>().fetchMovies();
  }

  bool get _isBottom {
    if (!_scrollController.hasClients) return false;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    return currentScroll >= (maxScroll * 0.9);
  }
}

class BottomLoader extends StatelessWidget {
  const BottomLoader({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: SizedBox(
        height: 24,
        width: 24,
        child: CircularProgressIndicator(strokeWidth: 1.5),
      ),
    );
  }
}

class MovieListItem extends StatelessWidget {
  const MovieListItem({super.key, required this.movie});

  final Movie movie;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: movie.posterPath != null
          ? Image.network(
              'https://image.tmdb.org/t/p/w92${movie.posterPath}',
              width: 50,
              fit: BoxFit.cover,
            )
          : const SizedBox(width: 50, child: Icon(Icons.movie)),
      title: Text(movie.title ?? 'No title'),
      subtitle: Text(movie.overview ?? '',
          maxLines: 2, overflow: TextOverflow.ellipsis),
      isThreeLine: true,
    );
  }
}
