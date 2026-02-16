import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../data/models/genre_categories.dart';
import '../discover_controller.dart';

class GenrePickerSheet extends StatefulWidget {
  const GenrePickerSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => const GenrePickerSheet(),
    );
  }

  @override
  State<GenrePickerSheet> createState() => _GenrePickerSheetState();
}

class _GenrePickerSheetState extends State<GenrePickerSheet> {
  final _selected = <String>{};

  @override
  void initState() {
    super.initState();
    final ctrl = Get.find<DiscoverController>();
    // Pre-select tags that are already in preferences AND are built-in
    for (final tag in ctrl.preferenceTags) {
      if (kBuiltInTags.contains(tag)) {
        _selected.add(tag);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            // Handle bar
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 8),
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            // Title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                '选择风格',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            // Category list
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: kGenreCategories.length,
                itemBuilder: (context, index) {
                  final category = kGenreCategories[index];
                  return _buildCategory(theme, category);
                },
              ),
            ),
            // Confirm button
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              child: FilledButton(
                onPressed: _onConfirm,
                style: FilledButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                ),
                child: Text(
                  _selected.isEmpty
                      ? '确认'
                      : '确认（已选 ${_selected.length} 个）',
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCategory(ThemeData theme, GenreCategory category) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${category.icon} ${category.name}',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: category.tags.map((tag) {
              final isSelected = _selected.contains(tag);
              return FilterChip(
                label: Text(tag),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _selected.add(tag);
                    } else {
                      _selected.remove(tag);
                    }
                  });
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  void _onConfirm() {
    final ctrl = Get.find<DiscoverController>();

    // Keep non-built-in tags (AI/manually added), merge with selected genre tags
    final customTags = ctrl.preferenceTags
        .where((tag) => !kBuiltInTags.contains(tag))
        .toList();

    final merged = [...customTags, ..._selected];
    ctrl.saveTagsToStorage(merged);

    Navigator.of(context).pop();
  }
}
