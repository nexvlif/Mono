import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class TerminalService {
  static TerminalService? _instance;
  static TerminalService get instance => _instance ??= TerminalService._();
  TerminalService._();

  static const _channel = MethodChannel('mono/terminal');

  bool _isTermuxAvailable = false;
  bool _isAndroidShellAvailable = false;
  String? _termuxHome;

  bool get isTermuxAvailable => _isTermuxAvailable;
  bool get isAndroidShellAvailable => _isAndroidShellAvailable;
  String? get termuxHome => _termuxHome;

  Future<void> initialize() async {
    await _checkTermuxAvailability();
    await _checkAndroidShellAvailability();
  }

  Future<void> _checkTermuxAvailability() async {
    try {
      const termuxPaths = [
        '/data/data/com.termux/files/home',
        '/data/data/com.termux/files/usr/bin',
      ];

      for (final path in termuxPaths) {
        if (await Directory(path).exists()) {
          _isTermuxAvailable = true;
          _termuxHome = '/data/data/com.termux/files/home';
          break;
        }
      }
    } catch (e) {
      debugPrint('Termux check failed: $e');
      _isTermuxAvailable = false;
    }
  }

  Future<void> _checkAndroidShellAvailability() async {
    try {
      final result = await Process.run('echo', ['test']);
      _isAndroidShellAvailable = result.exitCode == 0;
    } catch (e) {
      _isAndroidShellAvailable = false;
    }
  }

  Future<CommandResult> executeTermuxCommand(
    String command, {
    String? workingDirectory,
    Map<String, String>? environment,
  }) async {
    if (!_isTermuxAvailable) {
      return CommandResult(
        exitCode: -1,
        stdout: '',
        stderr: 'Termux is not available',
      );
    }

    try {
      final result = await _channel.invokeMethod<Map>('executeTermuxCommand', {
        'command': command,
        'workingDirectory': workingDirectory ?? _termuxHome,
        'environment': environment,
      });

      if (result != null) {
        return CommandResult(
          exitCode: result['exitCode'] as int? ?? -1,
          stdout: result['stdout'] as String? ?? '',
          stderr: result['stderr'] as String? ?? '',
        );
      }

      return await _executeViaShellScript(command, workingDirectory);
    } on PlatformException {
      return await _executeViaShellScript(command, workingDirectory);
    } catch (e) {
      return CommandResult(
        exitCode: -1,
        stdout: '',
        stderr: 'Failed to execute command: $e',
      );
    }
  }

  Future<CommandResult> _executeViaShellScript(
    String command,
    String? workingDirectory,
  ) async {
    try {
      final process = await Process.start(
        '/system/bin/sh',
        ['-c', command],
        workingDirectory: workingDirectory,
        environment: {
          'HOME': _termuxHome ?? '/data/data/com.termux/files/home',
          'PATH':
              '/data/data/com.termux/files/usr/bin:${Platform.environment['PATH'] ?? ''}',
        },
      );

      final stdout = await process.stdout.transform(utf8.decoder).join();
      final stderr = await process.stderr.transform(utf8.decoder).join();
      final exitCode = await process.exitCode;

      return CommandResult(exitCode: exitCode, stdout: stdout, stderr: stderr);
    } catch (e) {
      return CommandResult(
        exitCode: -1,
        stdout: '',
        stderr: 'Shell execution failed: $e',
      );
    }
  }

  Future<CommandResult> executeAndroidShellCommand(
    String command, {
    String? workingDirectory,
    Map<String, String>? environment,
  }) async {
    try {
      final result = await Process.run(
        '/system/bin/sh',
        ['-c', command],
        workingDirectory: workingDirectory,
        environment: environment,
      );

      return CommandResult(
        exitCode: result.exitCode,
        stdout: result.stdout.toString(),
        stderr: result.stderr.toString(),
      );
    } catch (e) {
      return CommandResult(
        exitCode: -1,
        stdout: '',
        stderr: 'Android shell execution failed: $e',
      );
    }
  }

  Future<CommandResult> executeCommand(
    String command, {
    String? workingDirectory,
    Map<String, String>? environment,
    bool preferTermux = true,
  }) async {
    if (preferTermux && _isTermuxAvailable) {
      return executeTermuxCommand(
        command,
        workingDirectory: workingDirectory,
        environment: environment,
      );
    }

    return executeAndroidShellCommand(
      command,
      workingDirectory: workingDirectory,
      environment: environment,
    );
  }

  Stream<String> startInteractiveSession({
    String? workingDirectory,
    String shell = '/system/bin/sh',
  }) async* {
    try {
      final process = await Process.start(
        shell,
        [],
        workingDirectory: workingDirectory ?? _termuxHome,
        environment: {
          'TERM': 'xterm-256color',
          'HOME': _termuxHome ?? '/data/local/tmp',
        },
      );

      await for (final data in process.stdout) {
        yield utf8.decode(data);
      }
    } catch (e) {
      yield 'Error starting shell: $e\n';
    }
  }

  Future<bool> commandExists(String command) async {
    final result = await executeCommand('which $command');
    return result.exitCode == 0 && result.stdout.trim().isNotEmpty;
  }

  Future<List<String>> getAvailableShells() async {
    final shells = <String>[];

    const possibleShells = [
      '/system/bin/sh',
      '/system/bin/bash',
      '/data/data/com.termux/files/usr/bin/bash',
      '/data/data/com.termux/files/usr/bin/zsh',
      '/data/data/com.termux/files/usr/bin/fish',
    ];

    for (final shell in possibleShells) {
      if (await File(shell).exists()) {
        shells.add(shell);
      }
    }

    return shells;
  }
}

class CommandResult {
  final int exitCode;
  final String stdout;
  final String stderr;

  CommandResult({
    required this.exitCode,
    required this.stdout,
    required this.stderr,
  });

  bool get isSuccess => exitCode == 0;

  String get output => stdout.isNotEmpty ? stdout : stderr;

  @override
  String toString() =>
      'CommandResult(exit: $exitCode, out: ${stdout.length} chars)';
}
