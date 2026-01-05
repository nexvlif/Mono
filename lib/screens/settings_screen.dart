import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../core/themes/app_colors.dart';
import '../core/constants/app_constants.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // Settings state
  bool _darkMode = true;
  double _fontSize = 14;
  String _fontFamily = 'JetBrains Mono';
  int _tabSize = 2;
  bool _wordWrap = false;
  bool _showLineNumbers = true;
  bool _showMinimap = false;
  bool _autoSave = false;
  bool _formatOnSave = false;
  bool _autoCloseBrackets = true;
  bool _highlightCurrentLine = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: Text(
          'Settings',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(Iconsax.arrow_left, color: AppColors.textSecondary),
        ),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildDevelopmentBanner(),
          const SizedBox(height: 16),
          // Editor Section
          _buildSectionHeader('Editor'),
          _buildSettingCard([
            _buildDropdownSetting(
              'Font Family',
              _fontFamily,
              ['JetBrains Mono', 'Fira Code', 'Source Code Pro', 'Roboto Mono'],
              (value) => setState(() => _fontFamily = value),
              icon: Iconsax.text,
            ),
            _buildDivider(),
            _buildSliderSetting(
              'Font Size',
              _fontSize,
              10,
              24,
              (value) => setState(() => _fontSize = value),
              icon: Iconsax.text_block,
            ),
            _buildDivider(),
            _buildDropdownSetting(
              'Tab Size',
              _tabSize.toString(),
              ['2', '4', '8'],
              (value) => setState(() => _tabSize = int.parse(value)),
              icon: Iconsax.arrow_right_3,
            ),
          ]),

          const SizedBox(height: 20),

          // Display Section
          _buildSectionHeader('Display'),
          _buildSettingCard([
            _buildSwitchSetting(
              'Dark Mode',
              'Use dark theme',
              _darkMode,
              (value) => setState(() => _darkMode = value),
              icon: Iconsax.moon,
            ),
            _buildDivider(),
            _buildSwitchSetting(
              'Word Wrap',
              'Wrap long lines',
              _wordWrap,
              (value) => setState(() => _wordWrap = value),
              icon: Iconsax.text_italic,
            ),
            _buildDivider(),
            _buildSwitchSetting(
              'Line Numbers',
              'Show line numbers',
              _showLineNumbers,
              (value) => setState(() => _showLineNumbers = value),
              icon: Iconsax.hashtag,
            ),
            _buildDivider(),
            _buildSwitchSetting(
              'Highlight Current Line',
              'Highlight the active line',
              _highlightCurrentLine,
              (value) => setState(() => _highlightCurrentLine = value),
              icon: Iconsax.minus,
            ),
            _buildDivider(),
            _buildSwitchSetting(
              'Minimap',
              'Show code overview (Beta)',
              _showMinimap,
              (value) => setState(() => _showMinimap = value),
              icon: Iconsax.map,
              isBeta: true,
            ),
          ]),

          const SizedBox(height: 20),

          // Editing Section
          _buildSectionHeader('Editing'),
          _buildSettingCard([
            _buildSwitchSetting(
              'Auto Save',
              'Save files automatically',
              _autoSave,
              (value) => setState(() => _autoSave = value),
              icon: Iconsax.document_download,
            ),
            _buildDivider(),
            _buildSwitchSetting(
              'Format on Save',
              'Auto format when saving',
              _formatOnSave,
              (value) => setState(() => _formatOnSave = value),
              icon: Iconsax.code_1,
            ),
            _buildDivider(),
            _buildSwitchSetting(
              'Auto Close Brackets',
              'Automatically close brackets',
              _autoCloseBrackets,
              (value) => setState(() => _autoCloseBrackets = value),
              icon: Iconsax.code,
            ),
          ]),

          const SizedBox(height: 20),

          // Extensions Section
          _buildSectionHeader('Extensions'),
          _buildSettingCard([
            _buildActionSetting(
              'Manage Extensions',
              'Browse and install extensions',
              Iconsax.box_1,
              () => _showExtensionsDialog(),
              trailing: _buildBetaBadge(),
            ),
          ]),

          const SizedBox(height: 20),

          // About Section
          _buildSectionHeader('About'),
          _buildSettingCard([
            _buildInfoSetting('Version', AppConstants.appVersion, Iconsax.tag),
            _buildDivider(),
            _buildActionSetting(
              'Developer',
              'nexvlif • Ard',
              Iconsax.user,
              () => _openGitHub(),
            ),
            _buildDivider(),
            _buildActionSetting(
              'GitHub Repository',
              'github.com/nexvlif/mono',
              Iconsax.code_circle,
              () => _openGitHub(),
            ),
            _buildDivider(),
            _buildActionSetting(
              'Report Bug',
              'Submit an issue',
              Iconsax.warning_2,
              () => _showGitHubInfo(),
            ),
            _buildActionSetting(
              'License',
              'View license',
              Iconsax.document,
              () => _showLicenseDialog(),
            ),
            _buildDivider(),
            _buildInfoSetting('Copyright', '© 2026 nexvlif', Iconsax.tag),
          ]),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary,
          letterSpacing: 1,
        ),
      ),
    );
  }

  Widget _buildSettingCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildDivider() {
    return Divider(height: 1, color: AppColors.border);
  }

  Widget _buildSwitchSetting(
    String title,
    String subtitle,
    bool value,
    Function(bool) onChanged, {
    required IconData icon,
    bool isBeta = false,
  }) {
    return ListTile(
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 18, color: AppColors.textSecondary),
      ),
      title: Row(
        children: [
          Text(
            title,
            style: TextStyle(fontSize: 14, color: AppColors.textPrimary),
          ),
          if (isBeta) ...[const SizedBox(width: 6), _buildBetaBadge()],
        ],
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(fontSize: 12, color: AppColors.textMuted),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: AppColors.primary,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
    );
  }

  Widget _buildDropdownSetting(
    String title,
    String value,
    List<String> options,
    Function(String) onChanged, {
    required IconData icon,
  }) {
    return ListTile(
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 18, color: AppColors.textSecondary),
      ),
      title: Text(
        title,
        style: TextStyle(fontSize: 14, color: AppColors.textPrimary),
      ),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AppColors.border),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: value,
            isDense: true,
            dropdownColor: AppColors.surfaceLight,
            style: TextStyle(fontSize: 13, color: AppColors.textPrimary),
            items: options.map((opt) {
              return DropdownMenuItem(value: opt, child: Text(opt));
            }).toList(),
            onChanged: (v) => onChanged(v!),
          ),
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
    );
  }

  Widget _buildSliderSetting(
    String title,
    double value,
    double min,
    double max,
    Function(double) onChanged, {
    required IconData icon,
  }) {
    return ListTile(
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 18, color: AppColors.textSecondary),
      ),
      title: Row(
        children: [
          Text(
            title,
            style: TextStyle(fontSize: 14, color: AppColors.textPrimary),
          ),
          const Spacer(),
          Text(
            '${value.round()}px',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
      subtitle: Slider(
        value: value,
        min: min,
        max: max,
        divisions: (max - min).round(),
        onChanged: onChanged,
        activeColor: AppColors.primary,
        inactiveColor: AppColors.surfaceLight,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
    );
  }

  Widget _buildActionSetting(
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap, {
    Widget? trailing,
  }) {
    return ListTile(
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 18, color: AppColors.textSecondary),
      ),
      title: Row(
        children: [
          Text(
            title,
            style: TextStyle(fontSize: 14, color: AppColors.textPrimary),
          ),
          if (trailing != null) ...[const SizedBox(width: 6), trailing],
        ],
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(fontSize: 12, color: AppColors.textMuted),
      ),
      trailing: Icon(
        Iconsax.arrow_right_3,
        size: 16,
        color: AppColors.textMuted,
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
    );
  }

  Widget _buildInfoSetting(String title, String value, IconData icon) {
    return ListTile(
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 18, color: AppColors.textSecondary),
      ),
      title: Text(
        title,
        style: TextStyle(fontSize: 14, color: AppColors.textPrimary),
      ),
      trailing: Text(
        value,
        style: TextStyle(
          fontSize: 13,
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w500,
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
    );
  }

  Widget _buildBetaBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        'ALPHA',
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          color: AppColors.warning,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  void _showLicenseDialog() {
    const licenseText = '''MIT License

Copyright (c) 2026 nexvlif

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
''';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('License', style: TextStyle(color: AppColors.textPrimary)),
        content: SingleChildScrollView(
          child: Text(licenseText, style: TextStyle(color: AppColors.textSecondary)),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
          TextButton(
            onPressed: () {
              Clipboard.setData(const ClipboardData(text: licenseText));
              Navigator.pop(context);
            },
            child: const Text('Copy'),
          ),
        ],
      ),
    );
  }

  void _showExtensionsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Row(
          children: [
            Text('Extensions', style: TextStyle(color: AppColors.textPrimary)),
            const SizedBox(width: 8),
            _buildBetaBadge(),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Extension support is coming soon!',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            Text(
              'Planned features:',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            _buildExtensionFeature('• Syntax themes'),
            _buildExtensionFeature('• Language packs'),
            _buildExtensionFeature('• Custom snippets'),
            _buildExtensionFeature('• Git integrations'),
            _buildExtensionFeature('• Linters & formatters'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  Widget _buildExtensionFeature(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Text(
        text,
        style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
      ),
    );
  }

  Widget _buildDevelopmentBanner() {
    return Container(
      width: double.infinity,
      color: AppColors.info.withValues(alpha: 0.1),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      child: Row(
        children: [
          Icon(Iconsax.info_circle, size: 16, color: AppColors.info),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Development Process',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.info,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showGitHubInfo() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Visit: github.com/nexvlif/mono'),
        backgroundColor: AppColors.surface,
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'Copy',
          onPressed: () {
            Clipboard.setData(
              const ClipboardData(text: 'https://github.com/nexvlif'),
            );
          },
        ),
      ),
    );
  }

  void _openGitHub() {
    _showGitHubInfo();
  }
}
