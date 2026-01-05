import 'package:flutter/material.dart';

class EditorTab {
  final String id;
  final String name;
  final String path;
  String content;
  String savedContent;
  final String language;
  int cursorPosition;
  int scrollPosition;
  bool isPinned;

  EditorTab({
    required this.id,
    required this.name,
    required this.path,
    required this.content,
    String? savedContent,
    required this.language,
    this.cursorPosition = 0,
    this.scrollPosition = 0,
    this.isPinned = false,
  }) : savedContent = savedContent ?? content;

  bool get isModified => content != savedContent;

  String get extension {
    final dotIndex = name.lastIndexOf('.');
    if (dotIndex == -1 || dotIndex == name.length - 1) return '';
    return name.substring(dotIndex + 1).toLowerCase();
  }

  void markSaved() {
    savedContent = content;
  }

  void updateContent(String newContent) {
    content = newContent;
  }

  EditorTab copyWith({
    String? id,
    String? name,
    String? path,
    String? content,
    String? savedContent,
    String? language,
    int? cursorPosition,
    int? scrollPosition,
    bool? isPinned,
  }) {
    return EditorTab(
      id: id ?? this.id,
      name: name ?? this.name,
      path: path ?? this.path,
      content: content ?? this.content,
      savedContent: savedContent ?? this.savedContent,
      language: language ?? this.language,
      cursorPosition: cursorPosition ?? this.cursorPosition,
      scrollPosition: scrollPosition ?? this.scrollPosition,
      isPinned: isPinned ?? this.isPinned,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EditorTab &&
          runtimeType == other.runtimeType &&
          path == other.path;

  @override
  int get hashCode => path.hashCode;

  @override
  String toString() => 'EditorTab($name, modified: $isModified)';
}
class EditorTabsNotifier extends ChangeNotifier {
  final List<EditorTab> _tabs = [];
  int _activeIndex = -1;

  List<EditorTab> get tabs => List.unmodifiable(_tabs);
  int get activeIndex => _activeIndex;
  EditorTab? get activeTab => _activeIndex >= 0 && _activeIndex < _tabs.length
      ? _tabs[_activeIndex]
      : null;

  bool get hasUnsavedChanges => _tabs.any((tab) => tab.isModified);

  void openTab(EditorTab tab) {
    final existingIndex = _tabs.indexWhere((t) => t.path == tab.path);
    if (existingIndex >= 0) {
      _activeIndex = existingIndex;
    } else {
      _tabs.add(tab);
      _activeIndex = _tabs.length - 1;
    }
    notifyListeners();
  }

  void closeTab(int index) {
    if (index < 0 || index >= _tabs.length) return;

    _tabs.removeAt(index);
    if (_activeIndex >= _tabs.length) {
      _activeIndex = _tabs.length - 1;
    } else if (_activeIndex > index) {
      _activeIndex--;
    }
    notifyListeners();
  }

  void closeTabByPath(String path) {
    final index = _tabs.indexWhere((t) => t.path == path);
    if (index >= 0) closeTab(index);
  }

  void setActiveTab(int index) {
    if (index >= 0 && index < _tabs.length) {
      _activeIndex = index;
      notifyListeners();
    }
  }

  void updateTabContent(String path, String content) {
    final index = _tabs.indexWhere((t) => t.path == path);
    if (index >= 0) {
      _tabs[index].updateContent(content);
      notifyListeners();
    }
  }

  void markTabSaved(String path) {
    final index = _tabs.indexWhere((t) => t.path == path);
    if (index >= 0) {
      _tabs[index].markSaved();
      notifyListeners();
    }
  }

  void reorderTab(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) newIndex--;
    final tab = _tabs.removeAt(oldIndex);
    _tabs.insert(newIndex, tab);

    if (_activeIndex == oldIndex) {
      _activeIndex = newIndex;
    } else if (_activeIndex > oldIndex && _activeIndex <= newIndex) {
      _activeIndex--;
    } else if (_activeIndex < oldIndex && _activeIndex >= newIndex) {
      _activeIndex++;
    }
    notifyListeners();
  }

  void closeAllTabs() {
    _tabs.clear();
    _activeIndex = -1;
    notifyListeners();
  }

  void closeOtherTabs(int keepIndex) {
    if (keepIndex < 0 || keepIndex >= _tabs.length) return;
    final keepTab = _tabs[keepIndex];
    _tabs.clear();
    _tabs.add(keepTab);
    _activeIndex = 0;
    notifyListeners();
  }
}
