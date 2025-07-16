part of 'streaming_platforms_cubit.dart';

class StreamingPlatform extends Equatable {
  final String id;
  final String name;
  final String icon;

  const StreamingPlatform({
    required this.id,
    required this.name,
    required this.icon,
  });

  @override
  List<Object?> get props => [id, name, icon];
}

class StreamingPlatformsState extends Equatable {
  final List<StreamingPlatform> allPlatforms;
  final List<StreamingPlatform> selectedPlatforms;
  final bool isLoading;
  final String? error;

  const StreamingPlatformsState({
    this.allPlatforms = const [],
    this.selectedPlatforms = const [],
    this.isLoading = true,
    this.error,
  });

  StreamingPlatformsState copyWith({
    List<StreamingPlatform>? allPlatforms,
    List<StreamingPlatform>? selectedPlatforms,
    bool? isLoading,
    String? error,
  }) {
    return StreamingPlatformsState(
      allPlatforms: allPlatforms ?? this.allPlatforms,
      selectedPlatforms: selectedPlatforms ?? this.selectedPlatforms,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }

  @override
  List<Object?> get props => [allPlatforms, selectedPlatforms, isLoading, error];
} 