part of 'genre_cubit.dart';

enum GenreStatus { initial, loading, success, failure }

class GenreState extends Equatable {
  const GenreState({
    this.status = GenreStatus.initial,
    this.movies = const <Movie>[],
    this.genre = '',
    this.page = 1,
    this.hasReachedMax = false,
  });

  final GenreStatus status;
  final List<Movie> movies;
  final String genre;
  final int page;
  final bool hasReachedMax;

  GenreState copyWith({
    GenreStatus? status,
    List<Movie>? movies,
    String? genre,
    int? page,
    bool? hasReachedMax,
  }) {
    return GenreState(
      status: status ?? this.status,
      movies: movies ?? this.movies,
      genre: genre ?? this.genre,
      page: page ?? this.page,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
    );
  }

  @override
  List<Object> get props => [status, movies, genre, page, hasReachedMax];
}
