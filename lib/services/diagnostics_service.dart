
class DiagnosticsService {
  static DiagnosticsService? _instance;
  static DiagnosticsService get instance =>
      _instance ??= DiagnosticsService._();
  DiagnosticsService._();

  List<Diagnostic> analyze(String code, String language) {
    final diagnostics = <Diagnostic>[];

    // Run all checks
    diagnostics.addAll(_checkBrackets(code));
    diagnostics.addAll(_checkStrings(code, language));
    diagnostics.addAll(_checkLanguageSpecific(code, language));

    return diagnostics;
  }

  List<Diagnostic> _checkBrackets(String code) {
    final diagnostics = <Diagnostic>[];
    final stack = <_BracketInfo>[];

    const pairs = {'(': ')', '{': '}', '[': ']'};

    const closers = {')', '}', ']'};

    bool inString = false;
    bool inSingleQuote = false;
    bool inDoubleQuote = false;
    bool inTemplate = false;
    bool escaped = false;
    int lineNumber = 1;
    int column = 1;

    for (int i = 0; i < code.length; i++) {
      final char = code[i];

      // Track line/column
      if (char == '\n') {
        lineNumber++;
        column = 1;
        continue;
      }

      // Handle escape
      if (escaped) {
        escaped = false;
        column++;
        continue;
      }

      if (char == '\\') {
        escaped = true;
        column++;
        continue;
      }

      // Track strings
      if (!inString) {
        if (char == "'" && !inDoubleQuote && !inTemplate) {
          inSingleQuote = true;
          inString = true;
        } else if (char == '"' && !inSingleQuote && !inTemplate) {
          inDoubleQuote = true;
          inString = true;
        } else if (char == '`') {
          inTemplate = true;
          inString = true;
        }
      } else {
        if (char == "'" && inSingleQuote) {
          inSingleQuote = false;
          inString = false;
        } else if (char == '"' && inDoubleQuote) {
          inDoubleQuote = false;
          inString = false;
        } else if (char == '`' && inTemplate) {
          inTemplate = false;
          inString = false;
        }
      }

      // Check brackets only outside strings
      if (!inString) {
        if (pairs.containsKey(char)) {
          stack.add(_BracketInfo(char, pairs[char]!, lineNumber, column, i));
        } else if (closers.contains(char)) {
          if (stack.isEmpty) {
            diagnostics.add(
              Diagnostic(
                message: 'Unexpected closing bracket "$char"',
                severity: DiagnosticSeverity.error,
                line: lineNumber,
                column: column,
                length: 1,
              ),
            );
          } else {
            final last = stack.removeLast();
            if (last.closer != char) {
              diagnostics.add(
                Diagnostic(
                  message:
                      'Mismatched brackets: expected "${last.closer}", found "$char"',
                  severity: DiagnosticSeverity.error,
                  line: lineNumber,
                  column: column,
                  length: 1,
                ),
              );
            }
          }
        }
      }

      column++;
    }

    // Report unclosed brackets
    for (final bracket in stack) {
      diagnostics.add(
        Diagnostic(
          message: 'Unclosed bracket "${bracket.opener}"',
          severity: DiagnosticSeverity.error,
          line: bracket.line,
          column: bracket.column,
          length: 1,
        ),
      );
    }

    return diagnostics;
  }

  List<Diagnostic> _checkStrings(String code, String language) {
    final diagnostics = <Diagnostic>[];
    final lines = code.split('\n');

    for (int lineIndex = 0; lineIndex < lines.length; lineIndex++) {
      final line = lines[lineIndex];
      bool inSingle = false;
      bool inDouble = false;
      int stringStart = -1;
      bool escaped = false;

      for (int i = 0; i < line.length; i++) {
        final char = line[i];

        if (escaped) {
          escaped = false;
          continue;
        }

        if (char == '\\') {
          escaped = true;
          continue;
        }

        // Skip comments
        if (!inSingle && !inDouble && i + 1 < line.length) {
          if (line.substring(i, i + 2) == '//') break;
        }

        if (char == "'" && !inDouble) {
          if (!inSingle) {
            inSingle = true;
            stringStart = i;
          } else {
            inSingle = false;
          }
        } else if (char == '"' && !inSingle) {
          if (!inDouble) {
            inDouble = true;
            stringStart = i;
          } else {
            inDouble = false;
          }
        }
      }

      // Multi-line strings are allowed in some languages
      final allowsMultiline = {'python', 'javascript', 'typescript', 'dart'};

      if ((inSingle || inDouble) &&
          !allowsMultiline.contains(language.toLowerCase())) {
        diagnostics.add(
          Diagnostic(
            message: 'Unclosed string',
            severity: DiagnosticSeverity.error,
            line: lineIndex + 1,
            column: stringStart + 1,
            length: line.length - stringStart,
          ),
        );
      }
    }

    return diagnostics;
  }

  List<Diagnostic> _checkLanguageSpecific(String code, String language) {
    switch (language.toLowerCase()) {
      case 'dart':
      case 'javascript':
      case 'typescript':
      case 'java':
      case 'c':
      case 'cpp':
        return _checkSemicolonLanguage(code);
      default:
        return [];
    }
  }

  List<Diagnostic> _checkSemicolonLanguage(String code) {
    final diagnostics = <Diagnostic>[];
    final lines = code.split('\n');

    // Patterns that should end with semicolon
    final shouldEndWithSemicolon = RegExp(
      r'^\s*(return|break|continue|throw|var|let|const|final)\s+.+[^;,{]\s*$',
    );

    // Patterns that shouldn't require semicolon
    final noSemicolon = RegExp(
      r'^\s*(if|else|for|while|switch|try|catch|finally|class|function|def|async)\b|^\s*[{}]\s*$|^\s*//|^\s*$',
    );

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trimRight();

      if (line.isEmpty) continue;
      if (noSemicolon.hasMatch(line)) continue;

      if (shouldEndWithSemicolon.hasMatch(line)) {
        diagnostics.add(
          Diagnostic(
            message: 'Statement may be missing a semicolon',
            severity: DiagnosticSeverity.warning,
            line: i + 1,
            column: line.length,
            length: 1,
          ),
        );
      }
    }

    return diagnostics;
  }
}

class _BracketInfo {
  final String opener;
  final String closer;
  final int line;
  final int column;
  final int position;

  _BracketInfo(this.opener, this.closer, this.line, this.column, this.position);
}
enum DiagnosticSeverity { error, warning, info, hint }
class Diagnostic {
  final String message;
  final DiagnosticSeverity severity;
  final int line;
  final int column;
  final int length;
  final String? code;
  final String? source;

  Diagnostic({
    required this.message,
    required this.severity,
    required this.line,
    required this.column,
    this.length = 1,
    this.code,
    this.source,
  });

  int get colorValue {
    switch (severity) {
      case DiagnosticSeverity.error:
        return 0xFFF85149;
      case DiagnosticSeverity.warning:
        return 0xFFD29922;
      case DiagnosticSeverity.info:
        return 0xFF58A6FF;
      case DiagnosticSeverity.hint:
        return 0xFF8B949E;
    }
  }

  String get icon {
    switch (severity) {
      case DiagnosticSeverity.error:
        return '✕';
      case DiagnosticSeverity.warning:
        return '⚠';
      case DiagnosticSeverity.info:
        return 'ℹ';
      case DiagnosticSeverity.hint:
        return 'I';
    }
  }

  @override
  String toString() => '[$severity] Line $line:$column - $message';
}
