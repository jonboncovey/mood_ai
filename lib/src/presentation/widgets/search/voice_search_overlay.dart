import 'package:flutter/material.dart' hide SearchBar;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mood_ai/src/logic/discovery/discovery_bloc.dart';
import 'package:mood_ai/src/logic/discovery/discovery_event.dart';
import 'package:mood_ai/src/logic/discovery/discovery_state.dart';
import 'package:mood_ai/src/presentation/widgets/search/mic_button.dart';
import 'package:mood_ai/src/presentation/widgets/search/search_bar.dart';
import 'package:mood_ai/src/presentation/widgets/search/search_results_body.dart';
import 'package:mood_ai/src/presentation/widgets/search/voice_visualizer.dart';

// Helper to report size
class _SizeReportingWidget extends StatefulWidget {
  final Widget child;
  final ValueChanged<Size> onSizeChanged;

  const _SizeReportingWidget({
    Key? key,
    required this.child,
    required this.onSizeChanged,
  }) : super(key: key);

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

class VoiceSearchOverlay extends StatefulWidget {
  final Widget child;
  const VoiceSearchOverlay({required this.child, Key? key}) : super(key: key);

  @override
  _VoiceSearchOverlayState createState() => _VoiceSearchOverlayState();
}

class _VoiceSearchOverlayState extends State<VoiceSearchOverlay> {
  late final TextEditingController _searchController;
  double _searchBarHeight = 72.0; // Default height + padding

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _searchController.addListener(() {
      if (context.mounted) {
        final bloc = context.read<DiscoveryBloc>();
        if (_searchController.text != bloc.state.recognizedText) {
          bloc.add(SearchQueryChanged(_searchController.text));
        }
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
        final isInSearchMode = state.searchStatus != SearchStatus.initial;
        return Stack(
          fit: StackFit.expand,
          children: [
            // Body
            if (isInSearchMode)
              SearchResultsBody(
                state: state,
                topPadding: _searchBarHeight,
              )
            else
              widget.child,

            // Voice Visualizer
            if (state.isListening) const VoiceVisualizer(),

            // Search Bar
            AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              top: isInSearchMode ? MediaQuery.of(context).padding.top : null,
              left: 16,
              right: isInSearchMode ? 16 : (16 + 56 + 8),
              bottom: isInSearchMode ? null : 24,
              child: _SizeReportingWidget(
                onSizeChanged: (size) =>
                    setState(() => _searchBarHeight = size.height),
                child: SearchBar(controller: _searchController),
              ),
            ),

            // Mic Button
            AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              bottom: 24,
              right: 16,
              child: const MicButton(),
            ),
          ],
        );
      },
    );
  }
} 