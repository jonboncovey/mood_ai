import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mood_ai/src/data/repositories/content_repository.dart';
import 'package:mood_ai/src/models/movie.dart';
import 'package:rxdart/rxdart.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'discovery_event.dart';
import 'discovery_state.dart';

class DiscoveryBloc extends Bloc<DiscoveryEvent, DiscoveryState> {
  final ContentRepository _contentRepository;
  final SpeechToText _speechToText;

  static const List<String> _genresToFetch = [
    'Romance',
    'TV Movie',
    'Drama',
    'Comedy',
    'Fantasy',
  ];

  DiscoveryBloc({
    required ContentRepository contentRepository,
    required SpeechToText speechToText,
  })  : _contentRepository = contentRepository,
        _speechToText = speechToText,
        super(const DiscoveryState()) {
    on<FetchDiscoveryData>(_onFetchDiscoveryData);
    on<SearchQueryChanged>(
      _onSearchQueryChanged,
      transformer: (events, mapper) => events
          .debounceTime(const Duration(milliseconds: 300))
          .switchMap(mapper),
    );
    on<StartVoiceSearch>(_onStartVoiceSearch);
    on<StopVoiceSearch>(_onStopVoiceSearch);
    on<VoiceSearchResult>(_onVoiceSearchResult);
    on<VoiceSearchError>(_onVoiceSearchError);
    on<VoiceSoundLevelChanged>(_onVoiceSoundLevelChanged);
    on<UpdateRecognizedText>(_onUpdateRecognizedText);
    on<ClearSearch>(_onClearSearch);
  }

  void _onClearSearch(
    ClearSearch event,
    Emitter<DiscoveryState> emit,
  ) {
    emit(state.copyWith(
      searchStatus: SearchStatus.initial,
      searchResults: [],
      recognizedText: '',
    ));
  }

  Future<void> _onStartVoiceSearch(
    StartVoiceSearch event,
    Emitter<DiscoveryState> emit,
  ) async {
    bool available = await _speechToText.initialize(
      onError: (_) => add(VoiceSearchError()),
      onStatus: (status) {
        if (status == 'done' || status == 'notListening') {
          add(StopVoiceSearch());
        }
      },
    );

    if (available) {
      emit(state.copyWith(isListening: true, recognizedText: ''));
      _speechToText.listen(
        onResult: (result) {
          // ignore: avoid_print
          print('Recognized words: ${result.recognizedWords}');
          add(UpdateRecognizedText(result.recognizedWords, isFinal: result.finalResult));
        },
        onSoundLevelChange: (level) {
          add(VoiceSoundLevelChanged(level));
        },
      );
    } else {
      add(VoiceSearchError());
    }
  }

  void _onUpdateRecognizedText(
    UpdateRecognizedText event,
    Emitter<DiscoveryState> emit,
  ) {
    emit(state.copyWith(recognizedText: event.text));
    if (event.isFinal) {
      add(SearchQueryChanged(event.text));
    }
  }

  Future<void> _onStopVoiceSearch(
    StopVoiceSearch event,
    Emitter<DiscoveryState> emit,
  ) async {
    await _speechToText.stop();
    emit(state.copyWith(isListening: false));
  }

  void _onVoiceSearchResult(
    VoiceSearchResult event,
    Emitter<DiscoveryState> emit,
  ) {
    // Dispatch a text search event with the final recognized words
    add(SearchQueryChanged(event.recognizedText));
  }

  void _onVoiceSearchError(VoiceSearchError event, Emitter<DiscoveryState> emit) {
    emit(state.copyWith(
      isListening: false,
      errorMessage: 'Voice recognition failed. Please try again.',
    ));
  }

  void _onVoiceSoundLevelChanged(
    VoiceSoundLevelChanged event,
    Emitter<DiscoveryState> emit,
  ) {
    emit(state.copyWith(soundLevel: event.level));
  }

  Future<void> _onFetchDiscoveryData(
    FetchDiscoveryData event,
    Emitter<DiscoveryState> emit,
  ) async {
    emit(state.copyWith(fetchStatus: FetchStatus.loading));
    try {
      // First, get a general list of popular movies to ensure we have some content.
      final popularMovies =
          await _contentRepository.getPopularMovies(limit: 10);
      final Map<String, List<Movie>> moviesByGenre = {};

      if (popularMovies.isNotEmpty) {
        moviesByGenre['Popular'] = popularMovies;
      }

      for (String genre in _genresToFetch) {
        final movies =
            await _contentRepository.getMoviesByGenre(genre, limit: 10);
        if (movies.isNotEmpty) {
          moviesByGenre[genre] = movies;
        }
      }

      emit(state.copyWith(
        fetchStatus: FetchStatus.success,
        moviesByGenre: moviesByGenre,
      ));
    } catch (e) {
      emit(state.copyWith(
        fetchStatus: FetchStatus.failure,
        errorMessage: 'Failed to fetch content: ${e.toString()}',
      ));
    }
  }

  Future<void> _onSearchQueryChanged(
    SearchQueryChanged event,
    Emitter<DiscoveryState> emit,
  ) async {
    if (event.query.isEmpty) {
      emit(state
          .copyWith(searchStatus: SearchStatus.initial, searchResults: []));
      return;
    }

    emit(state.copyWith(searchStatus: SearchStatus.loading));
    try {
      final results = await _contentRepository.searchMoviesByTitle(event.query);
      emit(state.copyWith(
        searchStatus: SearchStatus.success,
        searchResults: results,
      ));
    } catch (e) {
      emit(state.copyWith(
        searchStatus: SearchStatus.failure,
        errorMessage: 'Failed to fetch search results: ${e.toString()}',
      ));
    }
  }
}
