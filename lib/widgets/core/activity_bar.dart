import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../core/themes/app_colors.dart';

enum ActivityTab { explorer, search, git, extensions }

class ActivityBar extends StatelessWidget {
  final ActivityTab activeTab;
  final Function(ActivityTab) onTabSelected;
  final VoidCallback onSettings;

  const ActivityBar({
    super.key,
    required this.activeTab,
    required this.onTabSelected,
    required this.onSettings,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        border: Border(right: BorderSide(color: AppColors.border, width: 1)),
      ),
      child: Column(
        children: [
          _buildTab(ActivityTab.explorer, Iconsax.folder_2),
          _buildTab(ActivityTab.search, Iconsax.search_normal),
          _buildTab(ActivityTab.git, Iconsax.code_1),
          _buildTab(ActivityTab.extensions, Iconsax.box_1),
          const Spacer(),
          _buildIcon(Iconsax.setting_2, onSettings),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildTab(ActivityTab tab, IconData icon) {
    final isActive = activeTab == tab;
    return InkWell(
      onTap: () => onTabSelected(tab),
      child: Container(
        height: 48,
        width: 48,
        decoration: BoxDecoration(
          border: isActive
              ? Border(left: BorderSide(color: AppColors.primary, width: 2))
              : null,
        ),
        child: Icon(
          icon,
          size: 24,
          color: isActive ? AppColors.textPrimary : AppColors.textMuted,
        ),
      ),
    );
  }

  Widget _buildIcon(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: SizedBox(
        height: 48,
        width: 48,
        child: Icon(icon, size: 24, color: AppColors.textMuted),
      ),
    );
  }
}
