import 'package:flutter/material.dart';

class TerminalSession {
  final String id;
  final String name;
  final TerminalType type;
  final DateTime createdAt;
  bool isActive;
  String workingDirectory;
  List<TerminalCommand> history;

  TerminalSession({
    required this.id,
    required this.name,
    required this.type,
    DateTime? createdAt,
    this.isActive = true,
    this.workingDirectory = '',
    List<TerminalCommand>? history,
  }) : createdAt = createdAt ?? DateTime.now(),
       history = history ?? [];


  void addToHistory(TerminalCommand command) {
    history.add(command);
    if (history.length > 1000) {
      history.removeAt(0);
    }
  }

  @override
  String toString() => 'TerminalSession($name, type: $type)';
}

enum TerminalType { termux, androidShell, local }

extension TerminalTypeExtension on TerminalType {
  String get displayName {
    switch (this) {
      case TerminalType.termux:
        return 'Termux';
      case TerminalType.androidShell:
        return 'Android Shell';
      case TerminalType.local:
        return 'Local';
    }
  }

  IconData get icon {
    switch (this) {
      case TerminalType.termux:
        return Icons.terminal;
      case TerminalType.androidShell:
        return Icons.android;
      case TerminalType.local:
        return Icons.computer;
    }
  }
}

class TerminalCommand {
  final String command;
  final String? output;
  final int? exitCode;
  final DateTime executedAt;
  final Duration? duration;

  TerminalCommand({
    required this.command,
    this.output,
    this.exitCode,
    DateTime? executedAt,
    this.duration,
  }) : executedAt = executedAt ?? DateTime.now();

  bool get isSuccess => exitCode == 0;

  @override
  String toString() => 'TerminalCommand($command, exit: $exitCode)';
}

class TerminalSessionsNotifier extends ChangeNotifier {
  final List<TerminalSession> _sessions = [];
  int _activeIndex = -1;

  List<TerminalSession> get sessions => List.unmodifiable(_sessions);
  int get activeIndex => _activeIndex;
  TerminalSession? get activeSession =>
      _activeIndex >= 0 && _activeIndex < _sessions.length
      ? _sessions[_activeIndex]
      : null;


  TerminalSession createSession({
    required String name,
    required TerminalType type,
    String? workingDirectory,
  }) {
    final session = TerminalSession(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      type: type,
      workingDirectory: workingDirectory ?? '',
    );
    _sessions.add(session);
    _activeIndex = _sessions.length - 1;
    notifyListeners();
    return session;
  }


  void closeSession(int index) {
    if (index < 0 || index >= _sessions.length) return;

    _sessions[index].isActive = false;
    _sessions.removeAt(index);

    if (_activeIndex >= _sessions.length) {
      _activeIndex = _sessions.length - 1;
    }
    notifyListeners();
  }


  void setActiveSession(int index) {
    if (index >= 0 && index < _sessions.length) {
      _activeIndex = index;
      notifyListeners();
    }
  }


  void addCommandToHistory(TerminalCommand command) {
    if (activeSession != null) {
      activeSession!.addToHistory(command);
      notifyListeners();
    }
  }
}
