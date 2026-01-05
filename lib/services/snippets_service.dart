class SnippetsService {
  static SnippetsService? _instance;
  static SnippetsService get instance => _instance ??= SnippetsService._();
  SnippetsService._();

  List<CodeSnippet> getSnippets(String language) {
    return _snippets[language.toLowerCase()] ?? [];
  }

  List<CodeSnippet> getAllSnippets() {
    return _snippets.values.expand((list) => list).toList();
  }

  List<CodeSnippet> findByPrefix(String prefix, String language) {
    final snippets = getSnippets(language);
    final lowercasePrefix = prefix.toLowerCase();

    return snippets
        .where(
          (s) =>
              s.prefix.toLowerCase().startsWith(lowercasePrefix) ||
              s.name.toLowerCase().contains(lowercasePrefix),
        )
        .toList();
  }

  static final Map<String, List<CodeSnippet>> _snippets = {
    'dart': [
      CodeSnippet(
        prefix: 'stful',
        name: 'Stateful Widget',
        body: '''class \${1:WidgetName} extends StatefulWidget {
  const \${1:WidgetName}({super.key});

  @override
  State<\${1:WidgetName}> createState() => _\${1:WidgetName}State();
}

class _\${1:WidgetName}State extends State<\${1:WidgetName}> {
  @override
  Widget build(BuildContext context) {
    return \${2:Container()};
  }
}''',
        description: 'Create a StatefulWidget',
      ),
      CodeSnippet(
        prefix: 'stless',
        name: 'Stateless Widget',
        body: '''class \${1:WidgetName} extends StatelessWidget {
  const \${1:WidgetName}({super.key});

  @override
  Widget build(BuildContext context) {
    return \${2:Container()};
  }
}''',
        description: 'Create a StatelessWidget',
      ),
      CodeSnippet(
        prefix: 'initstate',
        name: 'initState',
        body: '''@override
void initState() {
  super.initState();
  \${1:}
}''',
        description: 'initState method',
      ),
      CodeSnippet(
        prefix: 'dispose',
        name: 'dispose',
        body: '''@override
void dispose() {
  \${1:}
  super.dispose();
}''',
        description: 'dispose method',
      ),
      CodeSnippet(
        prefix: 'build',
        name: 'build method',
        body: '''@override
Widget build(BuildContext context) {
  return \${1:Container()};
}''',
        description: 'build method',
      ),
      CodeSnippet(
        prefix: 'future',
        name: 'Future function',
        body: '''Future<\${1:void}> \${2:functionName}() async {
  \${3:}
}''',
        description: 'Async function',
      ),
      CodeSnippet(
        prefix: 'try',
        name: 'Try-Catch',
        body: '''try {
  \${1:}
} catch (e) {
  \${2:}
}''',
        description: 'Try-catch block',
      ),
      CodeSnippet(
        prefix: 'for',
        name: 'For loop',
        body: '''for (var i = 0; i < \${1:length}; i++) {
  \${2:}
}''',
        description: 'For loop',
      ),
      CodeSnippet(
        prefix: 'forin',
        name: 'For-in loop',
        body: '''for (final \${1:item} in \${2:items}) {
  \${3:}
}''',
        description: 'For-in loop',
      ),
      CodeSnippet(
        prefix: 'if',
        name: 'If statement',
        body: '''if (\${1:condition}) {
  \${2:}
}''',
        description: 'If statement',
      ),
      CodeSnippet(
        prefix: 'ifelse',
        name: 'If-Else statement',
        body: '''if (\${1:condition}) {
  \${2:}
} else {
  \${3:}
}''',
        description: 'If-else statement',
      ),
      CodeSnippet(
        prefix: 'switch',
        name: 'Switch statement',
        body: '''switch (\${1:variable}) {
  case \${2:value}:
    \${3:}
    break;
  default:
    \${4:}
}''',
        description: 'Switch statement',
      ),
      CodeSnippet(
        prefix: 'class',
        name: 'Class',
        body: '''class \${1:ClassName} {
  \${2:}
}''',
        description: 'Class definition',
      ),
      CodeSnippet(
        prefix: 'print',
        name: 'Print',
        body: "print('\${1:message}');",
        description: 'Print statement',
      ),
      CodeSnippet(
        prefix: 'debug',
        name: 'debugPrint',
        body: "debugPrint('\${1:message}');",
        description: 'Debug print',
      ),
    ],

    'javascript': [
      CodeSnippet(
        prefix: 'fn',
        name: 'Function',
        body: '''function \${1:functionName}(\${2:params}) {
  \${3:}
}''',
        description: 'Function declaration',
      ),
      CodeSnippet(
        prefix: 'afn',
        name: 'Async Function',
        body: '''async function \${1:functionName}(\${2:params}) {
  \${3:}
}''',
        description: 'Async function',
      ),
      CodeSnippet(
        prefix: 'arrow',
        name: 'Arrow Function',
        body: '''const \${1:name} = (\${2:params}) => {
  \${3:}
};''',
        description: 'Arrow function',
      ),
      CodeSnippet(
        prefix: 'log',
        name: 'Console Log',
        body: "console.log(\${1:'message'});",
        description: 'Console log',
      ),
      CodeSnippet(
        prefix: 'trycatch',
        name: 'Try-Catch',
        body: '''try {
  \${1:}
} catch (error) {
  console.error(error);
}''',
        description: 'Try-catch block',
      ),
      CodeSnippet(
        prefix: 'for',
        name: 'For loop',
        body: '''for (let i = 0; i < \${1:length}; i++) {
  \${2:}
}''',
        description: 'For loop',
      ),
      CodeSnippet(
        prefix: 'forof',
        name: 'For-of loop',
        body: '''for (const \${1:item} of \${2:items}) {
  \${3:}
}''',
        description: 'For-of loop',
      ),
      CodeSnippet(
        prefix: 'foreach',
        name: 'forEach',
        body: '''\${1:array}.forEach((\${2:item}) => {
  \${3:}
});''',
        description: 'Array forEach',
      ),
      CodeSnippet(
        prefix: 'map',
        name: 'Array map',
        body: '''\${1:array}.map((\${2:item}) => {
  return \${3:item};
});''',
        description: 'Array map',
      ),
      CodeSnippet(
        prefix: 'filter',
        name: 'Array filter',
        body: '''\${1:array}.filter((\${2:item}) => {
  return \${3:condition};
});''',
        description: 'Array filter',
      ),
      CodeSnippet(
        prefix: 'class',
        name: 'Class',
        body: '''class \${1:ClassName} {
  constructor(\${2:params}) {
    \${3:}
  }
}''',
        description: 'Class definition',
      ),
      CodeSnippet(
        prefix: 'import',
        name: 'Import',
        body: "import { \${2:module} } from '\${1:package}';",
        description: 'Import statement',
      ),
      CodeSnippet(
        prefix: 'export',
        name: 'Export default',
        body: 'export default \${1:name};',
        description: 'Export default',
      ),
    ],

    'typescript': [
      CodeSnippet(
        prefix: 'interface',
        name: 'Interface',
        body: '''interface \${1:InterfaceName} {
  \${2:property}: \${3:type};
}''',
        description: 'Interface definition',
      ),
      CodeSnippet(
        prefix: 'type',
        name: 'Type alias',
        body: 'type \${1:TypeName} = \${2:type};',
        description: 'Type alias',
      ),
      CodeSnippet(
        prefix: 'enum',
        name: 'Enum',
        body: '''enum \${1:EnumName} {
  \${2:Value1},
  \${3:Value2},
}''',
        description: 'Enum definition',
      ),
    ],

    'python': [
      CodeSnippet(
        prefix: 'def',
        name: 'Function',
        body: '''def \${1:function_name}(\${2:params}):
    \${3:pass}''',
        description: 'Function definition',
      ),
      CodeSnippet(
        prefix: 'adef',
        name: 'Async Function',
        body: '''async def \${1:function_name}(\${2:params}):
    \${3:pass}''',
        description: 'Async function',
      ),
      CodeSnippet(
        prefix: 'class',
        name: 'Class',
        body: '''class \${1:ClassName}:
    def __init__(self\${2:, params}):
        \${3:pass}''',
        description: 'Class definition',
      ),
      CodeSnippet(
        prefix: 'if',
        name: 'If statement',
        body: '''if \${1:condition}:
    \${2:pass}''',
        description: 'If statement',
      ),
      CodeSnippet(
        prefix: 'ifelse',
        name: 'If-Else',
        body: '''if \${1:condition}:
    \${2:pass}
else:
    \${3:pass}''',
        description: 'If-else statement',
      ),
      CodeSnippet(
        prefix: 'for',
        name: 'For loop',
        body: '''for \${1:item} in \${2:items}:
    \${3:pass}''',
        description: 'For loop',
      ),
      CodeSnippet(
        prefix: 'while',
        name: 'While loop',
        body: '''while \${1:condition}:
    \${2:pass}''',
        description: 'While loop',
      ),
      CodeSnippet(
        prefix: 'try',
        name: 'Try-Except',
        body: '''try:
    \${1:pass}
except \${2:Exception} as e:
    \${3:pass}''',
        description: 'Try-except block',
      ),
      CodeSnippet(
        prefix: 'with',
        name: 'With statement',
        body: '''with \${1:expression} as \${2:variable}:
    \${3:pass}''',
        description: 'With statement',
      ),
      CodeSnippet(
        prefix: 'print',
        name: 'Print',
        body: "print(\${1:'message'})",
        description: 'Print statement',
      ),
      CodeSnippet(
        prefix: 'main',
        name: 'Main block',
        body: '''if __name__ == "__main__":
    \${1:pass}''',
        description: 'Main entry point',
      ),
    ],

    'html': [
      CodeSnippet(
        prefix: 'html5',
        name: 'HTML5 template',
        body: '''<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>\${1:Document}</title>
</head>
<body>
    \${2:}
</body>
</html>''',
        description: 'HTML5 boilerplate',
      ),
      CodeSnippet(
        prefix: 'div',
        name: 'Div',
        body: '<div class="\${1:class}">\${2:}</div>',
        description: 'Div element',
      ),
      CodeSnippet(
        prefix: 'a',
        name: 'Anchor',
        body: '<a href="\${1:url}">\${2:text}</a>',
        description: 'Anchor link',
      ),
      CodeSnippet(
        prefix: 'img',
        name: 'Image',
        body: '<img src="\${1:url}" alt="\${2:description}">',
        description: 'Image element',
      ),
      CodeSnippet(
        prefix: 'ul',
        name: 'Unordered List',
        body: '''<ul>
    <li>\${1:item}</li>
</ul>''',
        description: 'Unordered list',
      ),
      CodeSnippet(
        prefix: 'form',
        name: 'Form',
        body: '''<form action="\${1:action}" method="\${2:post}">
    \${3:}
</form>''',
        description: 'Form element',
      ),
      CodeSnippet(
        prefix: 'input',
        name: 'Input',
        body: '<input type="\${1:text}" name="\${2:name}" id="\${3:id}">',
        description: 'Input element',
      ),
      CodeSnippet(
        prefix: 'btn',
        name: 'Button',
        body: '<button type="\${1:button}">\${2:Click me}</button>',
        description: 'Button element',
      ),
    ],

    'css': [
      CodeSnippet(
        prefix: 'flex',
        name: 'Flexbox',
        body: '''display: flex;
justify-content: \${1:center};
align-items: \${2:center};''',
        description: 'Flexbox container',
      ),
      CodeSnippet(
        prefix: 'grid',
        name: 'Grid',
        body: '''display: grid;
grid-template-columns: \${1:repeat(3, 1fr)};
gap: \${2:1rem};''',
        description: 'Grid container',
      ),
      CodeSnippet(
        prefix: 'media',
        name: 'Media Query',
        body: '''@media (max-width: \${1:768px}) {
  \${2:}
}''',
        description: 'Media query',
      ),
      CodeSnippet(
        prefix: 'animation',
        name: 'Animation',
        body: '''@keyframes \${1:animationName} {
  from {
    \${2:}
  }
  to {
    \${3:}
  }
}''',
        description: 'CSS animation',
      ),
    ],
  };
}

class CodeSnippet {
  final String prefix;
  final String name;
  final String body;
  final String description;

  const CodeSnippet({
    required this.prefix,
    required this.name,
    required this.body,
    required this.description,
  });


  String expand({Map<String, String>? values}) {
    String result = body;

    if (values != null) {
      for (final entry in values.entries) {
        result = result.replaceAll('\${${entry.key}}', entry.value);
      }
    }

    final placeholderRegex = RegExp(r'\$\{(\d+):?([^}]*)\}');
    result = result.replaceAllMapped(placeholderRegex, (match) {
      return match.group(2) ?? '';
    });

    return result;
  }


  int? getFirstPlaceholderPosition(String expandedBody) {
    final match = RegExp(r'\$\{1[:\}]').firstMatch(body);
    return match?.start;
  }
}
