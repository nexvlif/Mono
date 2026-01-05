class AppConstants {
  AppConstants._();

  static const String appName = 'Mono';
  static const String appVersion = '1.0.0';
  static const String appDescription = 'Mini VSCode - Code Editor for Android';
  static const double sidebarMinWidth = 200.0;
  static const double sidebarMaxWidth = 400.0;
  static const double sidebarDefaultWidth = 260.0;
  static const double terminalMinHeight = 100.0;
  static const double terminalMaxHeight = 500.0;
  static const double terminalDefaultHeight = 200.0;
  static const double tabHeight = 36.0;
  static const double lineNumberWidth = 50.0;
  static const double editorFontSize = 14.0;
  static const String editorFontFamily = 'JetBrains Mono';
  static const Duration animFast = Duration(milliseconds: 150);
  static const Duration animMedium = Duration(milliseconds: 300);
  static const Duration animSlow = Duration(milliseconds: 500);
  static const Map<String, String> extensionToLanguage = {
    'dart': 'dart',
    'py': 'python',
    'js': 'javascript',
    'ts': 'typescript',
    'jsx': 'javascript',
    'tsx': 'typescript',
    'html': 'html',
    'css': 'css',
    'scss': 'scss',
    'json': 'json',
    'yaml': 'yaml',
    'yml': 'yaml',
    'md': 'markdown',
    'xml': 'xml',
    'java': 'java',
    'kt': 'kotlin',
    'swift': 'swift',
    'c': 'c',
    'cpp': 'cpp',
    'h': 'c',
    'hpp': 'cpp',
    'go': 'go',
    'rs': 'rust',
    'rb': 'ruby',
    'php': 'php',
    'sh': 'bash',
    'bash': 'bash',
    'zsh': 'bash',
    'sql': 'sql',
    'gradle': 'groovy',
    'properties': 'properties',
    'txt': 'plaintext',
  };

  static const Map<String, String> fileIcons = {
    'folder': 'folder',
    'folder_open': 'folder_open',
    'dart': 'code',
    'python': 'code',
    'javascript': 'code',
    'typescript': 'code',
    'html': 'global',
    'css': 'brush',
    'json': 'document',
    'yaml': 'document',
    'markdown': 'document_text',
    'image': 'image',
    'default': 'document',
  };
}
