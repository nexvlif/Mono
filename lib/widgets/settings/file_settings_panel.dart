import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../core/themes/app_colors.dart';
import '../../models/file_settings.dart';

class FileSettingsPanel extends StatefulWidget {
  final FileSettings settings;
  final Function(FileSettings) onSettingsChanged;
  final VoidCallback onClose;

  const FileSettingsPanel({
    super.key,
    required this.settings,
    required this.onSettingsChanged,
    required this.onClose,
  });

  @override
  State<FileSettingsPanel> createState() => _FileSettingsPanelState();
}

class _FileSettingsPanelState extends State<FileSettingsPanel> {
  late FileSettings _settings;

  @override
  void initState() {
    super.initState();
    _settings = widget.settings.copyWith();
  }

  void _updateSetting(FileSettings Function(FileSettings) updater) {
    setState(() {
      _settings = updater(_settings);
    });
    widget.onSettingsChanged(_settings);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader(),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSection('Encoding & Format', [
                    _buildDropdown<FileEncoding>(
                      'Encoding',
                      _settings.encoding,
                      FileEncoding.values,
                      (e) => e.displayName,
                      (value) =>
                          _updateSetting((s) => s.copyWith(encoding: value)),
                    ),
                    const SizedBox(height: 12),
                    _buildDropdown<LineEnding>(
                      'Line Ending',
                      _settings.lineEnding,
                      LineEnding.values,
                      (e) => '${e.symbol} (${e.description})',
                      (value) =>
                          _updateSetting((s) => s.copyWith(lineEnding: value)),
                    ),
                  ]),

                  const SizedBox(height: 20),

                  _buildSection('Indentation', [
                    Row(
                      children: [
                        Expanded(
                          child: _buildDropdown<IndentType>(
                            'Type',
                            _settings.indentType,
                            IndentType.values,
                            (e) => e.displayName,
                            (value) => _updateSetting(
                              (s) => s.copyWith(indentType: value),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildDropdown<int>(
                            'Size',
                            _settings.indentSize,
                            [2, 4, 8],
                            (e) => '$e spaces',
                            (value) => _updateSetting(
                              (s) => s.copyWith(indentSize: value),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildToggle(
                      'Detect from file',
                      _settings.detectIndentation,
                      (value) => _updateSetting(
                        (s) => s.copyWith(detectIndentation: value),
                      ),
                    ),
                  ]),

                  const SizedBox(height: 20),

                  _buildSection('Whitespace', [
                    _buildToggle(
                      'Trim trailing whitespace',
                      _settings.trimTrailingWhitespace,
                      (value) => _updateSetting(
                        (s) => s.copyWith(trimTrailingWhitespace: value),
                      ),
                    ),
                    _buildToggle(
                      'Insert final newline',
                      _settings.insertFinalNewline,
                      (value) => _updateSetting(
                        (s) => s.copyWith(insertFinalNewline: value),
                      ),
                    ),
                    _buildToggle(
                      'Show invisible characters',
                      _settings.showInvisibleChars,
                      (value) => _updateSetting(
                        (s) => s.copyWith(showInvisibleChars: value),
                      ),
                    ),
                  ]),

                  const SizedBox(height: 20),

                  _buildSection('Advanced', [
                    _buildToggle(
                      'Normalize Unicode',
                      _settings.normalizeUnicode,
                      (value) => _updateSetting(
                        (s) => s.copyWith(normalizeUnicode: value),
                      ),
                      subtitle: 'Convert special space/separator characters',
                    ),
                    _buildToggle(
                      'Preserve BOM',
                      _settings.preserveBom,
                      (value) =>
                          _updateSetting((s) => s.copyWith(preserveBom: value)),
                      subtitle: 'Keep Byte Order Mark if present',
                    ),
                  ]),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border, width: 1)),
      ),
      child: Row(
        children: [
          Icon(Iconsax.setting_4, size: 20, color: AppColors.textSecondary),
          const SizedBox(width: 10),
          Text(
            'File Settings',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: widget.onClose,
            icon: Icon(Iconsax.close_circle, size: 20),
            color: AppColors.textSecondary,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 10),
        ...children,
      ],
    );
  }

  Widget _buildDropdown<T>(
    String label,
    T value,
    List<T> options,
    String Function(T) displayName,
    Function(T) onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 4),
        Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: AppColors.border),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              value: value,
              isExpanded: true,
              dropdownColor: AppColors.surfaceLight,
              style: TextStyle(fontSize: 13, color: AppColors.textPrimary),
              icon: Icon(
                Iconsax.arrow_down_1,
                size: 16,
                color: AppColors.textSecondary,
              ),
              items: options.map((option) {
                return DropdownMenuItem<T>(
                  value: option,
                  child: Text(displayName(option)),
                );
              }).toList(),
              onChanged: (newValue) {
                if (newValue != null) onChanged(newValue);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildToggle(
    String label,
    bool value,
    Function(bool) onChanged, {
    String? subtitle,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 14, color: AppColors.textPrimary),
                ),
                if (subtitle != null)
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                  ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.primary,
            activeTrackColor: AppColors.primary.withValues(alpha: 0.3),
            inactiveThumbColor: AppColors.textMuted,
            inactiveTrackColor: AppColors.surfaceLight,
          ),
        ],
      ),
    );
  }
}

Future<FileSettings?> showFileSettingsPanel(
  BuildContext context,
  FileSettings settings,
) async {
  FileSettings? result;

  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    constraints: BoxConstraints(
      maxHeight: MediaQuery.of(context).size.height * 0.7,
    ),
    builder: (context) {
      return FileSettingsPanel(
        settings: settings,
        onSettingsChanged: (newSettings) {
          result = newSettings;
        },
        onClose: () => Navigator.pop(context),
      );
    },
  );

  return result;
}
