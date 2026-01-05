import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../core/themes/app_colors.dart';
import '../../models/editor_tab.dart';
import '../../services/diagnostics_service.dart';
import '../../services/emmet_service.dart';
import 'keyboard_toolbar.dart';
import 'search_replace_panel.dart';

class CodeEditor extends StatefulWidget {
  final EditorTab? tab;
  final Function(String) onContentChanged;
  final VoidCallback? onSave;
  final VoidCallback? onRun;

  const CodeEditor({
    super.key,
    this.tab,
    required this.onContentChanged,
    this.onSave,
    this.onRun,
  });

  @override
  State<CodeEditor> createState() => _CodeEditorState();
}

class _CodeEditorState extends State<CodeEditor> {
  late TextEditingController _controller;
  late ScrollController _editorScrollController;
  late ScrollController _lineNumberScrollController;
  final FocusNode _focusNode = FocusNode();

  int _lineCount = 1;
  bool _showSearch = false;
  List<Diagnostic> _diagnostics = [];

  final DiagnosticsService _diagnosticsService = DiagnosticsService.instance;
  final EmmetService _emmetService = EmmetService.instance;

  final List<String> _undoStack = [];
  final List<String> _redoStack = [];
  String _lastContent = '';

  @override
  void initState() {
    super.initState();
    _initController();
  }

  void _initController() {
    _controller = TextEditingController(text: widget.tab?.content ?? '');
    _editorScrollController = ScrollController();
    _lineNumberScrollController = ScrollController();
    _lastContent = _controller.text;
    _updateLineCount();
    _runDiagnostics();

    _controller.addListener(_onTextChanged);

    _editorScrollController.addListener(_syncScroll);
  }

  void _syncScroll() {
    if (_lineNumberScrollController.hasClients &&
        _editorScrollController.hasClients) {
      _lineNumberScrollController.jumpTo(_editorScrollController.offset);
    }
  }

  void _onTextChanged() {
    final newContent = _controller.text;
    widget.onContentChanged(newContent);
    _updateLineCount();

    if (newContent != _lastContent) {
      if (_lastContent.isNotEmpty) {
        _undoStack.add(_lastContent);
        if (_undoStack.length > 100) {
          _undoStack.removeAt(0);
        }
        _redoStack.clear();
      }
      _lastContent = newContent;
    }

    _runDiagnostics();
  }

  void _updateLineCount() {
    final newCount = '\n'.allMatches(_controller.text).length + 1;
    if (newCount != _lineCount) {
      setState(() {
        _lineCount = newCount;
      });
    }
  }

  void _runDiagnostics() {
    if (widget.tab == null) return;

    final diagnostics = _diagnosticsService.analyze(
      _controller.text,
      widget.tab!.language,
    );

    setState(() {
      _diagnostics = diagnostics;
    });
  }

