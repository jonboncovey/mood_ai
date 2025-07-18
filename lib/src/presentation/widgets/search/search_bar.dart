import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mood_ai/src/logic/discovery/discovery_bloc.dart';
import 'package:mood_ai/src/logic/discovery/discovery_event.dart';
import 'package:mood_ai/src/logic/discovery/discovery_state.dart';

class SearchBar extends StatelessWidget {
  const SearchBar({required this.controller, Key? key}) : super(key: key);
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DiscoveryBloc, DiscoveryState>(
      buildWhen: (p, c) =>
          p.isListening != c.isListening || p.searchStatus != c.searchStatus,
      builder: (context, state) {
        final isListening = state.isListening;
        final isInSearchMode = state.searchStatus != SearchStatus.initial;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceVariant,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              const Icon(Icons.search),
              const SizedBox(width: 16),
              Expanded(
                child: TextField(
                  controller: controller,
                  maxLines: null, // Allows the text field to grow
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.transparent,
                    border: InputBorder.none,
                    hintText:
                        isListening ? 'Listening...' : "What's your mood?",
                    suffixIcon: isInSearchMode
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              controller.clear();
                              context.read<DiscoveryBloc>().add(ClearSearch());
                            },
                          )
                        : null,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
} 