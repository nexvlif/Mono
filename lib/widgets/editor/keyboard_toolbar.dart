import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../core/themes/app_colors.dart';

class KeyboardToolbar extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback? onUndo;
  final VoidCallback? onRedo;
  final VoidCallback? onSave;
  final VoidCallback? onSearch;
  final VoidCallback? onRun;
  final VoidCallback? onEmmetExpand;

  const KeyboardToolbar({
    super.key,
    required this.controller,
    required this.focusNode,
    this.onUndo,
    this.onRedo,
    this.onSave,
    this.onSearch,
    this.onRun,
    this.onEmmetExpand,
  });

  @override
  State<KeyboardToolbar> createState() => _KeyboardToolbarState();
}

class _KeyboardToolbarState extends State<KeyboardToolbar> {
  bool _isCtrlMode = false;
  bool _isShiftMode = false;
  int _currentRow = 0;
  
  static const List<List<_KeyDef>> _keyRows = [
    [
      _KeyDef('Tab', icon: Icons.keyboard_tab, isAction: true),
      _KeyDef('←', char: null, isArrow: true),
      _KeyDef('→', char: null, isArrow: true),
      _KeyDef('↑', char: null, isArrow: true),
      _KeyDef('↓', char: null, isArrow: true),
      _KeyDef('Ctrl', isModifier: true),
      _KeyDef('Shift', isModifier: true),
      _KeyDef('Esc', isAction: true),
      _KeyDef('Home', isAction: true),
      _KeyDef('End', isAction: true),
    ],
    
    [
      _KeyDef('(', char: '('),
      _KeyDef(')', char: ')'),
      _KeyDef('{', char: '{'),
      _KeyDef('}', char: '}'),
      _KeyDef('[', char: '['),
      _KeyDef(']', char: ']'),
      _KeyDef('<', char: '<'),
      _KeyDef('>', char: '>'),
      _KeyDef(';', char: ';'),
      _KeyDef(':', char: ':'),
    ],
    
    [
      _KeyDef('=', char: '='),
      _KeyDef('+', char: '+'),
      _KeyDef('-', char: '-'),
      _KeyDef('*', char: '*'),
      _KeyDef('/', char: '/'),
      _KeyDef('\\', char: '\\'),
      _KeyDef('%', char: '%'),
      _KeyDef('&', char: '&'),
      _KeyDef('|', char: '|'),
      _KeyDef('^', char: '^'),
    ],
    
    [
      _KeyDef('"', char: '"'),
      _KeyDef("'", char: "'"),
      _KeyDef('`', char: '`'),
      _KeyDef('_', char: '_'),
      _KeyDef('@', char: '@'),
      _KeyDef('#', char: '#'),
      _KeyDef('\$', char: '\$'),
      _KeyDef('!', char: '!'),
      _KeyDef('?', char: '?'),
      _KeyDef('~', char: '~'),
    ],
  ];

