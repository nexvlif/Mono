import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../core/themes/app_colors.dart';
import '../../services/terminal_service.dart';

class TerminalPanel extends StatefulWidget {
  final double height;
  final String? workingDirectory;
  final bool isExpanded;
  final VoidCallback onToggle;
  final Function(double) onResize;

  const TerminalPanel({
    super.key,
    required this.height,
    this.workingDirectory,
    required this.isExpanded,
    required this.onToggle,
    required this.onResize,
  });

  @override
  State<TerminalPanel> createState() => _TerminalPanelState();
}

class _TerminalPanelState extends State<TerminalPanel> {
  final TerminalService _terminalService = TerminalService.instance;
  final TextEditingController _inputController = TextEditingController();
  final FocusNode _inputFocusNode = FocusNode();
  final ScrollController _outputScrollController = ScrollController();

  final List<TerminalOutput> _outputs = [];
  bool _isExecuting = false;
  final List<String> _commandHistory = [];
  int _historyIndex = -1;

  @override
  void initState() {
    super.initState();
    _initTerminal();
  }

  Future<void> _initTerminal() async {
    await _terminalService.initialize();
    _writeWelcome();
  }

  void _writeWelcome() {
    _addOutput(
      '╭─────────────────────────────────────╮\n'
      '│  Mono Terminal                      │\n'
      '│  Type commands to execute           │\n'
      '╰─────────────────────────────────────╯\n',
      type: OutputType.info,
    );

    if (_terminalService.isTermuxAvailable) {
      _addOutput('✓ Termux detected\n', type: OutputType.success);
    } else {
      _addOutput(
        '⚠ Termux not found - using Android shell\n',
        type: OutputType.warning,
      );
    }

    _addPrompt();
  }

  void _addOutput(String text, {OutputType type = OutputType.normal}) {
    setState(() {
      _outputs.add(TerminalOutput(text: text, type: type));
    });
    _scrollToBottom();
  }

