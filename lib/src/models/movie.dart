import 'dart:convert';
import 'package:equatable/equatable.dart';

class Movie extends Equatable {
  final int id;
  final String? title;
  final double? voteAverage;
  final int? voteCount;
  final String? status;
  final String? releaseDate;
  final int? revenue;
  final int? runtime;
  final bool? adult;
  final String? backdropPath;
  final int? budget;
  final String? homepage;
  final String? imdbId;
  final String? originalLanguage;
  final String? originalTitle;
  final String? overview;
  final double? popularity;
  final String? posterPath;
  final String? tagline;
  final List<String> genres;
  final String? productionCompanies;
  final String? productionCountries;
  final String? spokenLanguages;
  final String? keywords;
  final Map<String, dynamic>? streamingOptions;

  const Movie({
    required this.id,
    this.title,
    this.voteAverage,
    this.voteCount,
    this.status,
    this.releaseDate,
    this.revenue,
    this.runtime,
    this.adult,
    this.backdropPath,
    this.budget,
    this.homepage,
    this.imdbId,
    this.originalLanguage,
    this.originalTitle,
    this.overview,
    this.popularity,
    this.posterPath,
    this.tagline,
    this.genres = const [],
    this.productionCompanies,
    this.productionCountries,
    this.spokenLanguages,
    this.keywords,
    this.streamingOptions,
  });

  String get fullPosterUrl {
    if (posterPath != null) {
      return 'https://image.tmdb.org/t/p/w500$posterPath';
    }
    return 'https://via.placeholder.com/500x750.png?text=No+Image';
  }

  String get fullBackdropUrl {
    if (backdropPath != null) {
      return 'https://image.tmdb.org/t/p/w1280$backdropPath';
    }
    return 'https://via.placeholder.com/1280x720.png?text=No+Image';
  }

  factory Movie.fromMap(Map<String, dynamic> map) {
    final rawGenres = map['genres'];
    List<String>? genresList;
    if (rawGenres is String) {
      genresList =
          rawGenres.split(',').map((e) => e.trim()).toList();
    } else if (rawGenres is List) {
      genresList = List<String>.from(rawGenres);
    }

    return Movie(
      id: map['id'] as int,
      title: map['title'] as String?,
      voteAverage: (map['vote_average'] as num?)?.toDouble(),
      voteCount: map['vote_count'],
      status: map['status'],
      releaseDate: map['release_date'] as String?,
      revenue: map['revenue'],
      runtime: map['runtime'],
      adult: map['adult'] == 1,
      backdropPath: map['backdrop_path'],
      budget: map['budget'],
      homepage: map['homepage'],
      imdbId: map['imdb_id'],
      originalLanguage: map['original_language'],
      originalTitle: map['original_title'],
      overview: map['overview'] as String?,
      popularity: map['popularity']?.toDouble(),
      posterPath: map['poster_path'] as String?,
      tagline: map['tagline'],
      genres: genresList ?? [],
      productionCompanies: map['production_companies'],
      productionCountries: map['production_countries'],
      spokenLanguages: map['spoken_languages'],
      keywords: map['keywords'],
      streamingOptions: _parseStreamingOptions(map['streaming_options']),
    );
  }

  static List<String> _parseGenres(String? genreString) {
    if (genreString == null || genreString.isEmpty) {
      return [];
    }
    try {
      final List<dynamic> decoded = json.decode(genreString);
      return decoded.map((genre) => genre['name'] as String).toList();
    } catch (e) {
      return [];
    }
  }

  static Map<String, dynamic>? _parseStreamingOptions(String? streamingOptionsString) {
    if (streamingOptionsString == null || streamingOptionsString.isEmpty) {
      return null;
    }
    try {
      return json.decode(streamingOptionsString) as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }

  @override
  List<Object?> get props => [
        id,
        title,
        voteAverage,
        voteCount,
        status,
        releaseDate,
        revenue,
        runtime,
        adult,
        backdropPath,
        budget,
        homepage,
        imdbId,
        originalLanguage,
        originalTitle,
        overview,
        popularity,
        posterPath,
        tagline,
        genres,
        productionCompanies,
        productionCountries,
        spokenLanguages,
        keywords,
        streamingOptions,
      ];
}
