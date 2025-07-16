import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:equatable/equatable.dart';

part 'streaming_platforms_state.dart';

class StreamingPlatformsCubit extends Cubit<StreamingPlatformsState> {
  StreamingPlatformsCubit() : super(const StreamingPlatformsState());

  // All available streaming platforms (using correct API service names)
  static const List<StreamingPlatform> _allPlatforms = [
    StreamingPlatform(id: 'netflix', name: 'Netflix', icon: '🎬'),
    StreamingPlatform(id: 'hulu', name: 'Hulu', icon: '🟢'),
    StreamingPlatform(id: 'prime', name: 'Amazon Prime Video', icon: '📦'),
    StreamingPlatform(id: 'disney', name: 'Disney+', icon: '🏰'),
    StreamingPlatform(id: 'max', name: 'Max', icon: '🎭'),
    StreamingPlatform(id: 'apple', name: 'Apple TV+', icon: '🍎'),
    StreamingPlatform(id: 'paramount', name: 'Paramount+', icon: '⭐'),
    StreamingPlatform(id: 'peacock', name: 'Peacock', icon: '🦚'),
    StreamingPlatform(id: 'starz', name: 'Starz', icon: '⭐'),
    StreamingPlatform(id: 'showtime', name: 'Showtime', icon: '🎪'),
    StreamingPlatform(id: 'crunchyroll', name: 'Crunchyroll', icon: '🍥'),
    StreamingPlatform(id: 'tubi', name: 'Tubi', icon: '📺'),
    StreamingPlatform(id: 'pluto', name: 'Pluto TV', icon: '🪐'),
    StreamingPlatform(id: 'youtube', name: 'YouTube Movies', icon: '📹'),
    StreamingPlatform(id: 'vudu', name: 'Vudu', icon: '🎬'),
    StreamingPlatform(id: 'google_play', name: 'Google Play', icon: '🎮'),
    StreamingPlatform(id: 'itunes', name: 'iTunes', icon: '🎵'),
  ];

  Future<void> loadPlatforms() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final selectedIds = prefs.getStringList('selected_platforms') ?? [];
      
      // If no platforms are selected, default to Netflix only (optimized for free API tier)
      if (selectedIds.isEmpty) {
        selectedIds.addAll(['netflix']);
        await prefs.setStringList('selected_platforms', selectedIds);
      }
      
      final selectedPlatforms = _allPlatforms
          .where((platform) => selectedIds.contains(platform.id))
          .toList();
      
      emit(state.copyWith(
        allPlatforms: _allPlatforms,
        selectedPlatforms: selectedPlatforms,
        isLoading: false,
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        error: 'Failed to load platforms: $e',
      ));
    }
  }

  Future<void> togglePlatform(StreamingPlatform platform) async {
    try {
      final currentSelected = List<StreamingPlatform>.from(state.selectedPlatforms);
      
      if (currentSelected.any((p) => p.id == platform.id)) {
        currentSelected.removeWhere((p) => p.id == platform.id);
      } else {
        currentSelected.add(platform);
      }
      
      // Save to preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(
        'selected_platforms',
        currentSelected.map((p) => p.id).toList(),
      );
      
      emit(state.copyWith(selectedPlatforms: currentSelected));
    } catch (e) {
      emit(state.copyWith(error: 'Failed to toggle platform: $e'));
    }
  }

  Future<void> selectAllPlatforms() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(
        'selected_platforms',
        _allPlatforms.map((p) => p.id).toList(),
      );
      
      emit(state.copyWith(selectedPlatforms: _allPlatforms));
    } catch (e) {
      emit(state.copyWith(error: 'Failed to select all platforms: $e'));
    }
  }

  Future<void> clearAllPlatforms() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('selected_platforms', []);
      
      emit(state.copyWith(selectedPlatforms: []));
    } catch (e) {
      emit(state.copyWith(error: 'Failed to clear platforms: $e'));
    }
  }

  List<String> get selectedPlatformIds => state.selectedPlatforms.map((p) => p.id).toList();
} 