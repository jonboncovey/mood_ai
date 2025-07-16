import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mood_ai/src/data/repositories/content_repository.dart';
import 'package:mood_ai/src/models/movie.dart';
import 'package:mood_ai/src/logic/streaming_platforms/streaming_platforms_cubit.dart';
import 'package:rxdart/rxdart.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'discovery_event.dart';
import 'discovery_state.dart';
import '../../config/app_config.dart';

class DiscoveryBloc extends Bloc<DiscoveryEvent, DiscoveryState> {
  final ContentRepository _contentRepository;
  final SpeechToText _speechToText;
  final StreamingPlatformsCubit _streamingPlatformsCubit;
  List<String> _selectedStreamingServices = [];

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
    required StreamingPlatformsCubit streamingPlatformsCubit,
  })  : _contentRepository = contentRepository,
        _speechToText = speechToText,
        _streamingPlatformsCubit = streamingPlatformsCubit,
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

    // Listen for streaming platform changes and refetch data
    _streamingPlatformsCubit.stream.listen((_) {
      add(FetchDiscoveryData());
    });
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
      final Map<String, List<Movie>> moviesByGenre = {};

      // Get selected streaming platforms, but only if the feature is enabled
      final selectedPlatforms = AppConfig.streamingFeatureEnabled
          ? _streamingPlatformsCubit.selectedPlatformIds
          : <String>[];
          
      print(
          'Fetching discovery data with streaming platforms: ${selectedPlatforms.join(", ")}');

      // A map of section titles to futures that fetch the movies for that section.
      final Map<String, Future<List<Movie>>> sectionsToFetch = {
        'Popular': _contentRepository.getPopularMovies(limit: 10, selectedPlatforms: selectedPlatforms),
        'Critically Acclaimed': _contentRepository.getCriticallyAcclaimed(limit: 10, selectedPlatforms: selectedPlatforms),
        'Hidden Gems': _contentRepository.getHiddenGems(limit: 10, selectedPlatforms: selectedPlatforms),
        'Indie Darlings': _contentRepository.getIndieDarlings(limit: 10, selectedPlatforms: selectedPlatforms),
        'Romance': _contentRepository.getMoviesByGenre('Romance', limit: 10, selectedPlatforms: selectedPlatforms),
        'Comedy': _contentRepository.getMoviesByGenre('Comedy', limit: 10, selectedPlatforms: selectedPlatforms),
      };

      // Fetch all sections in parallel.
      final results = await Future.wait(sectionsToFetch.values);

      // Assign the fetched movies to their sections.
      final keys = sectionsToFetch.keys.toList();
      for (int i = 0; i < keys.length; i++) {
        if (results[i].isNotEmpty) {
          moviesByGenre[keys[i]] = results[i];
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
      // Get selected streaming platforms for search, if feature is enabled
      final selectedPlatforms = AppConfig.streamingFeatureEnabled
          ? _streamingPlatformsCubit.selectedPlatformIds
          : <String>[];
      print('Searching with streaming platforms: ${selectedPlatforms.join(", ")}');
      
      final results = await _contentRepository.searchMoviesByTitle(
        event.query,
        selectedPlatforms: selectedPlatforms,
      );
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
