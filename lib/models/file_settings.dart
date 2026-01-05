import 'dart:convert';

enum FileEncoding {
  utf8('UTF-8'),
  utf8Bom('UTF-8 with BOM'),
  utf16Le('UTF-16 LE'),
  utf16Be('UTF-16 BE'),
  ascii('ASCII'),
  latin1('ISO-8859-1');

  final String displayName;
  const FileEncoding(this.displayName);

  Encoding get encoding {
    switch (this) {
      case FileEncoding.utf8:
      case FileEncoding.utf8Bom:
        return const Utf8Codec();
      case FileEncoding.utf16Le:
      case FileEncoding.utf16Be:
        return const Utf8Codec();
      case FileEncoding.ascii:
        return const AsciiCodec();
      case FileEncoding.latin1:
        return const Latin1Codec();
    }
  }
}

enum LineEnding {
  lf('LF', '\n', 'Unix/macOS'),
  crlf('CRLF', '\r\n', 'Windows'),
  cr('CR', '\r', 'Classic Mac');

  final String symbol;
  final String char;
  final String description;
  const LineEnding(this.symbol, this.char, this.description);


  static LineEnding detect(String content) {
    if (content.contains('\r\n')) return LineEnding.crlf;
    if (content.contains('\r')) return LineEnding.cr;
    return LineEnding.lf;
  }


  String apply(String content) {
    String normalized = content.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
    return normalized.replaceAll('\n', char);
  }
}

enum IndentType {
  spaces('Spaces'),
  tabs('Tabs');

  final String displayName;
  const IndentType(this.displayName);
}

class FileSettings {
  FileEncoding encoding;
  LineEnding lineEnding;
  IndentType indentType;
  int indentSize;
  bool trimTrailingWhitespace;
  bool insertFinalNewline;
  bool detectIndentation;
  bool showInvisibleChars;
  bool normalizeUnicode;
  bool preserveBom;

  FileSettings({
    this.encoding = FileEncoding.utf8,
    this.lineEnding = LineEnding.lf,
    this.indentType = IndentType.spaces,
    this.indentSize = 2,
    this.trimTrailingWhitespace = true,
    this.insertFinalNewline = true,
    this.detectIndentation = true,
    this.showInvisibleChars = false,
    this.normalizeUnicode = false,
    this.preserveBom = false,
  });


  factory FileSettings.defaults() => FileSettings();


  factory FileSettings.fromContent(String content) {
    final settings = FileSettings();

    settings.lineEnding = LineEnding.detect(content);
    
    final lines = content.split('\n');
    int tabCount = 0;
    int spaceCount = 0;
    final spaceSizes = <int>[];

    for (final line in lines) {
      if (line.startsWith('\t')) {
        tabCount++;
      } else if (line.startsWith(' ')) {
        spaceCount++;
        
        int spaces = 0;
        for (var i = 0; i < line.length && line[i] == ' '; i++) {
          spaces++;
        }
        if (spaces > 0 && spaces <= 8) {
          spaceSizes.add(spaces);
        }
      }
    }

    settings.indentType = tabCount > spaceCount
        ? IndentType.tabs
        : IndentType.spaces;

    
    if (spaceSizes.isNotEmpty) {
      
      int gcd(int a, int b) => b == 0 ? a : gcd(b, a % b);
      int commonSize = spaceSizes.reduce((a, b) => gcd(a, b));
      if (commonSize >= 2 && commonSize <= 8) {
        settings.indentSize = commonSize;
      }
    }

    return settings;
  }

  String applyToContent(String content) {
    String result = content;
    
    if (normalizeUnicode) {
      result = _normalizeUnicode(result);
    }

    if (trimTrailingWhitespace) {
      result = result.split('\n').map((line) => line.trimRight()).join('\n');
    }
    
    result = lineEnding.apply(result);
    
    if (insertFinalNewline && !result.endsWith(lineEnding.char)) {
      result += lineEnding.char;
    }

    return result;
  }

  String _normalizeUnicode(String content) {
    
    return content
        .replaceAll('\u00A0', ' ') 
        .replaceAll('\u2028', '\n') 
        .replaceAll('\u2029', '\n') 
        .replaceAll('\u200B', '') 
        .replaceAll('\uFEFF', ''); 
  }

  String get indentString {
    return indentType == IndentType.tabs ? '\t' : ' ' * indentSize;
  }

