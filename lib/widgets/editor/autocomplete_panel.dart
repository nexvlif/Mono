import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/themes/app_colors.dart';
import '../../services/autocomplete_service.dart';

class AutocompletePanel extends StatefulWidget {
  final List<CompletionItem> items;
  final Function(CompletionItem) onSelect;
  final VoidCallback onDismiss;
  final Offset position;

  const AutocompletePanel({
    super.key,
    required this.items,
    required this.onSelect,
    required this.onDismiss,
    required this.position,
  });

  @override
  State<AutocompletePanel> createState() => _AutocompletePanelState();
}

class _AutocompletePanelState extends State<AutocompletePanel> {
  int _selectedIndex = 0;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _selectedIndex = 0;
  }

  @override
  void didUpdateWidget(AutocompletePanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.items != oldWidget.items) {
      _selectedIndex = 0;
      _scrollToSelected();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void selectNext() {
    if (widget.items.isEmpty) return;
    setState(() {
      _selectedIndex = (_selectedIndex + 1) % widget.items.length;
    });
    _scrollToSelected();
  }

  void selectPrevious() {
    if (widget.items.isEmpty) return;
    setState(() {
      _selectedIndex =
          (_selectedIndex - 1 + widget.items.length) % widget.items.length;
    });
    _scrollToSelected();
  }

  void confirmSelection() {
    if (_selectedIndex >= 0 && _selectedIndex < widget.items.length) {
      widget.onSelect(widget.items[_selectedIndex]);
    }
  }

  void _scrollToSelected() {
    if (!_scrollController.hasClients) return;

    const itemHeight = 36.0;
    final offset = _selectedIndex * itemHeight;
    final viewportHeight = _scrollController.position.viewportDimension;

    if (offset < _scrollController.offset) {
      _scrollController.animateTo(
        offset,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOut,
      );
    } else if (offset + itemHeight >
        _scrollController.offset + viewportHeight) {
      _scrollController.animateTo(
        offset - viewportHeight + itemHeight,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) {
      return const SizedBox.shrink();
    }

    return Positioned(
      left: widget.position.dx,
      top: widget.position.dy,
      child: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(8),
        color: AppColors.surfaceLight,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 320, maxHeight: 240),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: AppColors.border, width: 1),
                  ),
                ),
                child: Row(
                  children: [
                    Text(
                      'Suggestions',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${widget.items.length} items',
                      style: TextStyle(
                        fontSize: 10,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),

              Flexible(
                child: ListView.builder(
                  controller: _scrollController,
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  itemCount: widget.items.length,
                  itemBuilder: (context, index) {
                    return _buildItem(widget.items[index], index);
                  },
                ),
              ),

              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  border: Border(
                    top: BorderSide(color: AppColors.border, width: 1),
                  ),
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(8),
                  ),
                ),
                child: Row(
                  children: [
                    _buildHint('↑↓', 'navigate'),
                    const SizedBox(width: 12),
                    _buildHint('Tab/Enter', 'insert'),
                    const SizedBox(width: 12),
                    _buildHint('Esc', 'dismiss'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildItem(CompletionItem item, int index) {
    final isSelected = index == _selectedIndex;

    return GestureDetector(
      onTap: () => widget.onSelect(item),
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        color: isSelected ? AppColors.primary.withValues(alpha: 0.15) : null,
        child: Row(
          children: [
            Container(
              width: 22,
              height: 22,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: _getKindColor(item.kind).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(item.icon, style: TextStyle(fontSize: 12)),
            ),

            const SizedBox(width: 8),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    item.label,
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (item.detail != null)
                    Text(
                      item.detail!,
                      style: TextStyle(
                        fontSize: 10,
                        color: AppColors.textMuted,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                color: _getKindColor(item.kind).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(3),
              ),
              child: Text(
                _getKindLabel(item.kind),
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  color: _getKindColor(item.kind),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHint(String key, String action) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(3),
            border: Border.all(color: AppColors.border),
          ),
          child: Text(
            key,
            style: GoogleFonts.jetBrainsMono(
              fontSize: 9,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        const SizedBox(width: 3),
        Text(action, style: TextStyle(fontSize: 9, color: AppColors.textMuted)),
      ],
    );
  }

  Color _getKindColor(CompletionItemKind kind) {
    switch (kind) {
      case CompletionItemKind.emmet:
        return AppColors.success;
      case CompletionItemKind.snippet:
        return AppColors.warning;
      case CompletionItemKind.keyword:
        return AppColors.primary;
      case CompletionItemKind.text:
        return AppColors.textSecondary;
      case CompletionItemKind.variable:
        return AppColors.info;
      case CompletionItemKind.function:
        return AppColors.success;
      case CompletionItemKind.className:
        return AppColors.secondary;
    }
  }

  String _getKindLabel(CompletionItemKind kind) {
    switch (kind) {
      case CompletionItemKind.emmet:
        return 'emmet';
      case CompletionItemKind.snippet:
        return 'snip';
      case CompletionItemKind.keyword:
        return 'key';
      case CompletionItemKind.text:
        return 'word';
      case CompletionItemKind.variable:
        return 'var';
      case CompletionItemKind.function:
        return 'fn';
      case CompletionItemKind.className:
        return 'class';
    }
  }
}
