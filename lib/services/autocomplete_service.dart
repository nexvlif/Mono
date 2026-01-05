import 'snippets_service.dart';
import 'emmet_service.dart';
class AutocompleteService {
  static AutocompleteService? _instance;
  static AutocompleteService get instance =>
      _instance ??= AutocompleteService._();
  AutocompleteService._();

  final SnippetsService _snippets = SnippetsService.instance;
  final EmmetService _emmet = EmmetService.instance;

  List<CompletionItem> getCompletions({
    required String text,
    required int cursorPosition,
    required String language,
    int maxResults = 20,
  }) {
    
    final wordInfo = _getCurrentWord(text, cursorPosition);
    if (wordInfo == null || wordInfo.word.isEmpty) {
      return [];
    }

    final word = wordInfo.word.toLowerCase();
    final results = <CompletionItem>[];

    
    if (_emmet.isEmmetAbbreviation(wordInfo.word, language)) {
      final emmetSuggestions = _emmet.getSuggestions(wordInfo.word, language);
      for (final suggestion in emmetSuggestions) {
        results.add(
          CompletionItem(
            label: suggestion.abbreviation,
            detail: 'Emmet',
            documentation: suggestion.expansion,
            kind: CompletionItemKind.emmet,
            insertText:
                _emmet.expand(suggestion.abbreviation, language) ??
                suggestion.expansion,
            sortOrder: -1, 
          ),
        );
      }

      
      final directExpansion = _emmet.expand(wordInfo.word, language);
      if (directExpansion != null &&
          !results.any((r) => r.label == wordInfo.word)) {
        results.add(
          CompletionItem(
            label: wordInfo.word,
            detail: 'Emmet Expand',
            documentation: directExpansion.length > 100
                ? '${directExpansion.substring(0, 100)}...'
                : directExpansion,
            kind: CompletionItemKind.emmet,
            insertText: directExpansion,
            sortOrder: -2, 
          ),
        );
      }
    }

    
    final snippets = _snippets.findByPrefix(word, language);
    for (final snippet in snippets) {
      results.add(
        CompletionItem(
          label: snippet.prefix,
          detail: snippet.name,
          documentation: snippet.description,
          kind: CompletionItemKind.snippet,
          insertText: snippet.expand(),
          sortOrder: 0, 
        ),
      );
    }

    
    final keywords = _getLanguageKeywords(language);
    for (final keyword in keywords) {
      if (keyword.toLowerCase().startsWith(word)) {
        results.add(
          CompletionItem(
            label: keyword,
            kind: CompletionItemKind.keyword,
            insertText: keyword,
            sortOrder: 1,
          ),
        );
      }
    }

    
    final documentWords = _extractWords(text, minLength: 3);
    for (final docWord in documentWords) {
      final lowerWord = docWord.toLowerCase();
      if (lowerWord.startsWith(word) && lowerWord != word) {
        
        if (!results.any((r) => r.label.toLowerCase() == lowerWord)) {
          results.add(
            CompletionItem(
              label: docWord,
              kind: CompletionItemKind.text,
              insertText: docWord,
              sortOrder: 2,
            ),
          );
        }
      }
    }

    results.sort((a, b) {
      if (a.sortOrder != b.sortOrder) {
        return a.sortOrder.compareTo(b.sortOrder);
      }
      return a.label.compareTo(b.label);
    });

    return results.take(maxResults).toList();
  }

  WordInfo? _getCurrentWord(String text, int position) {
    if (position <= 0 || position > text.length) return null;

    int start = position - 1;
    while (start >= 0 && _isWordChar(text[start])) {
      start--;
    }
    start++;
    
    int end = position;
    while (end < text.length && _isWordChar(text[end])) {
      end++;
    }

    if (start >= end) return null;

    return WordInfo(
      word: text.substring(start, position),
      start: start,
      end: end,
    );
  }

  bool _isWordChar(String char) {
    final code = char.codeUnitAt(0);
    return (code >= 65 && code <= 90) || 
        (code >= 97 && code <= 122) || 
        (code >= 48 && code <= 57) || 
        char == '_' ||
        char == '\$';
  }

  Set<String> _extractWords(String text, {int minLength = 2}) {
    final wordRegex = RegExp(r'[a-zA-Z_$][a-zA-Z0-9_$]*');
    final matches = wordRegex.allMatches(text);

    return matches
        .map((m) => m.group(0)!)
        .where((w) => w.length >= minLength)
        .toSet();
  }

  List<String> _getLanguageKeywords(String language) {
    return _keywords[language.toLowerCase()] ?? [];
  }