  FileSettings copyWith({
    FileEncoding? encoding,
    LineEnding? lineEnding,
    IndentType? indentType,
    int? indentSize,
    bool? trimTrailingWhitespace,
    bool? insertFinalNewline,
    bool? detectIndentation,
    bool? showInvisibleChars,
    bool? normalizeUnicode,
    bool? preserveBom,
  }) {
    return FileSettings(
      encoding: encoding ?? this.encoding,
      lineEnding: lineEnding ?? this.lineEnding,
      indentType: indentType ?? this.indentType,
      indentSize: indentSize ?? this.indentSize,
      trimTrailingWhitespace:
          trimTrailingWhitespace ?? this.trimTrailingWhitespace,
      insertFinalNewline: insertFinalNewline ?? this.insertFinalNewline,
      detectIndentation: detectIndentation ?? this.detectIndentation,
      showInvisibleChars: showInvisibleChars ?? this.showInvisibleChars,
      normalizeUnicode: normalizeUnicode ?? this.normalizeUnicode,
      preserveBom: preserveBom ?? this.preserveBom,
    );
  }

  Map<String, dynamic> toJson() => {
    'encoding': encoding.name,
    'lineEnding': lineEnding.name,
    'indentType': indentType.name,
    'indentSize': indentSize,
    'trimTrailingWhitespace': trimTrailingWhitespace,
    'insertFinalNewline': insertFinalNewline,
    'detectIndentation': detectIndentation,
    'showInvisibleChars': showInvisibleChars,
    'normalizeUnicode': normalizeUnicode,
    'preserveBom': preserveBom,
  };

  factory FileSettings.fromJson(Map<String, dynamic> json) {
    return FileSettings(
      encoding: FileEncoding.values.firstWhere(
        (e) => e.name == json['encoding'],
        orElse: () => FileEncoding.utf8,
      ),
      lineEnding: LineEnding.values.firstWhere(
        (e) => e.name == json['lineEnding'],
        orElse: () => LineEnding.lf,
      ),
      indentType: IndentType.values.firstWhere(
        (e) => e.name == json['indentType'],
        orElse: () => IndentType.spaces,
      ),
      indentSize: json['indentSize'] ?? 2,
      trimTrailingWhitespace: json['trimTrailingWhitespace'] ?? true,
      insertFinalNewline: json['insertFinalNewline'] ?? true,
      detectIndentation: json['detectIndentation'] ?? true,
      showInvisibleChars: json['showInvisibleChars'] ?? false,
      normalizeUnicode: json['normalizeUnicode'] ?? false,
      preserveBom: json['preserveBom'] ?? false,
    );
  }
}

class InvisibleCharDetector {
  static const Map<String, String> invisibleChars = {
    ' ': '·', 
    '\t': '→', 
    '\n': '↵', 
    '\r': '←', 
    '\u00A0': '°', 
    '\u200B': '[ZWS]', 
    '\u200C': '[ZWNJ]', 
    '\u200D': '[ZWJ]', 
    '\uFEFF': '[BOM]', 
    '\u2028': '[LS]', 
    '\u2029': '[PS]', 
  };

  static String makeVisible(String content) {
    String result = content;
    for (final entry in invisibleChars.entries) {
      result = result.replaceAll(entry.key, entry.value);
    }
    return result;
  }

  static List<InvisibleChar> findInvisible(String content) {
    final found = <InvisibleChar>[];

    for (int i = 0; i < content.length; i++) {
      final char = content[i];
      if (invisibleChars.containsKey(char) &&
          char != ' ' &&
          char != '\n' &&
          char != '\t') {
        found.add(
          InvisibleChar(position: i, char: char, name: _getCharName(char)),
        );
      }
    }

    return found;
  }

  static String _getCharName(String char) {
    switch (char) {
      case '\u00A0':
        return 'Non-breaking space';
      case '\u200B':
        return 'Zero-width space';
      case '\u200C':
        return 'Zero-width non-joiner';
      case '\u200D':
        return 'Zero-width joiner';
      case '\uFEFF':
        return 'Byte order mark';
      case '\u2028':
        return 'Line separator';
      case '\u2029':
        return 'Paragraph separator';
      default:
        return 'Unknown';
    }
  }
}

class InvisibleChar {
  final int position;
  final String char;
  final String name;

  InvisibleChar({
    required this.position,
    required this.char,
    required this.name,
  });
}
