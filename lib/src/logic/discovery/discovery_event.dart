import 'package:equatable/equatable.dart';

abstract class DiscoveryEvent extends Equatable {
  const DiscoveryEvent();

  @override
  List<Object> get props => [];
}

class FetchDiscoveryData extends DiscoveryEvent {}

class SearchQueryChanged extends DiscoveryEvent {
  final String query;

  const SearchQueryChanged(this.query);

  @override
  List<Object> get props => [query];
}

class StartVoiceSearch extends DiscoveryEvent {}

class StopVoiceSearch extends DiscoveryEvent {}

class VoiceSearchError extends DiscoveryEvent {}

class VoiceSearchResult extends DiscoveryEvent {
  final String recognizedText;

  const VoiceSearchResult(this.recognizedText);

  @override
  List<Object> get props => [recognizedText];
}

class VoiceSoundLevelChanged extends DiscoveryEvent {
  final double level;

  const VoiceSoundLevelChanged(this.level);

  @override
  List<Object> get props => [level];
}

class UpdateRecognizedText extends DiscoveryEvent {
  final String text;
  final bool isFinal;

  const UpdateRecognizedText(this.text, {this.isFinal = false});

  @override
  List<Object> get props => [text, isFinal];
}

class ClearSearch extends DiscoveryEvent {}

class StreamingPlatformsChanged extends DiscoveryEvent {}
