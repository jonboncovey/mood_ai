import 'package:equatable/equatable.dart';
import 'package:mood_ai/src/models/movie.dart';

enum FetchStatus { initial, loading, success, failure }

enum SearchStatus { initial, loading, success, failure }

class DiscoveryState extends Equatable {
  const DiscoveryState({
    this.fetchStatus = FetchStatus.initial,
    this.searchStatus = SearchStatus.initial,
    this.moviesByGenre = const {},
    this.searchResults = const [],
    this.errorMessage,
    this.isListening = false,
    this.recognizedText = '',
    this.soundLevel = 0.0,
  });

  final FetchStatus fetchStatus;
  final SearchStatus searchStatus;
  final Map<String, List<Movie>> moviesByGenre;
  final List<Movie> searchResults;
  final String? errorMessage;
  final bool isListening;
  final String recognizedText;
  final double soundLevel;

  DiscoveryState copyWith({
    FetchStatus? fetchStatus,
    SearchStatus? searchStatus,
    Map<String, List<Movie>>? moviesByGenre,
    List<Movie>? searchResults,
    String? errorMessage,
    bool? isListening,
    String? recognizedText,
    double? soundLevel,
  }) {
    return DiscoveryState(
      fetchStatus: fetchStatus ?? this.fetchStatus,
      searchStatus: searchStatus ?? this.searchStatus,
      moviesByGenre: moviesByGenre ?? this.moviesByGenre,
      searchResults: searchResults ?? this.searchResults,
      errorMessage: errorMessage ?? this.errorMessage,
      isListening: isListening ?? this.isListening,
      recognizedText: recognizedText ?? this.recognizedText,
      soundLevel: soundLevel ?? this.soundLevel,
    );
  }

  @override
  List<Object?> get props => [
        fetchStatus,
        searchStatus,
        moviesByGenre,
        searchResults,
        errorMessage,
        isListening,
        recognizedText,
        soundLevel,
      ];
}
