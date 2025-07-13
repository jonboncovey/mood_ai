# Mood AI: Flutter Application Architecture

This document outlines the proposed screen and BLoC (Business Logic Component) structure for the Mood AI mobile application.

---

## 1. Screen & Navigation Hierarchy

The application will utilize a centralized navigation system, likely managed by a package like `go_router`. This allows for deep linking and a decoupled navigation flow.

The primary navigation structure is as follows:

```
/ (App Root)
|
+-- /splash (Initial loading/auth check screen)
|
+-- /onboarding (First-time user experience)
|
+-- /home (Main application shell, likely with a BottomNavigationBar)
|   |
|   +-- /discovery (Default view for exploring and searching content)
|   |
|   +-- /profile (User profile and settings)
|
+-- /mood-selector (Modal or fullscreen page to set the user's mood)
|
+-- /content/:id (Details screen for a specific movie or series)

```

### Screen Descriptions:

*   **Splash Screen (`/splash`):**
    *   The initial entry point of the app.
    *   Responsible for checking authentication status, loading initial configuration, and navigating the user to either the Onboarding or Home screen.

*   **Onboarding Screen (`/onboarding`):**
    *   Shown to new users on their first launch.
    *   Explains the core features of the app, especially the "mood" filter.

*   **Home Screen (`/home`):**
    *   The main container for the app's core features after login/onboarding.
    *   Will likely contain a `BottomNavigationBar` to switch between `Discovery` and `Profile`.
    *   A persistent "Set Mood" button will be present, which opens the `/mood-selector`.

*   **Discovery Screen (`/discovery`):**
    *   The primary content interaction screen.
    *   By default, it displays various lists of movies and series (e.g., "Trending," "Popular," "Because you're feeling Happy").
    *   Contains a persistent search bar with both text and voice input. When a user initiates a search, the view transitions to show the search results, replacing the curated lists.
    *   The content displayed, both in lists and in search results, is influenced by the user's selected mood.

*   **Mood Selector Screen (`/mood-selector`):**
    *   A modal or full-screen view where users can select or update their current mood.
    *   Once a mood is set, it will update the `MoodCubit`, and relevant screens will rebuild to reflect the new mood filter.

*   **Content Details Screen (`/content/:id`):**
    *   Shows detailed information about a selected movie or series (e.g., synopsis, cast, rating, trailers).

*   **Profile Screen (`/profile`):**
    *   Displays user information.
    *   Provides options for logging out and managing settings.

---

## 2. BLoC Structure and Responsibilities

The state management will be handled by the `flutter_bloc` package. BLoCs will be provided high in the widget tree (e.g., above `MaterialApp`) to be accessible to all relevant screens.

### `MoodCubit`

*   **Responsibility:** Manages the user's current mood globally across the app.
*   **State:**
    *   `MoodState`: Contains the `currentMood` (e.g., an enum `Mood.happy`, `Mood.sad`).
*   **Methods:**
    *   `updateMood(newMood)`: Triggered when the user selects a new mood.
*   **Used In:**
    *   **Provided:** High in the widget tree, accessible globally.
    *   **Modified:** `MoodSelectorScreen`.
    *   **Consumed:** `DiscoveryBloc`, `HomeScreen`.

### `DiscoveryBloc`

*   **Responsibility:** A unified BLoC that manages both the browsing of curated content lists and the natural language search functionality. It orchestrates voice recognition, NLP, and fetching content from the repository. If a mood is detected in a search query, it updates the global `MoodCubit`.
*   **Note:** The ContentRepository now uses Azure OpenAI for intelligent query processing, extracting genres and vibes, filtering the DB, and ranking results.
*   **State:** The state reflects whether the user is browsing or searching.
    *   `DiscoveryInitial`: The default state.
    *   `DiscoveryLoading`: Showing a loading indicator for the initial content lists.
    *   `DiscoveryDisplayingLists`: Contains lists of content (`trendingMovies`, `popularSeries`, etc.) for browsing.
    *   `DiscoverySearching`: Actively processing a text or voice search query.
    *   `DiscoveryDisplayingResults`: The view should now display the `List<Content>` of search results.
    *   `DiscoveryError`: Contains an error message if any data fetching fails.
*   **Events:**
    *   `FetchInitialContent`: Loads the initial curated lists for browsing.
    *   `StartVoiceSearch`: Triggered when the user taps the microphone button.
    *   `SubmitTextSearch(textQuery)`: Triggered when the user submits their query via the text field.
    *   `_onMoodChanged`: (Internal listener) Reacts to state changes from `MoodCubit`. It will either refetch the curated lists or re-run the current search with the new mood filter.
*   **Dependencies:**
    *   `MoodCubit`: To react to mood changes and to update the mood from search queries.
    *   `ContentRepository`: A repository that can both fetch curated content lists AND process a natural language query (including voice) to return search results.
*   **Used In:**
    *   **Provided/Consumed:** `DiscoveryScreen`.

### `ContentDetailsCubit`

*   **Responsibility:** Fetches detailed information for a single piece of content.
*   **State:**
    *   `ContentDetailsLoading`:
    *   `ContentDetailsLoaded`: Contains the full `Content` object with all details.
    *   `ContentDetailsError`:
*   **Methods:**
    *   `fetchDetails(contentId)`: Triggered when the user navigates to a details screen.
*   **Used In:**
    *   **Provided/Consumed:** `ContentDetailsScreen`.

### `AuthenticationCubit`

*   **Responsibility:** Manages user authentication state.
*   **State:**
    *   `AuthenticationInitial`:
    *   `AuthenticationAuthenticated(user)`:
    *   `AuthenticationUnauthenticated`:
*   **Methods:**
    *   `checkAuthStatus()`: To check the initial auth state on app start.
    *   `logIn()`:
    *   `logOut()`:
*   **Used In:**
    *   **Provided:** Globally.
    *   **Consumed:** `SplashScreen`, `AppRoot` (to control navigation), `ProfileScreen`.

