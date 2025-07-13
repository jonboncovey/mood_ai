import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:mood_ai/src/models/models.dart';
import 'package:mood_ai/src/data/repositories/content_repository.dart';

part 'genre_state.dart';

class GenreCubit extends Cubit<GenreState> {
  GenreCubit({required this.contentRepository, required String genre})
      : super(GenreState(genre: genre));

  final ContentRepository contentRepository;

  Future<void> fetchMovies() async {
    if (state.hasReachedMax) return;

    emit(state.copyWith(status: GenreStatus.loading));

    try {
      final movies = await contentRepository.getMoviesByGenre(
        state.genre,
        page: state.page,
      );
      if (movies.isEmpty) {
        emit(state.copyWith(hasReachedMax: true, status: GenreStatus.success));
      } else {
        emit(
          state.copyWith(
            status: GenreStatus.success,
            movies: List.of(state.movies)..addAll(movies),
            page: state.page + 1,
          ),
        );
      }
    } catch (_) {
      emit(state.copyWith(status: GenreStatus.failure));
    }
  }
}
