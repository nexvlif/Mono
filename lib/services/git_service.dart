import 'dart:io';
import '../models/file_node.dart';
import 'terminal_service.dart';

class GitService {
  static GitService? _instance;
  static GitService get instance => _instance ??= GitService._();
  GitService._();

  final TerminalService _terminal = TerminalService.instance;

  bool _isGitAvailable = false;
  bool get isGitAvailable => _isGitAvailable;

  Future<void> initialize() async {
    _isGitAvailable = await _terminal.commandExists('git');
  }

  Future<bool> isGitRepository(String path) async {
    final gitDir = Directory('$path/.git');
    return await gitDir.exists();
  }

  Future<GitStatusResult> getStatus(String repoPath) async {
    if (!_isGitAvailable) {
      return GitStatusResult.notAvailable();
    }

    try {
      final result = await _terminal.executeCommand(
        'git status --porcelain=v1',
        workingDirectory: repoPath,
      );

      if (!result.isSuccess) {
        return GitStatusResult(isRepository: false, error: result.stderr);
      }

      final files = _parseStatusOutput(result.stdout);
      return GitStatusResult(isRepository: true, files: files);
    } catch (e) {
      return GitStatusResult(isRepository: false, error: e.toString());
    }
  }


  Map<String, GitStatus> _parseStatusOutput(String output) {
    final files = <String, GitStatus>{};
    final lines = output.split('\n').where((l) => l.isNotEmpty);

    for (final line in lines) {
      if (line.length < 3) continue;

      final status = line.substring(0, 2);
      final filePath = line.substring(3).trim();

      files[filePath] = _parseStatus(status);
    }

    return files;
  }

  GitStatus _parseStatus(String status) {
    final index = status[0];
    final workTree = status[1];

    if (index == 'A' || workTree == 'A') return GitStatus.added;
    if (index == 'M' || workTree == 'M') return GitStatus.modified;
    if (index == 'D' || workTree == 'D') return GitStatus.deleted;
    if (index == 'R' || workTree == 'R') return GitStatus.renamed;
    if (index == 'C' || workTree == 'C') return GitStatus.copied;
    if (index == '?' && workTree == '?') return GitStatus.untracked;
    if (index == '!' && workTree == '!') return GitStatus.ignored;

    return GitStatus.none;
  }


  Future<String?> getCurrentBranch(String repoPath) async {
    if (!_isGitAvailable) return null;

    try {
      final result = await _terminal.executeCommand(
        'git branch --show-current',
        workingDirectory: repoPath,
      );

      if (result.isSuccess) {
        return result.stdout.trim();
      }

      final headResult = await _terminal.executeCommand(
        'git rev-parse --short HEAD',
        workingDirectory: repoPath,
      );

      if (headResult.isSuccess) {
        return 'HEAD detached at ${headResult.stdout.trim()}';
      }

      return null;
    } catch (e) {
      return null;
    }
  }


  Future<List<String>> getBranches(String repoPath) async {
    if (!_isGitAvailable) return [];

    try {
      final result = await _terminal.executeCommand(
        'git branch --list',
        workingDirectory: repoPath,
      );

      if (!result.isSuccess) return [];

      return result.stdout
          .split('\n')
          .map((b) => b.replaceAll('*', '').trim())
          .where((b) => b.isNotEmpty)
          .toList();
    } catch (e) {
      return [];
    }
  }


  Future<bool> stageFile(String repoPath, String filePath) async {
    if (!_isGitAvailable) return false;

    try {
      final result = await _terminal.executeCommand(
        'git add "$filePath"',
        workingDirectory: repoPath,
      );
      return result.isSuccess;
    } catch (e) {
      return false;
    }
  }


  Future<bool> stageAll(String repoPath) async {
    if (!_isGitAvailable) return false;

    try {
      final result = await _terminal.executeCommand(
        'git add -A',
        workingDirectory: repoPath,
      );
      return result.isSuccess;
    } catch (e) {
      return false;
    }
  }


  Future<bool> unstageFile(String repoPath, String filePath) async {
    if (!_isGitAvailable) return false;

    try {
      final result = await _terminal.executeCommand(
        'git reset HEAD "$filePath"',
        workingDirectory: repoPath,
      );
      return result.isSuccess;
    } catch (e) {
      return false;
    }
  }


  Future<CommitResult> commit(String repoPath, String message) async {
    if (!_isGitAvailable) {
      return CommitResult(success: false, error: 'Git not available');
    }

    try {
      final escapedMessage = message.replaceAll('"', r'\"');

      final result = await _terminal.executeCommand(
        'git commit -m "$escapedMessage"',
        workingDirectory: repoPath,
      );

      if (result.isSuccess) {

        final hashResult = await _terminal.executeCommand(
          'git rev-parse --short HEAD',
          workingDirectory: repoPath,
        );

        return CommitResult(
          success: true,
          commitHash: hashResult.stdout.trim(),
          message: message,
        );
      }

      return CommitResult(
        success: false,
        error: result.stderr.isNotEmpty ? result.stderr : result.stdout,
      );
    } catch (e) {
      return CommitResult(success: false, error: e.toString());
    }
  }


