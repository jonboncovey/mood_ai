import 'package:flutter/material.dart' hide SearchBar;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mood_ai/src/logic/discovery/discovery_bloc.dart';
import 'package:mood_ai/src/logic/discovery/discovery_event.dart';
import 'package:mood_ai/src/logic/discovery/discovery_state.dart';
import 'package:mood_ai/src/presentation/screens/discover_screen.dart';
import 'package:mood_ai/src/presentation/screens/home_screen.dart';
import 'package:mood_ai/src/presentation/screens/profile_screen.dart';
import 'package:mood_ai/src/presentation/widgets/search/mic_button.dart';
import 'package:mood_ai/src/presentation/widgets/search/search_bar.dart';
import 'package:mood_ai/src/presentation/widgets/search/search_results_body.dart';
import 'package:mood_ai/src/presentation/widgets/search/voice_visualizer.dart';

// Helper to report size
class _SizeReportingWidget extends StatefulWidget {
  final Widget child;
  final ValueChanged<Size> onSizeChanged;

  const _SizeReportingWidget({
    required this.child,
    required this.onSizeChanged,
  });

  @override
  _SizeReportingWidgetState createState() => _SizeReportingWidgetState();
}

class _SizeReportingWidgetState extends State<_SizeReportingWidget> {
  final _widgetKey = GlobalKey();
  Size? _lastReportedSize;

  @override
  void initState() {
    super.initState();
    _reportSize();
  }

  void _reportSize() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final size = _widgetKey.currentContext?.size;
      if (size != null && size != _lastReportedSize) {
        _lastReportedSize = size;
        widget.onSizeChanged(size);
      }
    });
  }

  @override
  void didUpdateWidget(covariant _SizeReportingWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    _reportSize();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      key: _widgetKey,
      child: widget.child,
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  late final PageController _pageController;
  late final TextEditingController _searchController;
  double _searchBarHeight = 72.0; // Default height

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _selectedIndex);
    _searchController = TextEditingController();
    _searchController.addListener(() {
      if (mounted) {
        final bloc = context.read<DiscoveryBloc>();
        if (_searchController.text != bloc.state.recognizedText) {
          bloc.add(SearchQueryChanged(_searchController.text));
        }
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  List<Widget> _buildWidgetOptions() {
    // Pass the search bar height as bottom padding to the screens that need it.
    return <Widget>[
      HomeScreen(bottomPadding: _searchBarHeight),
      DiscoverScreen(bottomPadding: _searchBarHeight),
      const ProfileScreen(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<DiscoveryBloc, DiscoveryState>(
      listenWhen: (p, c) => p.recognizedText != c.recognizedText,
      listener: (context, state) {
        if (_searchController.text != state.recognizedText) {
          _searchController.text = state.recognizedText;
          _searchController.selection = TextSelection.fromPosition(
            TextPosition(offset: _searchController.text.length),
          );
        }
      },
      builder: (context, state) {
        final showSearchBar = _selectedIndex != 2;
        final isInSearchMode = state.searchStatus != SearchStatus.initial;
        final isListening = state.isListening;

        return Scaffold(
          body: Stack(
            fit: StackFit.expand,
            clipBehavior: Clip.none, // Allow shadows to escape the stack
            children: [
              // Page Content
              PageView(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _selectedIndex = index;
                  });
                },
                children: _buildWidgetOptions(),
              ),

              // Search Results
              if (isInSearchMode)
                SearchResultsBody(state: state, bottomPadding: _searchBarHeight),

              // Voice Visualizer
              if (isListening) const VoiceVisualizer(),

              // Persistent Search Bar
              if (showSearchBar)
                Positioned(
                  bottom: 0,
                  left: 12,
                  right: 12,
                  child: _SizeReportingWidget(
                    onSizeChanged: (size) {
                      final newHeight = size.height + 12; // Add padding
                      if (mounted && _searchBarHeight != newHeight) {
                        setState(() {
                          _searchBarHeight = newHeight;
                        });
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                              child: SearchBar(controller: _searchController)),
                          const SizedBox(width: 8),
                          const MicButton(),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
          bottomNavigationBar: BottomNavigationBar(
            items: const <BottomNavigationBarItem>[
              BottomNavigationBarItem(
                icon: Icon(Icons.home),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.search),
                label: 'Discover',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person),
                label: 'Profile',
              ),
            ],
            currentIndex: _selectedIndex,
            selectedItemColor: Theme.of(context).colorScheme.onSecondary,
            unselectedItemColor: Theme.of(context).colorScheme.primary,
            onTap: _onItemTapped,
          ),
        );
      },
    );
  }
} 