  void _expandEmmet() {
    if (widget.tab == null) return;

    final text = _controller.text;
    final cursorPos = _controller.selection.baseOffset;

    int wordStart = cursorPos - 1;
    while (wordStart >= 0 && _isEmmetChar(text[wordStart])) {
      wordStart--;
    }
    wordStart++;

    if (wordStart >= cursorPos) return;

    final abbr = text.substring(wordStart, cursorPos);
    final expanded = _emmetService.expand(abbr, widget.tab!.language);

    if (expanded != null) {
      final newText = text.replaceRange(wordStart, cursorPos, expanded);
      _controller.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: wordStart + expanded.length),
      );
      _focusNode.requestFocus();
    }
  }

  bool _isEmmetChar(String char) {
    final code = char.codeUnitAt(0);
    return (code >= 65 && code <= 90) ||
        (code >= 97 && code <= 122) ||
        (code >= 48 && code <= 57) ||
        '.#>+*[]{}()!:@-_\$'.contains(char);
  }

  void _undo() {
    if (_undoStack.isEmpty) return;

    _redoStack.add(_controller.text);
    final previous = _undoStack.removeLast();

    _controller.removeListener(_onTextChanged);
    _controller.text = previous;
    _lastContent = previous;
    _controller.addListener(_onTextChanged);

    widget.onContentChanged(previous);
    _updateLineCount();
  }

  void _redo() {
    if (_redoStack.isEmpty) return;

    _undoStack.add(_controller.text);
    final next = _redoStack.removeLast();

    _controller.removeListener(_onTextChanged);
    _controller.text = next;
    _lastContent = next;
    _controller.addListener(_onTextChanged);

    widget.onContentChanged(next);
    _updateLineCount();
  }

  @override
  void didUpdateWidget(CodeEditor oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.tab?.path != widget.tab?.path) {
      _controller.removeListener(_onTextChanged);
      _controller.text = widget.tab?.content ?? '';
      _lastContent = _controller.text;
      _undoStack.clear();
      _redoStack.clear();
      _controller.addListener(_onTextChanged);
      _updateLineCount();
      _runDiagnostics();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _editorScrollController.dispose();
    _lineNumberScrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.tab == null) {
      return _buildEmptyState();
    }

    return Container(
      color: AppColors.background,
      child: Column(
        children: [
          if (_showSearch)
            SearchReplacePanel(
              editorController: _controller,
              showReplace: false,
              onClose: () => setState(() => _showSearch = false),
            ),

          if (_diagnostics.isNotEmpty) _buildDiagnosticsBar(),

          Expanded(child: _buildEditor()),

          KeyboardToolbar(
            controller: _controller,
            focusNode: _focusNode,
            onUndo: _undo,
            onRedo: _redo,
            onSave: widget.onSave,
            onSearch: () => setState(() => _showSearch = !_showSearch),
            onRun: widget.onRun,
            onEmmetExpand: _expandEmmet,
          ),
        ],
      ),
    );
  }

  Widget _buildDiagnosticsBar() {
    final errors = _diagnostics
        .where((d) => d.severity == DiagnosticSeverity.error)
        .length;
    final warnings = _diagnostics
        .where((d) => d.severity == DiagnosticSeverity.warning)
        .length;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border, width: 1)),
      ),
      child: Row(
        children: [
          if (errors > 0) ...[
            Icon(Iconsax.close_circle, size: 14, color: AppColors.error),
            const SizedBox(width: 4),
            Text(
              '$errors errors',
              style: TextStyle(fontSize: 12, color: AppColors.error),
            ),
            const SizedBox(width: 12),
          ],
          if (warnings > 0) ...[
            Icon(Iconsax.warning_2, size: 14, color: AppColors.warning),
            const SizedBox(width: 4),
            Text(
              '$warnings warnings',
              style: TextStyle(fontSize: 12, color: AppColors.warning),
            ),
          ],
          const Spacer(),
          GestureDetector(
            onTap: _showDiagnosticsList,
            child: Text(
              'View all',
              style: TextStyle(fontSize: 12, color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  void _showDiagnosticsList() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      builder: (context) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.5,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Text(
                      'Problems',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(Iconsax.close_circle, size: 20),
                      color: AppColors.textSecondary,
                    ),
                  ],
                ),
              ),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _diagnostics.length,
                  itemBuilder: (context, index) {
                    final diag = _diagnostics[index];
                    return ListTile(
                      leading: Container(
                        width: 24,
                        height: 24,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Color(diag.colorValue).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          diag.icon,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                      title: Text(
                        diag.message,
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      subtitle: Text(
                        'Line ${diag.line}, Column ${diag.column}',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textMuted,
                        ),
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        _goToLine(diag.line - 1);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _goToLine(int lineIndex) {
    final lines = _controller.text.split('\n');
    int offset = 0;
    for (int i = 0; i < lineIndex && i < lines.length; i++) {
      offset += lines[i].length + 1;
    }
    _controller.selection = TextSelection.collapsed(offset: offset);
    _focusNode.requestFocus();
  }

  Widget _buildEditor() {
    return Shortcuts(
      shortcuts: {
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyS):
            const SaveIntent(),
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyZ):
            const UndoIntent(),
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyY):
            const RedoIntent(),
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyF):
            const SearchIntent(),
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyA):
            const SelectAllIntent(),
        LogicalKeySet(LogicalKeyboardKey.tab): const EmmetIntent(),
      },
      child: Actions(
        actions: {
          SaveIntent: CallbackAction<SaveIntent>(
            onInvoke: (_) {
              widget.onSave?.call();
              return null;
            },
          ),
          UndoIntent: CallbackAction<UndoIntent>(
            onInvoke: (_) {
              _undo();
              return null;
            },
          ),
          RedoIntent: CallbackAction<RedoIntent>(
            onInvoke: (_) {
              _redo();
              return null;
            },
          ),
          SearchIntent: CallbackAction<SearchIntent>(
            onInvoke: (_) {
              setState(() => _showSearch = !_showSearch);
              return null;
            },
          ),
          SelectAllIntent: CallbackAction<SelectAllIntent>(
            onInvoke: (_) {
              _controller.selection = TextSelection(
                baseOffset: 0,
                extentOffset: _controller.text.length,
              );
              return null;
            },
          ),
          EmmetIntent: CallbackAction<EmmetIntent>(
            onInvoke: (_) {
              _expandEmmet();
              return null;
            },
          ),
        },
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(width: 50, child: _buildLineNumbers()),
                Expanded(child: _buildCodeField()),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildLineNumbers() {
    const lineHeight = 24.0;

    return Container(
      color: AppColors.lineNumberBg,
      child: ListView.builder(
        controller: _lineNumberScrollController,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _lineCount,
        itemExtent: lineHeight,
        itemBuilder: (context, index) {
          final lineNum = index + 1;
          final hasError = _diagnostics.any(
            (d) => d.line == lineNum && d.severity == DiagnosticSeverity.error,
          );
          final hasWarning = _diagnostics.any(
            (d) =>
                d.line == lineNum && d.severity == DiagnosticSeverity.warning,
          );

          return Container(
            height: lineHeight,
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 8, left: 4),
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(
                  width: 3,
                  color: hasError
                      ? AppColors.error
                      : hasWarning
                      ? AppColors.warning
                      : Colors.transparent,
                ),
              ),
            ),
            child: Text(
              '$lineNum',
              style: GoogleFonts.jetBrainsMono(
                fontSize: 13,
                height: 1.0,
                color: hasError
                    ? AppColors.error
                    : hasWarning
                    ? AppColors.warning
                    : AppColors.lineNumberFg,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCodeField() {
    const lineHeight = 24.0;

    return SingleChildScrollView(
      controller: _editorScrollController,
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: _lineCount * lineHeight + 100),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minWidth: MediaQuery.of(context).size.width,
            ),
            child: SizedBox(
              width: 5000,
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                maxLines: null,
                keyboardType: TextInputType.multiline,
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 14,
                  height: lineHeight / 14,
                  color: AppColors.textPrimary,
                ),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 0,
                  ),
                  hintText: 'Start typing...',
                  hintStyle: GoogleFonts.jetBrainsMono(
                    fontSize: 14,
                    color: AppColors.textMuted,
                  ),
                ),
                cursorColor: AppColors.primary,
                cursorWidth: 2,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      color: AppColors.background,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.code_rounded,
              size: 64,
              color: AppColors.textMuted.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No file open',
              style: GoogleFonts.inter(
                fontSize: 16,
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Select a file from the explorer',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppColors.textMuted.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
class SaveIntent extends Intent {
  const SaveIntent();
}

class UndoIntent extends Intent {
  const UndoIntent();
}

class RedoIntent extends Intent {
  const RedoIntent();
}

class SearchIntent extends Intent {
  const SearchIntent();
}

class EmmetIntent extends Intent {
  const EmmetIntent();
}

class SelectAllIntent extends Intent {
  const SelectAllIntent();
}
