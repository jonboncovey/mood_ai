import 'package:mood_ai/src/models/mood_filter.dart';

final List<MoodFilter> moodFilters = [
  MoodFilter(
    name: "90s Rom-Com Classics",
    description: "Lighthearted, low-budget romance and comedy from the 1990s.",
    query:
        "genres LIKE '%Romance%' AND genres LIKE '%Comedy%' AND release_date >= '1990-01-01' AND release_date <= '1999-12-31' AND budget > 0 AND budget < 20000000",
  ),
  MoodFilter(
    name: "High-Octane Action",
    description: "Popular and critically-acclaimed, non-stop action movies.",
    query: "genres LIKE '%Action%' AND popularity > 100 AND vote_average > 7.0",
  ),
  MoodFilter(
    name: "Mind-Bending Sci-Fi",
    description: "Trippy science fiction featuring time travel, dystopias, or AI.",
    query:
        "genres LIKE '%Science Fiction%' AND (keywords LIKE '%time travel%' OR keywords LIKE '%dystopia%' OR keywords LIKE '%artificial intelligence%')",
  ),
  MoodFilter(
    name: "Indie Tearjerkers",
    description: "Low-budget, highly-rated dramas that will make you feel.",
    query:
        "genres LIKE '%Drama%' AND budget > 0 AND budget < 5000000 AND vote_average > 7.5",
  ),
  MoodFilter(
    name: "Spine-Chilling Horror",
    description: "Well-regarded horror movies that are sure to scare you.",
    query: "genres LIKE '%Horror%' AND vote_average > 6.5 AND vote_count > 500",
  ),
  MoodFilter(
    name: "Epic Fantasy Adventures",
    description: "Lengthy, adventurous, and fantastic journeys.",
    query:
        "genres LIKE '%Fantasy%' AND genres LIKE '%Adventure%' AND runtime > 120",
  ),
  MoodFilter(
    name: "Critically-Acclaimed Crime",
    description: "The highest-rated crime dramas.",
    query:
        "genres LIKE '%Crime%' AND genres LIKE '%Drama%' AND vote_average > 8.0",
  ),
  MoodFilter(
    name: "Laugh-Out-Loud Comedies",
    description: "The most popular and highly-rated comedies.",
    query: "genres LIKE '%Comedy%' AND popularity > 80 AND vote_average > 7.0",
  ),
]; 