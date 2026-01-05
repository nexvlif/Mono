import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/file_node.dart';

class FileService {
  static FileService? _instance;
  static FileService get instance => _instance ??= FileService._();
  FileService._();

  String? _currentDirectory;
  String? get currentDirectory => _currentDirectory;


  Future<bool> requestPermissions() async {
    if (Platform.isAndroid) {
      final status = await Permission.manageExternalStorage.request();
      if (status.isGranted) return true;

      final storageStatus = await Permission.storage.request();
      return storageStatus.isGranted;
    }
    return true;
  }


  Future<bool> hasPermissions() async {
    if (Platform.isAndroid) {
      return await Permission.manageExternalStorage.isGranted ||
          await Permission.storage.isGranted;
    }
    return true;
  }


  Future<List<String>> getDefaultDirectories() async {
    final directories = <String>[];

    try {
      final appDir = await getApplicationDocumentsDirectory();
      directories.add(appDir.path);

      if (Platform.isAndroid) {
        final extDirs = await getExternalStorageDirectories();
        if (extDirs != null && extDirs.isNotEmpty) {
          directories.addAll(extDirs.map((d) => d.path));
        }


        const commonPaths = [
          '/storage/emulated/0',
          '/storage/emulated/0/Download',
          '/storage/emulated/0/Documents',
          '/data/data/com.termux/files/home',
        ];
        for (final path in commonPaths) {
          if (await Directory(path).exists()) {
            directories.add(path);
          }
        }
      }
    } catch (e) {
      debugPrint('Error getting directories: $e');
    }

    return directories.toSet().toList();
  }


  void setCurrentDirectory(String path) {
    _currentDirectory = path;
  }


  Future<String> readFile(String path) async {
    try {
      final file = File(path);
      return await file.readAsString();
    } catch (e) {
      throw FileServiceException('Failed to read file: $e');
    }
  }


  Future<void> writeFile(String path, String content) async {
    try {
      final file = File(path);
      await file.writeAsString(content);
    } catch (e) {
      throw FileServiceException('Failed to write file: $e');
    }
  }


  Future<File> createFile(String path, {String content = ''}) async {
    try {
      final file = File(path);
      if (await file.exists()) {
        throw FileServiceException('File already exists');
      }
      await file.create(recursive: true);
      if (content.isNotEmpty) {
        await file.writeAsString(content);
      }
      return file;
    } catch (e) {
      throw FileServiceException('Failed to create file: $e');
    }
  }


  Future<Directory> createDirectory(String path) async {
    try {
      final dir = Directory(path);
      if (await dir.exists()) {
        throw FileServiceException('Directory already exists');
      }
      return await dir.create(recursive: true);
    } catch (e) {
      throw FileServiceException('Failed to create directory: $e');
    }
  }


  Future<void> delete(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
        return;
      }

      final dir = Directory(path);
      if (await dir.exists()) {
        await dir.delete(recursive: true);
        return;
      }

      throw FileServiceException('Path does not exist');
    } catch (e) {
      throw FileServiceException('Failed to delete: $e');
    }
  }


  Future<String> rename(String oldPath, String newName) async {
    try {
      final file = File(oldPath);
      final isFile = await file.exists();

      final parentPath = oldPath.substring(
        0,
        oldPath.lastIndexOf(Platform.pathSeparator),
      );
      final newPath = '$parentPath${Platform.pathSeparator}$newName';

      if (isFile) {
        final renamed = await file.rename(newPath);
        return renamed.path;
      } else {
        final dir = Directory(oldPath);
        final renamed = await dir.rename(newPath);
        return renamed.path;
      }
    } catch (e) {
      throw FileServiceException('Failed to rename: $e');
    }
  }


  Future<String> copyFile(String sourcePath, String destPath) async {
    try {
      final file = File(sourcePath);
      final copied = await file.copy(destPath);
      return copied.path;
    } catch (e) {
      throw FileServiceException('Failed to copy file: $e');
    }
  }


  Future<String> move(String sourcePath, String destPath) async {
    try {
      final file = File(sourcePath);
      if (await file.exists()) {
        await file.copy(destPath);
        await file.delete();
        return destPath;
      }

      final dir = Directory(sourcePath);
      if (await dir.exists()) {
        final newDir = await Directory(destPath).create(recursive: true);
        await _copyDirectory(dir, newDir);
        await dir.delete(recursive: true);
        return newDir.path;
      }

      throw FileServiceException('Source does not exist');
    } catch (e) {
      throw FileServiceException('Failed to move: $e');
    }
  }


  Future<void> _copyDirectory(Directory source, Directory dest) async {
    await for (final entity in source.list()) {
      final newPath =
          '${dest.path}${Platform.pathSeparator}${entity.path.split(Platform.pathSeparator).last}';

      if (entity is File) {
        await entity.copy(newPath);
      } else if (entity is Directory) {
        final newDir = await Directory(newPath).create();
        await _copyDirectory(entity, newDir);
      }
    }
  }


  Future<bool> exists(String path) async {
    return await File(path).exists() || await Directory(path).exists();
  }


  Future<FileStat> getFileStat(String path) async {
    try {
      return await File(path).stat();
    } catch (e) {
      throw FileServiceException('Failed to get file info: $e');
    }
  }


  Future<FileNode> loadDirectoryTree(String path, {int maxDepth = 3}) async {
    final root = FileNode.fromPath(path);
    await _loadChildrenRecursive(root, 0, maxDepth);
    return root;
  }

  Future<void> _loadChildrenRecursive(
    FileNode node,
    int currentDepth,
    int maxDepth,
  ) async {
    if (!node.isDirectory || currentDepth >= maxDepth) return;

    await node.loadChildren();
    for (final child in node.children) {
      if (child.isDirectory) {
        await _loadChildrenRecursive(child, currentDepth + 1, maxDepth);
      }
    }
  }


  Future<List<FileNode>> searchFiles(String directory, String query) async {
    final results = <FileNode>[];
    final dir = Directory(directory);

    try {
      await for (final entity in dir.list(recursive: true)) {
        final name = entity.path.split(Platform.pathSeparator).last;
        if (name.toLowerCase().contains(query.toLowerCase())) {
          results.add(
            FileNode(
              name: name,
              path: entity.path,
              isDirectory: entity is Directory,
            ),
          );
          if (results.length >= 100) break;
        }
      }
    } catch (e) {
      debugPrint('Search error: $e');
    }

    return results;
  }
}

class FileServiceException implements Exception {
  final String message;
  FileServiceException(this.message);

  @override
  String toString() => 'FileServiceException: $message';
}
