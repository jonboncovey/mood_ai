import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:mood_ai/src/models/models.dart';
import 'package:mood_ai/src/data/repositories/content_repository.dart';
import 'package:mood_ai/src/logic/streaming_platforms/streaming_platforms_cubit.dart';

part 'genre_state.dart';

class GenreCubit extends Cubit<GenreState> {
  GenreCubit({
    required this.contentRepository, 
    required String genre,
    required this.streamingPlatformsCubit,
  }) : super(GenreState(genre: genre));

  final ContentRepository contentRepository;
  final StreamingPlatformsCubit streamingPlatformsCubit;

  Future<void> fetchMovies() async {
    if (state.hasReachedMax) return;

    emit(state.copyWith(status: GenreStatus.loading));

    try {
      // Get selected streaming platforms
      final selectedPlatforms = streamingPlatformsCubit.selectedPlatformIds;
      print('Fetching genre movies with streaming platforms: ${selectedPlatforms.join(", ")}');
      
      final movies = await contentRepository.getMoviesByGenre(
        state.genre,
        page: state.page,
        selectedPlatforms: selectedPlatforms,
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
