import 'package:flutter/material.dart';

class CallHistorySearchAndFilterBar extends StatelessWidget {
  final String searchText;
  final ValueChanged<String> onSearchChanged;
  final String filterType;
  final ValueChanged<String> onFilterChanged;
  final List<String> filterOptions;

  const CallHistorySearchAndFilterBar({
    super.key,
    required this.searchText,
    required this.onSearchChanged,
    required this.filterType,
    required this.onFilterChanged,
    this.filterOptions = const ['all', 'missed', 'answered'],
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Search bar
        Expanded(
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Search calls',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: BorderSide.none,
              ),
              filled: true,
              contentPadding: EdgeInsets.symmetric(vertical: 0, horizontal: 16),
            ),
            onChanged: onSearchChanged,
            controller: TextEditingController(text: searchText),
          ),
        ),
        const SizedBox(width: 8),
        // Filter button
        PopupMenuButton<String>(
          icon: Icon(Icons.filter_list),
          onSelected: onFilterChanged,
          itemBuilder: (context) => filterOptions
              .map(
                (option) => PopupMenuItem(
                  value: option,
                  child: Text(option[0].toUpperCase() + option.substring(1)),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}