  void _addPrompt() {
    final dir = widget.workingDirectory?.split('/').last ?? '~';
    _addOutput('\n\$ $dir > ', type: OutputType.prompt);
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_outputScrollController.hasClients) {
        _outputScrollController.animateTo(
          _outputScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 100),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _executeCommand(String command) async {
    _inputController.clear();
    if (command.trim().isEmpty) {
      _addPrompt();
      return;
    }

    setState(() {
      _isExecuting = true;
    });

    _commandHistory.add(command);
    _historyIndex = _commandHistory.length;

    _addOutput('$command\n', type: OutputType.command);

    if (command == 'clear' || command == 'cls') {
      setState(() {
        _outputs.clear();
      });
      _addPrompt();
      setState(() => _isExecuting = false);
      return;
    }

    if (command == 'exit') {
      widget.onToggle();
      setState(() => _isExecuting = false);
      return;
    }

    if (command == 'monofetch') {
      _addOutput('''
  __  __
 |  \\/  | ___  _ __   ___
 | |\\/| |/ _ \\| '_ \\ / _ \\
 | |  | | (_) | | | | (_) |
 |_|  |_|\\___/|_| |_|\\___/

 Mono (Lia) v1.0.0 ALPHA
 -----------------
 OS: Android / Linux
 Shell: Mono Shell
 UI: Flutter
 Code Project: Lia
''', type: OutputType.info);
      _addPrompt();
      setState(() => _isExecuting = false);
      return;
    }

    try {
      final result = await _terminalService.executeCommand(
        command,
        workingDirectory: widget.workingDirectory,
      );

      if (result.stdout.isNotEmpty) {
        _addOutput(result.stdout, type: OutputType.normal);
      }
      if (result.stderr.isNotEmpty) {
        _addOutput(result.stderr, type: OutputType.error);
      }
      if (!result.isSuccess && result.stdout.isEmpty && result.stderr.isEmpty) {
        _addOutput(
          'Command failed with exit code ${result.exitCode}\n',
          type: OutputType.error,
        );
      }
    } catch (e) {
      _addOutput('Error: $e\n', type: OutputType.error);
    }

    _addPrompt();
    setState(() => _isExecuting = false);
    _inputController.clear();
  }

  void _handleKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
        if (_historyIndex > 0) {
          _historyIndex--;
          _inputController.text = _commandHistory[_historyIndex];
          _inputController.selection = TextSelection.fromPosition(
            TextPosition(offset: _inputController.text.length),
          );
        }
      }
      else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
        if (_historyIndex < _commandHistory.length - 1) {
          _historyIndex++;
          _inputController.text = _commandHistory[_historyIndex];
        } else {
          _historyIndex = _commandHistory.length;
          _inputController.clear();
        }
      }
    }
  }

  @override
  void dispose() {
    _inputController.dispose();
    _inputFocusNode.dispose();
    _outputScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isExpanded) {
      return _buildCollapsedBar();
    }

    return GestureDetector(
      onVerticalDragUpdate: (details) {
        final newHeight = widget.height - details.delta.dy;
        if (newHeight >= 100 && newHeight <= 500) {
          widget.onResize(newHeight);
        }
      },
      child: Container(
        height: widget.height,
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.terminalBg,
          border: Border(top: BorderSide(color: AppColors.border, width: 1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(),
            Expanded(child: _buildTerminalOutput()),
            _buildInput(),
          ],
        ),
      ),
    );
  }

  Widget _buildCollapsedBar() {
    return GestureDetector(
      onTap: widget.onToggle,
      child: Container(
        height: 32,
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          border: Border(top: BorderSide(color: AppColors.border, width: 1)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            Icon(Iconsax.arrow_up_2, size: 14, color: AppColors.textMuted),
            const SizedBox(width: 8),
            Text(
              'TERMINAL',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
                letterSpacing: 0.5,
              ),
            ),
            if (_isExecuting) ...[
              const SizedBox(width: 8),
              SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.primary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      height: 32,
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        border: Border(bottom: BorderSide(color: AppColors.border, width: 1)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 200;
          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Row(
                  children: [
                    const SizedBox(width: 12),
                    Icon(Iconsax.code, size: 14, color: AppColors.textSecondary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'TERMINAL',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    if (_terminalService.isTermuxAvailable && !isNarrow) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Termux',
                          style: TextStyle(fontSize: 10, color: AppColors.success),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!isNarrow) ...[
                    _buildHeaderAction(Iconsax.trash, () {
                      setState(() => _outputs.clear());
                      _addPrompt();
                    }),
                    _buildHeaderAction(Iconsax.add, () {
                      
                    }),
                  ],
                  _buildHeaderAction(
                    widget.isExpanded ? Iconsax.arrow_down_1 : Iconsax.arrow_up_2,
                    widget.onToggle,
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeaderAction(IconData icon, VoidCallback onTap) {
    return SizedBox(
      width: 28,
      height: 28,
      child: IconButton(
        onPressed: onTap,
        icon: Icon(icon, size: 14, color: AppColors.textSecondary),
        padding: EdgeInsets.zero,
        splashRadius: 16,
        tooltip: '',
      ),
    );
  }

  Widget _buildTerminalOutput() {
    return Container(
      color: AppColors.terminalBg,
      child: ListView.builder(
        controller: _outputScrollController,
        padding: const EdgeInsets.all(8),
        itemCount: _outputs.length,
        itemBuilder: (context, index) {
          final output = _outputs[index];
          return SelectableText(
            output.text,
            style: GoogleFonts.jetBrainsMono(
              fontSize: 13,
              height: 1.4,
              color: output.color,
            ),
          );
        },
      ),
    );
  }

  Widget _buildInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border, width: 1)),
      ),
      child: Row(
        children: [
          Text(
            '\$',
            style: GoogleFonts.jetBrainsMono(
              fontSize: 13,
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: KeyboardListener(
              focusNode: FocusNode(),
              onKeyEvent: _handleKeyEvent,
              child: TextField(
                controller: _inputController,
                focusNode: _inputFocusNode,
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 13,
                  color: AppColors.terminalFg,
                ),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                  hintText: 'Enter command...',
                  hintStyle: GoogleFonts.jetBrainsMono(
                    fontSize: 13,
                    color: AppColors.textMuted,
                  ),
                ),
                onSubmitted: _executeCommand,
                enabled: !_isExecuting,
              ),
            ),
          ),
          if (_isExecuting)
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.primary,
              ),
            )
          else
            IconButton(
              onPressed: () => _executeCommand(_inputController.text),
              icon: Icon(Iconsax.send_1, size: 16),
              color: AppColors.primary,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
            ),
        ],
      ),
    );
  }
}

class TerminalOutput {
  final String text;
  final OutputType type;

  TerminalOutput({required this.text, this.type = OutputType.normal});

  Color get color {
    switch (type) {
      case OutputType.normal:
        return AppColors.terminalFg;
      case OutputType.command:
        return AppColors.primary;
      case OutputType.error:
        return AppColors.error;
      case OutputType.success:
        return AppColors.success;
      case OutputType.warning:
        return AppColors.warning;
      case OutputType.info:
        return AppColors.textSecondary;
      case OutputType.prompt:
        return AppColors.textMuted;
    }
  }
}

enum OutputType { normal, command, error, success, warning, info, prompt }
