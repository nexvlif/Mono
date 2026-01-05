import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../core/themes/app_colors.dart';

class SearchReplacePanel extends StatefulWidget {
  final TextEditingController editorController;
  final bool showReplace;
  final VoidCallback onClose;
  final Function(List<SearchMatch>)? onMatchesChanged;

  const SearchReplacePanel({
    super.key,
    required this.editorController,
    this.showReplace = false,
    required this.onClose,
    this.onMatchesChanged,
  });

  @override
  State<SearchReplacePanel> createState() => _SearchReplacePanelState();
}

class _SearchReplacePanelState extends State<SearchReplacePanel> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _replaceController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();

  bool _showReplace = false;
  bool _caseSensitive = false;
  bool _wholeWord = false;
  bool _useRegex = false;

  List<SearchMatch> _matches = [];
  int _currentMatchIndex = -1;

  @override
  void initState() {
    super.initState();
    _showReplace = widget.showReplace;
    _searchController.addListener(_onSearchChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchFocus.requestFocus();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _replaceController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _search();
  }

  void _search() {
    final query = _searchController.text;
    if (query.isEmpty) {
      setState(() {
        _matches = [];
        _currentMatchIndex = -1;
      });
      widget.onMatchesChanged?.call([]);
      return;
    }

    final text = widget.editorController.text;
    final matches = <SearchMatch>[];

    try {
      Pattern pattern;

      if (_useRegex) {
        pattern = RegExp(query, caseSensitive: _caseSensitive, multiLine: true);
      } else {
        String escapedQuery = RegExp.escape(query);
        if (_wholeWord) {
          escapedQuery = '\\b$escapedQuery\\b';
        }
        pattern = RegExp(escapedQuery, caseSensitive: _caseSensitive);
      }

      final regExp = pattern as RegExp;
      for (final match in regExp.allMatches(text)) {
        matches.add(
          SearchMatch(
            start: match.start,
            end: match.end,
            text: match.group(0) ?? '',
          ),
        );
      }
    } catch (e) {
    }

    setState(() {
      _matches = matches;
      if (matches.isNotEmpty && _currentMatchIndex < 0) {
        _currentMatchIndex = 0;
      } else if (matches.isEmpty) {
        _currentMatchIndex = -1;
      } else if (_currentMatchIndex >= matches.length) {
        _currentMatchIndex = matches.length - 1;
      }
    });

    widget.onMatchesChanged?.call(matches);
    _highlightCurrentMatch();
  }

  void _highlightCurrentMatch() {
    if (_currentMatchIndex < 0 || _currentMatchIndex >= _matches.length) return;

    final match = _matches[_currentMatchIndex];
    widget.editorController.selection = TextSelection(
      baseOffset: match.start,
      extentOffset: match.end,
    );
  }

  void _nextMatch() {
    if (_matches.isEmpty) return;
    setState(() {
      _currentMatchIndex = (_currentMatchIndex + 1) % _matches.length;
    });
    _highlightCurrentMatch();
  }

  void _previousMatch() {
    if (_matches.isEmpty) return;
    setState(() {
      _currentMatchIndex =
          (_currentMatchIndex - 1 + _matches.length) % _matches.length;
    });
    _highlightCurrentMatch();
  }

  void _replaceCurrent() {
    if (_currentMatchIndex < 0 || _currentMatchIndex >= _matches.length) return;

    final match = _matches[_currentMatchIndex];
    final text = widget.editorController.text;
    final replacement = _replaceController.text;

    final newText = text.replaceRange(match.start, match.end, replacement);
    widget.editorController.text = newText;

    widget.editorController.selection = TextSelection.collapsed(
      offset: match.start + replacement.length,
    );

  
  }

  void _replaceAll() {
    if (_matches.isEmpty) return;

    final query = _searchController.text;
    final replacement = _replaceController.text;
    final text = widget.editorController.text;

    String newText;
    try {
      if (_useRegex) {
        final regex = RegExp(
          query,
          caseSensitive: _caseSensitive,
          multiLine: true,
        );
        newText = text.replaceAll(regex, replacement);
      } else {
        String escapedQuery = RegExp.escape(query);
        if (_wholeWord) {
          escapedQuery = '\\b$escapedQuery\\b';
        }
        final regex = RegExp(escapedQuery, caseSensitive: _caseSensitive);
        newText = text.replaceAll(regex, replacement);
      }

      widget.editorController.text = newText;
      _search();
    } catch (e) {
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border, width: 1)),
      ),
      padding: const EdgeInsets.all(8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildSearchRow(),

          if (_showReplace) ...[const SizedBox(height: 6), _buildReplaceRow()],
        ],
      ),
    );
  }

  Widget _buildSearchRow() {
    return Row(
      children: [
        _buildIconButton(
          _showReplace ? Iconsax.arrow_up_2 : Iconsax.arrow_down_1,
          () => setState(() => _showReplace = !_showReplace),
          tooltip: 'Toggle Replace',
        ),

        const SizedBox(width: 6),

        Expanded(
          child: Container(
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: AppColors.border),
            ),
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocus,
              style: TextStyle(fontSize: 13, color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: 'Search...',
                hintStyle: TextStyle(color: AppColors.textMuted),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 8,
                ),
                isDense: true,
              ),
              onSubmitted: (_) => _nextMatch(),
            ),
          ),
        ),

        const SizedBox(width: 6),

        _buildOptionToggle('.*', _useRegex, () {
          setState(() => _useRegex = !_useRegex);
          _search();
        }, tooltip: 'Regex'),
        _buildOptionToggle('Aa', _caseSensitive, () {
          setState(() => _caseSensitive = !_caseSensitive);
          _search();
        }, tooltip: 'Case Sensitive'),
        _buildOptionToggle('W', _wholeWord, () {
          setState(() => _wholeWord = !_wholeWord);
          _search();
        }, tooltip: 'Whole Word'),

        const SizedBox(width: 8),

        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Text(
            _matches.isEmpty
                ? 'No results'
                : '${_currentMatchIndex + 1}/${_matches.length}',
            style: TextStyle(
              fontSize: 12,
              color: _matches.isEmpty
                  ? AppColors.error
                  : AppColors.textSecondary,
            ),
          ),
        ),

        _buildIconButton(
          Iconsax.arrow_up_2,
          _previousMatch,
          tooltip: 'Previous',
        ),
        _buildIconButton(Iconsax.arrow_down_1, _nextMatch, tooltip: 'Next'),
        _buildIconButton(
          Iconsax.close_circle,
          widget.onClose,
          tooltip: 'Close',
        ),
      ],
    );
  }

  Widget _buildReplaceRow() {
    return Row(
      children: [
        const SizedBox(width: 32),

        const SizedBox(width: 6),

        Expanded(
          child: Container(
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: AppColors.border),
            ),
            child: TextField(
              controller: _replaceController,
              style: TextStyle(fontSize: 13, color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: 'Replace...',
                hintStyle: TextStyle(color: AppColors.textMuted),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 8,
                ),
                isDense: true,
              ),
              onSubmitted: (_) => _replaceCurrent(),
            ),
          ),
        ),

        const SizedBox(width: 8),

        _buildTextButton('Replace', _replaceCurrent),
        const SizedBox(width: 4),
        _buildTextButton('All', _replaceAll),
      ],
    );
  }

  Widget _buildIconButton(
    IconData icon,
    VoidCallback onTap, {
    String? tooltip,
  }) {
    return Tooltip(
      message: tooltip ?? '',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(icon, size: 16, color: AppColors.textSecondary),
        ),
      ),
    );
  }

  Widget _buildOptionToggle(
    String label,
    bool isActive,
    VoidCallback onTap, {
    String? tooltip,
  }) {
    return Tooltip(
      message: tooltip ?? label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          decoration: BoxDecoration(
            color: isActive ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isActive ? AppColors.background : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextButton(String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: AppColors.border),
        ),
        child: Text(
          label,
          style: TextStyle(fontSize: 12, color: AppColors.textPrimary),
        ),
      ),
    );
  }
}
class SearchMatch {
  final int start;
  final int end;
  final String text;

  SearchMatch({required this.start, required this.end, required this.text});

  int get length => end - start;
}
