import 'dart:io';

class FileNode {
  final String name;
  final String path;
  final bool isDirectory;
  final int depth;
  List<FileNode> children;
  bool isExpanded;
  FileNode? parent;

  // Git status
  GitStatus gitStatus;

  FileNode({
    required this.name,
    required this.path,
    required this.isDirectory,
    this.depth = 0,
    this.children = const [],
    this.isExpanded = false,
    this.parent,
    this.gitStatus = GitStatus.none,
  });

  String get parentPath {
    final separator = Platform.pathSeparator;
    final lastSeparator = path.lastIndexOf(separator);
    if (lastSeparator == -1) return '';
    return path.substring(0, lastSeparator);
  }

  String get extension {
    if (isDirectory) return '';
    final dotIndex = name.lastIndexOf('.');
    if (dotIndex == -1 || dotIndex == name.length - 1) return '';
    return name.substring(dotIndex + 1).toLowerCase();
  }

  bool get isHidden => name.startsWith('.');

  Future<int> get size async {
    if (isDirectory) return 0;
    try {
      return await File(path).length();
    } catch (e) {
      return 0;
    }
  }

  Future<List<FileNode>> loadChildren() async {
    if (!isDirectory) return [];

    try {
      final dir = Directory(path);
      final entities = await dir.list().toList();

      final nodes = <FileNode>[];
      for (final entity in entities) {
        final name = entity.path.split(Platform.pathSeparator).last;
        nodes.add(
          FileNode(
            name: name,
            path: entity.path,
            isDirectory: entity is Directory,
            depth: depth + 1,
            parent: this,
          ),
        );
      }

      nodes.sort((a, b) {
        if (a.isDirectory && !b.isDirectory) return -1;
        if (!a.isDirectory && b.isDirectory) return 1;
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });

      children = nodes;
      return nodes;
    } catch (e) {
      return [];
    }
  }

  static FileNode fromPath(String path) {
    final dir = Directory(path);
    final isDir = dir.existsSync();
    final name = path.split(Platform.pathSeparator).last;

    return FileNode(name: name, path: path, isDirectory: isDir);
  }

  @override
  String toString() => 'FileNode($name, isDir: $isDirectory)';
}
enum GitStatus {
  none,
  added,
  modified,
  deleted,
  untracked,
  renamed,
  copied,
  ignored,
}

extension GitStatusExtension on GitStatus {
  String get symbol {
    switch (this) {
      case GitStatus.added:
        return 'A';
      case GitStatus.modified:
        return 'M';
      case GitStatus.deleted:
        return 'D';
      case GitStatus.untracked:
        return 'U';
      case GitStatus.renamed:
        return 'R';
      case GitStatus.copied:
        return 'C';
      case GitStatus.ignored:
        return 'I';
      case GitStatus.none:
        return '';
    }
  }
}
