import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../core/themes/app_colors.dart';
import '../../models/editor_tab.dart';

class EditorTabBar extends StatelessWidget {
  final List<EditorTab> tabs;
  final int activeIndex;
  final Function(int) onTabSelected;
  final Function(int) onTabClosed;
  final Function(int, int) onTabReorder;

  const EditorTabBar({
    super.key,
    required this.tabs,
    required this.activeIndex,
    required this.onTabSelected,
    required this.onTabClosed,
    required this.onTabReorder,
  });

  @override
  Widget build(BuildContext context) {
    if (tabs.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      height: 36,
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        border: Border(bottom: BorderSide(color: AppColors.border, width: 1)),
      ),
      child: ReorderableListView.builder(
        scrollDirection: Axis.horizontal,
        buildDefaultDragHandles: false,
        itemCount: tabs.length,
        onReorder: onTabReorder,
        proxyDecorator: (child, index, animation) {
          return Material(color: Colors.transparent, child: child);
        },
        itemBuilder: (context, index) {
          final tab = tabs[index];
          final isActive = index == activeIndex;

          return ReorderableDragStartListener(
            key: ValueKey(tab.path),
            index: index,
            child: _TabItem(
              tab: tab,
              isActive: isActive,
              onTap: () => onTabSelected(index),
              onClose: () => onTabClosed(index),
            ),
          );
        },
      ),
    );
  }
}

class _TabItem extends StatefulWidget {
  final EditorTab tab;
  final bool isActive;
  final VoidCallback onTap;
  final VoidCallback onClose;

  const _TabItem({
    required this.tab,
    required this.isActive,
    required this.onTap,
    required this.onClose,
  });

  @override
  State<_TabItem> createState() => _TabItemState();
}

class _TabItemState extends State<_TabItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
          onEnter: (_) => setState(() => _isHovered = true),
          onExit: (_) => setState(() => _isHovered = false),
          child: GestureDetector(
            onTap: widget.onTap,
            child: Container(
              constraints: const BoxConstraints(minWidth: 100, maxWidth: 180),
              decoration: BoxDecoration(
                color: widget.isActive
                    ? AppColors.background
                    : AppColors.surfaceLight,
                border: Border(
                  right: BorderSide(color: AppColors.border, width: 1),
                  top: widget.isActive
                      ? BorderSide(color: AppColors.primary, width: 2)
                      : BorderSide.none,
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(_getFileIcon(), size: 14, color: _getFileIconColor()),
                  const SizedBox(width: 8),

                  Flexible(
                    child: Text(
                      widget.tab.name,
                      style: TextStyle(
                        fontSize: 12,
                        color: widget.isActive
                            ? AppColors.textPrimary
                            : AppColors.textSecondary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),

                  const SizedBox(width: 8),
                  _buildCloseOrModified(),
                ],
              ),
            ),
          ),
        )
        .animate(target: widget.isActive ? 1 : 0)
        .custom(duration: 150.ms, builder: (context, value, child) => child);
  }

  Widget _buildCloseOrModified() {
    if (widget.tab.isModified && !_isHovered) {
      return Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          color: AppColors.textPrimary,
          shape: BoxShape.circle,
        ),
      );
    }

    return GestureDetector(
      onTap: widget.onClose,
      child: Container(
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4),
          color: _isHovered ? AppColors.surfaceHover : Colors.transparent,
        ),
        child: Icon(
          Iconsax.close_circle,
          size: 14,
          color: _isHovered ? AppColors.textPrimary : AppColors.textMuted,
        ),
      ),
    );
  }

  IconData _getFileIcon() {
    switch (widget.tab.extension) {
      case 'dart':
        return Iconsax.code;
      case 'py':
        return Iconsax.code;
      case 'js':
      case 'ts':
      case 'jsx':
      case 'tsx':
        return Iconsax.code;
      case 'html':
        return Iconsax.global;
      case 'css':
      case 'scss':
        return Iconsax.brush_1;
      case 'json':
      case 'yaml':
      case 'yml':
        return Iconsax.document;
      case 'md':
        return Iconsax.document_text;
      default:
        return Iconsax.document_1;
    }
  }

  Color _getFileIconColor() {
    switch (widget.tab.extension) {
      case 'dart':
        return AppColors.primary;
      case 'py':
        return const Color(0xFF3776AB);
      case 'js':
      case 'jsx':
        return const Color(0xFFF7DF1E);
      case 'ts':
      case 'tsx':
        return const Color(0xFF3178C6);
      case 'html':
        return const Color(0xFFE34F26);
      case 'css':
      case 'scss':
        return const Color(0xFF1572B6);
      case 'json':
        return const Color(0xFFFFA500);
      default:
        return AppColors.textMuted;
    }
  }
}