  Future<bool> push(String repoPath, {String? remote, String? branch}) async {
    if (!_isGitAvailable) return false;

    try {
      final remoteName = remote ?? 'origin';
      final branchName = branch ?? await getCurrentBranch(repoPath) ?? 'main';

      final result = await _terminal.executeCommand(
        'git push $remoteName $branchName',
        workingDirectory: repoPath,
      );
      return result.isSuccess;
    } catch (e) {
      return false;
    }
  }


  Future<bool> pull(String repoPath, {String? remote, String? branch}) async {
    if (!_isGitAvailable) return false;

    try {
      final remoteName = remote ?? 'origin';
      final branchName = branch ?? await getCurrentBranch(repoPath) ?? 'main';

      final result = await _terminal.executeCommand(
        'git pull $remoteName $branchName',
        workingDirectory: repoPath,
      );
      return result.isSuccess;
    } catch (e) {
      return false;
    }
  }


  Future<bool> fetch(String repoPath, {String? remote}) async {
    if (!_isGitAvailable) return false;

    try {
      final remoteName = remote ?? '--all';
      final result = await _terminal.executeCommand(
        'git fetch $remoteName',
        workingDirectory: repoPath,
      );
      return result.isSuccess;
    } catch (e) {
      return false;
    }
  }


  Future<bool> switchBranch(String repoPath, String branchName) async {
    if (!_isGitAvailable) return false;

    try {
      final result = await _terminal.executeCommand(
        'git checkout "$branchName"',
        workingDirectory: repoPath,
      );
      return result.isSuccess;
    } catch (e) {
      return false;
    }
  }


  Future<bool> createBranch(
    String repoPath,
    String branchName, {
    bool checkout = true,
  }) async {
    if (!_isGitAvailable) return false;

    try {
      final command = checkout
          ? 'git checkout -b "$branchName"'
          : 'git branch "$branchName"';

      final result = await _terminal.executeCommand(
        command,
        workingDirectory: repoPath,
      );
      return result.isSuccess;
    } catch (e) {
      return false;
    }
  }


  Future<List<GitCommit>> getRecentCommits(
    String repoPath, {
    int count = 20,
  }) async {
    if (!_isGitAvailable) return [];

    try {
      final result = await _terminal.executeCommand(
        'git log --oneline -n $count --format="%H|%s|%an|%ar"',
        workingDirectory: repoPath,
      );

      if (!result.isSuccess) return [];

      return result.stdout
          .split('\n')
          .where((l) => l.isNotEmpty)
          .map((line) {
            final parts = line.split('|');
            if (parts.length >= 4) {
              return GitCommit(
                hash: parts[0],
                message: parts[1],
                author: parts[2],
                relativeTime: parts[3],
              );
            }
            return null;
          })
          .whereType<GitCommit>()
          .toList();
    } catch (e) {
      return [];
    }
  }


  Future<bool> discardChanges(String repoPath, String filePath) async {
    if (!_isGitAvailable) return false;

    try {
      final result = await _terminal.executeCommand(
        'git checkout -- "$filePath"',
        workingDirectory: repoPath,
      );
      return result.isSuccess;
    } catch (e) {
      return false;
    }
  }


  Future<bool> clone(String url, String destPath) async {
    if (!_isGitAvailable) return false;

    try {
      final result = await _terminal.executeCommand(
        'git clone "$url" "$destPath"',
      );
      return result.isSuccess;
    } catch (e) {
      return false;
    }
  }


  Future<bool> init(String path) async {
    if (!_isGitAvailable) return false;

    try {
      final result = await _terminal.executeCommand(
        'git init',
        workingDirectory: path,
      );
      return result.isSuccess;
    } catch (e) {
      return false;
    }
  }
}

class GitStatusResult {
  final bool isRepository;
  final Map<String, GitStatus> files;
  final String? error;

  GitStatusResult({
    required this.isRepository,
    this.files = const {},
    this.error,
  });

  factory GitStatusResult.notAvailable() =>
      GitStatusResult(isRepository: false, error: 'Git is not available');

  bool get hasChanges => files.isNotEmpty;

  int get stagedCount => files.values
      .where((s) => s == GitStatus.added || s == GitStatus.modified)
      .length;

  int get untrackedCount =>
      files.values.where((s) => s == GitStatus.untracked).length;
}

class CommitResult {
  final bool success;
  final String? commitHash;
  final String? message;
  final String? error;

  CommitResult({
    required this.success,
    this.commitHash,
    this.message,
    this.error,
  });
}

class GitCommit {
  final String hash;
  final String message;
  final String author;
  final String relativeTime;

  GitCommit({
    required this.hash,
    required this.message,
    required this.author,
    required this.relativeTime,
  });

  String get shortHash => hash.length > 7 ? hash.substring(0, 7) : hash;
}