  static const Map<String, List<String>> _keywords = {
    'dart': [
      'abstract', 'as', 'assert', 'async', 'await', 'break', 'case', 'catch',
      'class', 'const', 'continue', 'covariant', 'default', 'deferred', 'do',
      'dynamic', 'else', 'enum', 'export', 'extends', 'extension', 'external',
      'factory', 'false', 'final', 'finally', 'for', 'Function', 'get', 'hide',
      'if', 'implements', 'import', 'in', 'interface', 'is', 'late', 'library',
      'mixin', 'new', 'null', 'on', 'operator', 'part', 'required', 'rethrow',
      'return', 'set', 'show', 'static', 'super', 'switch', 'sync', 'this',
      'throw',
      'true',
      'try',
      'typedef',
      'var',
      'void',
      'while',
      'with',
      'yield',
      
      'int',
      'double',
      'String',
      'bool',
      'List',
      'Map',
      'Set',
      'Future',
      'Stream',
      'Widget', 'BuildContext', 'State', 'StatelessWidget', 'StatefulWidget',
      'Container', 'Row', 'Column', 'Text', 'Icon', 'Scaffold', 'AppBar',
      'MaterialApp', 'Navigator', 'setState', 'initState', 'dispose', 'build',
    ],

    'javascript': [
      'await', 'break', 'case', 'catch', 'class', 'const', 'continue',
      'debugger', 'default', 'delete', 'do', 'else', 'export', 'extends',
      'false', 'finally', 'for', 'function', 'if', 'import', 'in', 'instanceof',
      'let', 'new', 'null', 'return', 'static', 'super', 'switch', 'this',
      'throw', 'true', 'try', 'typeof', 'undefined', 'var', 'void', 'while',
      'with', 'yield', 'async',
      
      'console', 'document', 'window', 'fetch', 'JSON', 'Array', 'Object',
      'Promise', 'Math', 'Date', 'Map', 'Set', 'Symbol', 'RegExp',
      'setTimeout', 'setInterval', 'addEventListener', 'querySelector',
    ],

    'typescript': [
      'abstract',
      'any',
      'as',
      'asserts',
      'async',
      'await',
      'boolean',
      'break',
      'case',
      'catch',
      'class',
      'const',
      'continue',
      'declare',
      'default',
      'delete',
      'do',
      'else',
      'enum',
      'export',
      'extends',
      'false',
      'finally',
      'for',
      'from',
      'function',
      'get',
      'if',
      'implements',
      'import',
      'in',
      'infer',
      'instanceof',
      'interface',
      'is',
      'keyof',
      'let',
      'module',
      'namespace',
      'never',
      'new',
      'null',
      'number',
      'object',
      'of',
      'package',
      'private',
      'protected',
      'public',
      'readonly',
      'require',
      'return',
      'set',
      'static',
      'string',
      'super',
      'switch',
      'symbol',
      'this',
      'throw',
      'true',
      'try',
      'type',
      'typeof',
      'undefined',
      'unique',
      'unknown',
      'var',
      'void',
      'while',
      'with',
      'yield',
    ],

    'python': [
      'False', 'None', 'True', 'and', 'as', 'assert', 'async', 'await', 'break',
      'class', 'continue', 'def', 'del', 'elif', 'else', 'except', 'finally',
      'for', 'from', 'global', 'if', 'import', 'in', 'is', 'lambda', 'nonlocal',
      'not', 'or', 'pass', 'raise', 'return', 'try', 'while', 'with', 'yield',
      
      'print', 'len', 'range', 'str', 'int', 'float', 'list', 'dict', 'set',
      'tuple', 'bool', 'type', 'isinstance', 'hasattr', 'getattr', 'setattr',
      'open',
      'input',
      'map',
      'filter',
      'zip',
      'enumerate',
      'sorted',
      'reversed',
      'self', '__init__', '__main__', '__name__',
    ],

    'html': [
      'html',
      'head',
      'body',
      'div',
      'span',
      'p',
      'a',
      'img',
      'ul',
      'ol',
      'li',
      'table',
      'tr',
      'td',
      'th',
      'form',
      'input',
      'button',
      'select',
      'option',
      'textarea',
      'label',
      'header',
      'footer',
      'nav',
      'section',
      'article',
      'aside',
      'main',
      'h1',
      'h2',
      'h3',
      'h4',
      'h5',
      'h6',
      'br',
      'hr',
      'meta',
      'link',
      'script',
      'style',
      'title',
      'class',
      'id',
      'href',
      'src',
      'alt',
      'type',
      'name',
      'value',
      'placeholder',
      'required',
      'disabled',
      'checked',
    ],

    'css': [
      'display',
      'position',
      'width',
      'height',
      'margin',
      'padding',
      'border',
      'background',
      'color',
      'font',
      'text',
      'flex',
      'grid',
      'align',
      'justify',
      'overflow',
      'visibility',
      'opacity',
      'transform',
      'transition',
      'animation',
      'box-shadow',
      'border-radius',
      'z-index',
      'cursor',
      'pointer-events',
      'flex-direction',
      'flex-wrap',
      'justify-content',
      'align-items',
      'gap',
      'grid-template-columns',
      'grid-template-rows',
      'media',
      'important',
      'none',
      'block',
      'inline',
      'inline-block',
      'flex',
      'grid',
      'absolute',
      'relative',
      'fixed',
      'sticky',
      'center',
      'auto',
      'inherit',
      'initial',
    ],
  };
}
class WordInfo {
  final String word;
  final int start;
  final int end;

  WordInfo({required this.word, required this.start, required this.end});
}
enum CompletionItemKind {
  emmet,
  snippet,
  keyword,
  text,
  variable,
  function,
  className,
}
class CompletionItem {
  final String label;
  final String? detail;
  final String? documentation;
  final CompletionItemKind kind;
  final String insertText;
  final int sortOrder;

  CompletionItem({
    required this.label,
    this.detail,
    this.documentation,
    required this.kind,
    required this.insertText,
    this.sortOrder = 0,
  });

  String get icon {
    switch (kind) {
      case CompletionItemKind.emmet:
        return 'DUMMY';
      case CompletionItemKind.snippet:
        return 'DUMMY';
      case CompletionItemKind.keyword:
        return 'd';
      case CompletionItemKind.text:
        return 'd';
      case CompletionItemKind.variable:
        return 'd';
      case CompletionItemKind.function:
        return 'd';
      case CompletionItemKind.className:
        return 'd';
    }
  }
}