  void _insertText(String text) {
    final controller = widget.controller;
    final selection = controller.selection;

    if (selection.isValid) {
      final newText = controller.text.replaceRange(
        selection.start,
        selection.end,
        text,
      );
      controller.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(
          offset: selection.start + text.length,
        ),
      );
    }
    widget.focusNode.requestFocus();
  }

  void _insertTab() {
    _insertText('  '); 
  }

  void _moveCursor(String direction) {
    final controller = widget.controller;
    final text = controller.text;
    var offset = controller.selection.baseOffset;

    switch (direction) {
      case '←':
        if (offset > 0) offset--;
        break;
      case '→':
        if (offset < text.length) offset++;
        break;
      case '↑':
        
        final lines = text.substring(0, offset).split('\n');
        if (lines.length > 1) {
          final currentLineLength = lines.last.length;
          final prevLineStart = offset - currentLineLength - 1;
          final prevLineLength = lines[lines.length - 2].length;
          offset =
              prevLineStart -
              prevLineLength +
              currentLineLength.clamp(0, prevLineLength);
          offset = offset.clamp(0, text.length);
        }
        break;
      case '↓':
        
        final afterCursor = text.substring(offset);
        final newlineIndex = afterCursor.indexOf('\n');
        if (newlineIndex != -1) {
          final currentLineStart = text.lastIndexOf('\n', offset - 1) + 1;
          final currentCol = offset - currentLineStart;
          final nextLineStart = offset + newlineIndex + 1;
          final nextLineEnd = text.indexOf('\n', nextLineStart);
          final nextLineLength =
              (nextLineEnd == -1 ? text.length : nextLineEnd) - nextLineStart;
          offset = nextLineStart + currentCol.clamp(0, nextLineLength);
        }
        break;
    }

    controller.selection = TextSelection.collapsed(offset: offset);
    widget.focusNode.requestFocus();
  }

  void _moveToLineStart() {
    final controller = widget.controller;
    final text = controller.text;
    final offset = controller.selection.baseOffset;
    final lineStart = text.lastIndexOf('\n', offset - 1) + 1;
    controller.selection = TextSelection.collapsed(offset: lineStart);
    widget.focusNode.requestFocus();
  }

  void _moveToLineEnd() {
    final controller = widget.controller;
    final text = controller.text;
    final offset = controller.selection.baseOffset;
    var lineEnd = text.indexOf('\n', offset);
    if (lineEnd == -1) lineEnd = text.length;
    controller.selection = TextSelection.collapsed(offset: lineEnd);
    widget.focusNode.requestFocus();
  }

  void _selectAll() {
    final controller = widget.controller;
    controller.selection = TextSelection(
      baseOffset: 0,
      extentOffset: controller.text.length,
    );
    widget.focusNode.requestFocus();
  }

  void _handleKey(_KeyDef key) {
    if (key.isModifier) {
      setState(() {
        if (key.label == 'Ctrl') {
          _isCtrlMode = !_isCtrlMode;
          _isShiftMode = false;
        } else if (key.label == 'Shift') {
          _isShiftMode = !_isShiftMode;
          _isCtrlMode = false;
        }
      });
      return;
    }

    if (key.isArrow) {
      _moveCursor(key.label);
      return;
    }

    if (key.isAction) {
      switch (key.label) {
        case 'Tab':
          _insertTab();
          break;
        case 'Esc':
          widget.focusNode.unfocus();
          break;
        case 'Home':
          _moveToLineStart();
          break;
        case 'End':
          _moveToLineEnd();
          break;
      }
      return;
    }

    
    if (_isCtrlMode && key.char != null) {
      switch (key.char) {
        case 's':
          widget.onSave?.call();
          break;
        case 'z':
          widget.onUndo?.call();
          break;
        case 'y':
          widget.onRedo?.call();
          break;
        case 'f':
          widget.onSearch?.call();
          break;
      }
      setState(() => _isCtrlMode = false);
      return;
    }

    
    if (key.char != null) {
      String charToInsert = key.char!;
      if (_isShiftMode) {
        
        final shiftMap = {
          '1': '!',
          '2': '@',
          '3': '#',
          '4': '\$',
          '5': '%',
          '6': '^',
          '7': '&',
          '8': '*',
          '9': '(',
          '0': ')',
          '-': '_',
          '=': '+',
          '[': '{',
          ']': '}',
          '\\': '|',
          ';': ':',
          "'": '"',
          ',': '<',
          '.': '>',
          '/': '?',
          '`': '~',
        };
        charToInsert = shiftMap[key.char] ?? key.char!.toUpperCase();
      }
      _insertText(charToInsert);
      setState(() => _isShiftMode = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border, width: 1)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          
          _buildTopBar(),
          
          _buildKeyRow(_keyRows[_currentRow]),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      height: 36,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            
            for (int i = 0; i < _keyRows.length; i++)
              Padding(
                padding: const EdgeInsets.only(right: 4),
                child: _buildRowChip(i),
              ),

            const SizedBox(width: 12),
            Container(width: 1, height: 20, color: AppColors.border),
            const SizedBox(width: 12),

            
            _buildQuickAction(Iconsax.task_square, _selectAll, 'Select All'),
            _buildQuickAction(Iconsax.undo, widget.onUndo, 'Undo'),
            _buildQuickAction(Iconsax.redo, widget.onRedo, 'Redo'),
            _buildQuickAction(Iconsax.search_normal, widget.onSearch, 'Search'),
            _buildQuickAction(Iconsax.document_download, widget.onSave, 'Save'),
            _buildQuickAction(Iconsax.flash_1, widget.onEmmetExpand, 'Emmet'),
            _buildQuickAction(Iconsax.play, widget.onRun, 'Run'),
          ],
        ),
      ),
    );
  }

  Widget _buildRowChip(int index) {
    final labels = ['Nav', '( )', 'Op', '" \$'];
    final isSelected = _currentRow == index;

    return GestureDetector(
      onTap: () => setState(() => _currentRow = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          labels[index],
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: isSelected ? AppColors.background : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildQuickAction(IconData icon, VoidCallback? onTap, String tooltip) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(
            icon,
            size: 18,
            color: onTap != null
                ? AppColors.textSecondary
                : AppColors.textMuted,
          ),
        ),
      ),
    );
  }

  Widget _buildKeyRow(List<_KeyDef> keys) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: keys.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: _buildKey(keys[index]),
          );
        },
      ),
    );
  }

  Widget _buildKey(_KeyDef key) {
    final isActive =
        (key.label == 'Ctrl' && _isCtrlMode) ||
        (key.label == 'Shift' && _isShiftMode);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _handleKey(key),
        borderRadius: BorderRadius.circular(6),
        child: Container(
          constraints: const BoxConstraints(minWidth: 36),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: isActive ? AppColors.primary : AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: isActive ? AppColors.primary : AppColors.border,
              width: 1,
            ),
          ),
          child: Center(
            child: key.icon != null
                ? Icon(
                    key.icon,
                    size: 16,
                    color: isActive
                        ? AppColors.background
                        : AppColors.textPrimary,
                  )
                : Text(
                    key.label,
                    style: TextStyle(
                      fontSize: key.label.length > 2 ? 10 : 14,
                      fontWeight: FontWeight.w600,
                      color: isActive
                          ? AppColors.background
                          : AppColors.textPrimary,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

class _KeyDef {
  final String label;
  final String? char;
  final IconData? icon;
  final bool isModifier;
  final bool isArrow;
  final bool isAction;

  const _KeyDef(
    this.label, {
    this.char,
    this.icon,
    this.isModifier = false,
    this.isArrow = false,
    this.isAction = false,
  });
}
