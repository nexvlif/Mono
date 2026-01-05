class EmmetService {
  static EmmetService? _instance;
  static EmmetService get instance => _instance ??= EmmetService._();
  EmmetService._();

  bool isEmmetAbbreviation(String text, String language) {
    if (text.isEmpty) return false;

    if (![
      'html',
      'css',
      'scss',
      'jsx',
      'tsx',
      'vue',
    ].contains(language.toLowerCase())) {
      return false;
    }

    if (language == 'css' || language == 'scss') {
      return _cssAbbreviations.containsKey(text) ||
          RegExp(r'^[a-z]+\d*$').hasMatch(text);
    }

    return RegExp(
      r'^[a-z!][a-z0-9]*([.#>\+\*\[\]{}()@\-:]|[a-z0-9])*$',
      caseSensitive: false,
    ).hasMatch(text);
  }


  String? expand(String abbreviation, String language) {
    if (abbreviation.isEmpty) return null;

    try {
      if (language == 'css' || language == 'scss') {
        return _expandCss(abbreviation);
      }
      return _expandHtml(abbreviation);
    } catch (e) {
      return null;
    }
  }


  String _expandHtml(String abbr) {
    if (_htmlSnippets.containsKey(abbr)) {
      return _htmlSnippets[abbr]!;
    }

    return _parseHtmlAbbr(abbr);
  }

  String _parseHtmlAbbr(String abbr) {
    final result = StringBuffer();

    final multiMatch = RegExp(r'^(.+)\*(\d+)$').firstMatch(abbr);
    if (multiMatch != null) {
      final base = multiMatch.group(1)!;
      final count = int.parse(multiMatch.group(2)!);
      for (int i = 0; i < count; i++) {
        result.write(_parseHtmlAbbr(base.replaceAll('\$', '${i + 1}')));
        if (i < count - 1) result.write('\n');
      }
      return result.toString();
    }

    if (abbr.contains('+')) {
      final parts = _splitOnOperator(abbr, '+');
      for (int i = 0; i < parts.length; i++) {
        result.write(_parseHtmlAbbr(parts[i]));
        if (i < parts.length - 1) result.write('\n');
      }
      return result.toString();
    }

    if (abbr.contains('>')) {
      final parts = _splitOnOperator(abbr, '>');
      String inner = '';
      for (int i = parts.length - 1; i >= 0; i--) {
        inner = _buildTag(parts[i], inner);
      }
      return inner;
    }

    if (abbr.startsWith('(') && abbr.endsWith(')')) {
      return _parseHtmlAbbr(abbr.substring(1, abbr.length - 1));
    }

    return _buildTag(abbr, '');
  }

  List<String> _splitOnOperator(String abbr, String op) {
    final parts = <String>[];
    int depth = 0;
    int start = 0;

    for (int i = 0; i < abbr.length; i++) {
      final char = abbr[i];
      if (char == '(' || char == '[' || char == '{') depth++;
      if (char == ')' || char == ']' || char == '}') depth--;
      if (char == op && depth == 0) {
        parts.add(abbr.substring(start, i));
        start = i + 1;
      }
    }
    parts.add(abbr.substring(start));
    return parts;
  }

  String _buildTag(String abbr, String content) {
    String tagName = 'div';
    final classes = <String>[];
    String? id;
    final attributes = <String, String>{};
    String? text;

    final textMatch = RegExp(r'\{([^}]*)\}').firstMatch(abbr);
    if (textMatch != null) {
      text = textMatch.group(1);
      abbr = abbr.replaceFirst(textMatch.group(0)!, '');
    }

    final attrMatches = RegExp(r'\[([^\]]+)\]').allMatches(abbr);
    for (final match in attrMatches) {
      final attrContent = match.group(1)!;
      final parts = attrContent.split('=');
      if (parts.length == 2) {
        attributes[parts[0]] = parts[1].replaceAll('"', '').replaceAll("'", '');
      } else {
        attributes[parts[0]] = '';
      }
      abbr = abbr.replaceFirst(match.group(0)!, '');
    }

    final tagMatch = RegExp(
      r'^([a-z][a-z0-9]*)?',
      caseSensitive: false,
    ).firstMatch(abbr);
    if (tagMatch != null && tagMatch.group(1) != null) {
      tagName = tagMatch.group(1)!;
      abbr = abbr.substring(tagMatch.end);
    }

    final classMatches = RegExp(r'\.([a-zA-Z0-9_-]+)').allMatches(abbr);
    for (final match in classMatches) {
      classes.add(match.group(1)!);
    }

    final idMatch = RegExp(r'#([a-zA-Z0-9_-]+)').firstMatch(abbr);
    if (idMatch != null) {
      id = idMatch.group(1);
    }

    final buffer = StringBuffer();
    buffer.write('<$tagName');

    if (id != null) {
      buffer.write(' id="$id"');
    }
    if (classes.isNotEmpty) {
      buffer.write(' class="${classes.join(' ')}"');
    }
    for (final entry in attributes.entries) {
      if (entry.value.isEmpty) {
        buffer.write(' ${entry.key}');
      } else {
        buffer.write(' ${entry.key}="${entry.value}"');
      }
    }

    if (_selfClosingTags.contains(tagName.toLowerCase())) {
      buffer.write(' />');
      return buffer.toString();
    }

    buffer.write('>');

    if (text != null) {
      buffer.write(text);
    }
    if (content.isNotEmpty) {
      if (content.contains('\n')) {
        buffer.write('\n');
        final indented = content
            .split('\n')
            .map((line) => '  $line')
            .join('\n');
        buffer.write(indented);
        buffer.write('\n');
      } else {
        buffer.write(content);
      }
    }

    buffer.write('</$tagName>');
    return buffer.toString();
  }


  String? _expandCss(String abbr) {
    if (_cssAbbreviations.containsKey(abbr)) {
      return _cssAbbreviations[abbr];
    }

    final valueMatch = RegExp(r'^([a-z]+)(\d+)([a-z%]*)$').firstMatch(abbr);
    if (valueMatch != null) {
      final prop = valueMatch.group(1)!;
      final value = valueMatch.group(2)!;
      final unit = valueMatch.group(3)!.isEmpty ? 'px' : valueMatch.group(3)!;

      if (_cssPropertyMap.containsKey(prop)) {
        return '${_cssPropertyMap[prop]}: $value$unit;';
      }
    }

    return null;
  }

  static const Set<String> _selfClosingTags = {
    'img',
    'br',
    'hr',
    'input',
    'meta',
    'link',
    'area',
    'base',
    'col',
    'embed',
    'param',
    'source',
    'track',
    'wbr',
  };

  static const Map<String, String> _htmlSnippets = {
    '!': '''<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Document</title>
</head>
<body>
  
</body>
</html>''',
    'doc': '''<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Document</title>
</head>
<body>
  
</body>
</html>''',
    'html:5': '''<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Document</title>
</head>
<body>
  
</body>
</html>''',
    'link:css': '<link rel="stylesheet" href="style.css">',
    'link:favicon': '<link rel="icon" type="image/x-icon" href="favicon.ico">',
    'script:src': '<script src=""></script>',
    'a:link': '<a href="http://"></a>',
    'a:mail': '<a href="mailto:"></a>',
    'form:get': '<form action="" method="get"></form>',
    'form:post': '<form action="" method="post"></form>',
    'input:text': '<input type="text" name="" id="">',
    'input:password': '<input type="password" name="" id="">',
    'input:email': '<input type="email" name="" id="">',
    'input:submit': '<input type="submit" value="">',
    'input:button': '<input type="button" value="">',
    'input:checkbox': '<input type="checkbox" name="" id="">',
    'input:radio': '<input type="radio" name="" id="">',
    'input:file': '<input type="file" name="" id="">',
    'input:hidden': '<input type="hidden" name="">',
    'btn': '<button type="button"></button>',
    'btn:s': '<button type="submit"></button>',
    'btn:r': '<button type="reset"></button>',
    'select': '<select name="" id=""></select>',
    'textarea': '<textarea name="" id="" cols="30" rows="10"></textarea>',
    'img': '<img src="" alt="">',
    'pic': '''<picture>
  <source srcset="">
  <img src="" alt="">
</picture>''',
    'video': '<video src="" controls></video>',
    'audio': '<audio src="" controls></audio>',
    'table+': '''<table>
  <tr>
    <td></td>
  </tr>
</table>''',
    'ol+': '''<ol>
  <li></li>
</ol>''',
    'ul+': '''<ul>
  <li></li>
</ul>''',
    'dl+': '''<dl>
  <dt></dt>
  <dd></dd>
</dl>''',
    'nav': '<nav></nav>',
    'header': '<header></header>',
    'footer': '<footer></footer>',
    'main': '<main></main>',
    'section': '<section></section>',
    'article': '<article></article>',
    'aside': '<aside></aside>',
  };

  static const Map<String, String> _cssPropertyMap = {
    'm': 'margin',
    'mt': 'margin-top',
    'mr': 'margin-right',
    'mb': 'margin-bottom',
    'ml': 'margin-left',
    'mx': 'margin-inline',
    'my': 'margin-block',
    'p': 'padding',
    'pt': 'padding-top',
    'pr': 'padding-right',
    'pb': 'padding-bottom',
    'pl': 'padding-left',
    'px': 'padding-inline',
    'py': 'padding-block',
    'w': 'width',
    'h': 'height',
    'mw': 'max-width',
    'mh': 'max-height',
    'minw': 'min-width',
    'minh': 'min-height',
    'fs': 'font-size',
    'fw': 'font-weight',
    'lh': 'line-height',
    'ls': 'letter-spacing',
    'bd': 'border',
    'bdr': 'border-radius',
    'op': 'opacity',
    'z': 'z-index',
    't': 'top',
    'r': 'right',
    'b': 'bottom',
    'l': 'left',
    'g': 'gap',
  };

  static const Map<String, String> _cssAbbreviations = {
    'd': 'display: ;',
    'dn': 'display: none;',
    'db': 'display: block;',
    'dib': 'display: inline-block;',
    'di': 'display: inline;',
    'df': 'display: flex;',
    'dg': 'display: grid;',
    'pos': 'position: ;',
    'posa': 'position: absolute;',
    'posr': 'position: relative;',
    'posf': 'position: fixed;',
    'poss': 'position: sticky;',
    'fl': 'float: left;',
    'fr': 'float: right;',
    'cl': 'clear: both;',
    'tac': 'text-align: center;',
    'tal': 'text-align: left;',
    'tar': 'text-align: right;',
    'taj': 'text-align: justify;',
    'tdn': 'text-decoration: none;',
    'tdu': 'text-decoration: underline;',
    'ttu': 'text-transform: uppercase;',
    'ttl': 'text-transform: lowercase;',
    'ttc': 'text-transform: capitalize;',
    'fwb': 'font-weight: bold;',
    'fwn': 'font-weight: normal;',
    'fsi': 'font-style: italic;',
    'bgc': 'background-color: ;',
    'bgi': 'background-image: url();',
    'bgr': 'background-repeat: ;',
    'bgp': 'background-position: ;',
    'bgs': 'background-size: ;',
    'c': 'color: ;',
    'cur': 'cursor: pointer;',
    'ov': 'overflow: ;',
    'ovh': 'overflow: hidden;',
    'ova': 'overflow: auto;',
    'ovs': 'overflow: scroll;',
    'ovv': 'overflow: visible;',
    'vis': 'visibility: ;',
    'vish': 'visibility: hidden;',
    'visv': 'visibility: visible;',
    'fxd': 'flex-direction: ;',
    'fxdr': 'flex-direction: row;',
    'fxdc': 'flex-direction: column;',
    'fxw': 'flex-wrap: wrap;',
    'jc': 'justify-content: ;',
    'jcc': 'justify-content: center;',
    'jcsb': 'justify-content: space-between;',
    'jcsa': 'justify-content: space-around;',
    'jcse': 'justify-content: space-evenly;',
    'jcfs': 'justify-content: flex-start;',
    'jcfe': 'justify-content: flex-end;',
    'ai': 'align-items: ;',
    'aic': 'align-items: center;',
    'aifs': 'align-items: flex-start;',
    'aife': 'align-items: flex-end;',
    'ais': 'align-items: stretch;',
    'ac': 'align-content: ;',
    'fg': 'flex-grow: ;',
    'fs': 'flex-shrink: ;',
    'fb': 'flex-basis: ;',
    'fx': 'flex: ;',
    'gtc': 'grid-template-columns: ;',
    'gtr': 'grid-template-rows: ;',
    'gg': 'grid-gap: ;',
    'bxs': 'box-shadow: ;',
    'bxsn': 'box-shadow: none;',
    'ts': 'transition: ;',
    'trf': 'transform: ;',
    'an': 'animation: ;',
    'whs': 'white-space: ;',
    'whsnw': 'white-space: nowrap;',
    'wob': 'word-break: ;',
    'ww': 'word-wrap: ;',
    'cnt': 'content: "";',
    'rsz': 'resize: ;',
    'us': 'user-select: none;',
    'pe': 'pointer-events: none;',
  };


  List<EmmetSuggestion> getSuggestions(String input, String language) {
    final suggestions = <EmmetSuggestion>[];

    if (input.isEmpty) return suggestions;

    if (language == 'css' || language == 'scss') {
      
      for (final entry in _cssAbbreviations.entries) {
        if (entry.key.startsWith(input)) {
          suggestions.add(
            EmmetSuggestion(
              abbreviation: entry.key,
              expansion: entry.value,
              description: 'CSS: ${entry.value.split(':').first}',
            ),
          );
        }
      }
      for (final entry in _cssPropertyMap.entries) {
        if (entry.key.startsWith(input)) {
          suggestions.add(
            EmmetSuggestion(
              abbreviation: '${entry.key}10',
              expansion: '${entry.value}: 10px;',
              description: 'CSS: ${entry.value}',
            ),
          );
        }
      }
    } else {
      // HTML suggestions
      for (final entry in _htmlSnippets.entries) {
        if (entry.key.startsWith(input)) {
          suggestions.add(
            EmmetSuggestion(
              abbreviation: entry.key,
              expansion: entry.value.length > 50
                  ? '${entry.value.substring(0, 50)}...'
                  : entry.value,
              description: 'HTML snippet',
            ),
          );
        }
      }

      // Common HTML patterns
      final commonTags = [
        'div',
        'span',
        'p',
        'a',
        'ul',
        'li',
        'h1',
        'h2',
        'h3',
        'section',
        'header',
        'footer',
        'nav',
        'main',
        'article',
      ];
      for (final tag in commonTags) {
        if (tag.startsWith(input)) {
          suggestions.add(
            EmmetSuggestion(
              abbreviation: tag,
              expansion: '<$tag></$tag>',
              description: 'HTML tag',
            ),
          );
        }
      }
    }

    return suggestions.take(10).toList();
  }
}

class EmmetSuggestion {
  final String abbreviation;
  final String expansion;
  final String description;

  EmmetSuggestion({
    required this.abbreviation,
    required this.expansion,
    required this.description,
  });
}
