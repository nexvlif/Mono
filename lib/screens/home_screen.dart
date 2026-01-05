import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher_string.dart';
import '../core/themes/app_colors.dart';
import '../core/constants/app_constants.dart';
import '../models/file_node.dart';
import '../models/editor_tab.dart';
import '../services/file_service.dart';
import '../services/git_service.dart';
import '../widgets/file_explorer/file_explorer.dart';
import '../widgets/editor/editor_tab_bar.dart';
import '../widgets/editor/code_editor.dart';
import '../widgets/terminal/terminal_panel.dart';
import '../widgets/core/activity_bar.dart';
import '../widgets/extensions/extensions_panel.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FileService _fileService = FileService.instance;
  final GitService _gitService = GitService.instance;

  bool _isSidebarVisible = true;
  double _sidebarWidth = AppConstants.sidebarDefaultWidth;
  ActivityTab _activeActivity = ActivityTab.explorer;
  bool _isTerminalExpanded = false;
  double _terminalHeight = AppConstants.terminalDefaultHeight;

  String? _rootPath;
  final List<EditorTab> _tabs = [];
  int _activeTabIndex = -1;
  String? _currentBranch;
  bool _isGitRepo = false;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await _fileService.requestPermissions();
    await _gitService.initialize();
  }

  EditorTab? get _activeTab =>
      _activeTabIndex >= 0 && _activeTabIndex < _tabs.length
      ? _tabs[_activeTabIndex]
      : null;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            Expanded(
              child: Row(
                children: [
              
                  ActivityBar(
                    activeTab: _activeActivity,
                    onTabSelected: (tab) {
                      setState(() {
                        if (_activeActivity == tab) {
                          _isSidebarVisible = !_isSidebarVisible;
                        } else {
                          _activeActivity = tab;
                          _isSidebarVisible = true;
                        }
                      });
                    },
                    onSettings: () => _showSettings(context),
                  ),

              
                  if (_isSidebarVisible)
                    _buildSidebar()
                        .animate()
                        .fadeIn(duration: 200.ms)
                        .slideX(begin: -0.1, end: 0),

              
                  if (_isSidebarVisible) _buildSidebarResizeHandle(),

              
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                    
                        EditorTabBar(
                          tabs: _tabs,
                          activeIndex: _activeTabIndex,
                          onTabSelected: (index) {
                            setState(() => _activeTabIndex = index);
                          },
                          onTabClosed: _closeTab,
                          onTabReorder: (oldIndex, newIndex) {
                            setState(() {
                              if (oldIndex < newIndex) newIndex--;
                              final tab = _tabs.removeAt(oldIndex);
                              _tabs.insert(newIndex, tab);
                              if (_activeTabIndex == oldIndex) {
                                _activeTabIndex = newIndex;
                              }
                            });
                          },
                        ),

                    
                        Expanded(
                          child: CodeEditor(
                            tab: _activeTab,
                            onContentChanged: (content) {
                              if (_activeTab != null) {
                                setState(() {
                                  _activeTab!.updateContent(content);
                                });
                              }
                            },
                            onSave: _saveCurrentFile,
                            onRun: _runCurrentFile,
                          ),
                        ),

                    
                        TerminalPanel(
                          height: _terminalHeight,
                          workingDirectory: _rootPath,
                          isExpanded: _isTerminalExpanded,
                          onToggle: () {
                            setState(() {
                              _isTerminalExpanded = !_isTerminalExpanded;
                            });
                          },
                          onResize: (height) {
                            setState(() => _terminalHeight = height);
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            _buildBottomBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border, width: 1)),
      ),
      padding: EdgeInsets.zero,
      child: Row(
        children: [
      
          SizedBox(
            width: 48,
            height: 48,
            child: IconButton(
              onPressed: () {
                setState(() => _isSidebarVisible = !_isSidebarVisible);
              },
              icon: Icon(
                _isSidebarVisible
                    ? Iconsax.sidebar_left
                    : Iconsax.sidebar_right,
                size: 20,
              ),
              color: AppColors.textSecondary,
              tooltip: 'Toggle Sidebar',
            ),
          ),

          const SizedBox(width: 8),

      
          Text(
            'Mono',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),

      
          if (_rootPath != null) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                _rootPath!.split('/').last,
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            ),
          ],

          const Spacer(),

      
          if (_isGitRepo && _currentBranch != null) ...[
            GestureDetector(
              onTap: _showGitMenu,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Iconsax.code_1,
                      size: 14,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _currentBranch!,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],

      
          IconButton(
            onPressed: _openFolder,
            icon: Icon(Iconsax.folder_open, size: 20),
            color: AppColors.textSecondary,
            tooltip: 'Open Folder',
          ),
          IconButton(
            onPressed: _saveCurrentFile,
            icon: Icon(Iconsax.document_download, size: 20),
            color: _activeTab?.isModified == true
                ? AppColors.warning
                : AppColors.textSecondary,
            tooltip: 'Save',
          ),
          IconButton(
            onPressed: _runCurrentFile,
            icon: Icon(Iconsax.play, size: 20),
            color: AppColors.textSecondary,
            tooltip: 'Run',
          ),
      
        ],
      ),
    );
  }

  Widget _buildSidebar() {
    switch (_activeActivity) {
      case ActivityTab.explorer:
        return FileExplorer(
          rootPath: _rootPath,
          width: _sidebarWidth,
          onFileSelected: _openFile,
          onDirectoryChanged: (path) {
            setState(() => _rootPath = path);
            _checkGitStatus();
          },
        );
      case ActivityTab.extensions:
        return ExtensionsPanel(width: _sidebarWidth);
      case ActivityTab.search:
        return _buildPlaceholderSidebar('Search');
      case ActivityTab.git:
        return _buildPlaceholderSidebar('Source Control');
    }
  }

  Widget _buildPlaceholderSidebar(String title) {
    return Container(
      width: _sidebarWidth,
      color: AppColors.surface,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title, style: TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 8),
            Text(
              'Coming Soon',
              style: TextStyle(color: AppColors.textMuted, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSidebarResizeHandle() {
    return GestureDetector(
      onHorizontalDragUpdate: (details) {
        setState(() {
          _sidebarWidth += details.delta.dx;
          _sidebarWidth = _sidebarWidth.clamp(
            AppConstants.sidebarMinWidth,
            AppConstants.sidebarMaxWidth,
          );
        });
      },
      child: MouseRegion(
        cursor: SystemMouseCursors.resizeColumn,
        child: Container(
          width: 4,
          color: Colors.transparent,
          child: Center(child: Container(width: 1, color: AppColors.border)),
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      height: 24,
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border, width: 1)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
      
          if (_isGitRepo) ...[
            Icon(Iconsax.code_1, size: 12, color: AppColors.success),
            const SizedBox(width: 4),
            Text(
              _currentBranch ?? 'main',
              style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
            ),
            const SizedBox(width: 12),
          ],

      
          if (_activeTab != null) ...[
            Text(
              _activeTab!.language.toUpperCase(),
              style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
            ),
            const SizedBox(width: 12),
          ],

          const Spacer(),

      
          Text(
            'UTF-8',
            style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
          ),
          const SizedBox(width: 12),

      
          if (_activeTab != null)
            Text(
              'Ln ${_activeTab!.cursorPosition + 1}',
              style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
            ),
        ],
      ),
    );
  }

  Future<void> _openFolder() async {
    try {
      String? selectedDirectory = await FilePicker.platform.getDirectoryPath();

      if (selectedDirectory != null) {
        setState(() {
          _rootPath = selectedDirectory;
        });
        _fileService.setCurrentDirectory(selectedDirectory);
        await _checkGitStatus();
      }
    } catch (e) {
      _showError('Failed to open folder: $e');
    }
  }

  Future<void> _openFile(FileNode node) async {
    if (node.isDirectory) return;


    final existingIndex = _tabs.indexWhere((t) => t.path == node.path);
    if (existingIndex >= 0) {
      setState(() => _activeTabIndex = existingIndex);
      return;
    }

    try {
      final content = await _fileService.readFile(node.path);
      final language = _getLanguage(node.extension);

      final tab = EditorTab(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: node.name,
        path: node.path,
        content: content,
        language: language,
      );

      setState(() {
        _tabs.add(tab);
        _activeTabIndex = _tabs.length - 1;
      });
    } catch (e) {
      _showError('Failed to open file: $e');
    }
  }

  void _closeTab(int index) {
    if (index < 0 || index >= _tabs.length) return;

    final tab = _tabs[index];

    if (tab.isModified) {
      _showSaveDialog(tab, () {
        setState(() {
          _tabs.removeAt(index);
          if (_activeTabIndex >= _tabs.length) {
            _activeTabIndex = _tabs.length - 1;
          }
        });
      });
    } else {
      setState(() {
        _tabs.removeAt(index);
        if (_activeTabIndex >= _tabs.length) {
          _activeTabIndex = _tabs.length - 1;
        }
      });
    }
  }

  Future<void> _saveCurrentFile() async {
    if (_activeTab == null) return;

    try {
      await _fileService.writeFile(_activeTab!.path, _activeTab!.content);
      setState(() {
        _activeTab!.markSaved();
      });
      _showSnackBar('File saved');
    } catch (e) {
      _showError('Failed to save: $e');
    }
  }

  void _showSaveDialog(EditorTab tab, VoidCallback onDiscard) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(
          'Unsaved Changes',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: Text(
          'Do you want to save changes to ${tab.name}?',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onDiscard();
            },
            child: const Text('Discard'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _fileService.writeFile(tab.path, tab.content);
              tab.markSaved();
              onDiscard();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _runCurrentFile() async {
    if (_activeTab == null) return;


    await _saveCurrentFile();

    if (_activeTab!.language == 'html') {
      try {
        final uri = Uri.file(_activeTab!.path).toString();
        if (await canLaunchUrlString(uri)) {
          await launchUrlString(uri);
        } else {
      
          final content = Uri.encodeComponent(_activeTab!.content);
          final dataUri = 'data:text/html;charset=utf-8,$content';
          if (await canLaunchUrlString(dataUri)) {
            await launchUrlString(dataUri);
          } else {
            _showError('Could not launch HTML preview');
          }
        }
      } catch (e) {
        _showError('Expanded HTML preview error: $e');
      }
    } else {
      _showSnackBar(
        'Running ${_activeTab!.language} files is not supported yet',
      );
    }
  }

  Future<void> _checkGitStatus() async {
    if (_rootPath == null) return;

    final isRepo = await _gitService.isGitRepository(_rootPath!);
    if (isRepo) {
      final branch = await _gitService.getCurrentBranch(_rootPath!);
      setState(() {
        _isGitRepo = true;
        _currentBranch = branch;
      });
    } else {
      setState(() {
        _isGitRepo = false;
        _currentBranch = null;
      });
    }
  }

  void _showGitMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Git Actions',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              _buildGitAction(Iconsax.refresh, 'Pull', () async {
                Navigator.pop(context);
                await _gitService.pull(_rootPath!);
                _showSnackBar('Pulled latest changes');
              }),
              _buildGitAction(Iconsax.send_2, 'Push', () async {
                Navigator.pop(context);
                await _gitService.push(_rootPath!);
                _showSnackBar('Pushed changes');
              }),
              _buildGitAction(Iconsax.add_square, 'Stage All', () async {
                Navigator.pop(context);
                await _gitService.stageAll(_rootPath!);
                _showSnackBar('Staged all files');
              }),
              _buildGitAction(Iconsax.tick_square, 'Commit', () {
                Navigator.pop(context);
                _showCommitDialog();
              }),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Widget _buildGitAction(IconData icon, String label, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: AppColors.textSecondary),
      title: Text(label, style: TextStyle(color: AppColors.textPrimary)),
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
    );
  }

  void _showCommitDialog() {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('Commit', style: TextStyle(color: AppColors.textPrimary)),
        content: TextField(
          controller: controller,
          maxLines: 3,
          autofocus: true,
          style: TextStyle(color: AppColors.textPrimary),
          decoration: const InputDecoration(hintText: 'Commit message...'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.isEmpty) return;
              Navigator.pop(context);
              final result = await _gitService.commit(
                _rootPath!,
                controller.text,
              );
              if (result.success) {
                _showSnackBar('Committed: ${result.commitHash}');
              } else {
                _showError(result.error ?? 'Commit failed');
              }
            },
            child: const Text('Commit'),
          ),
        ],
      ),
    );
  }

  void _showSettings(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SettingsScreen()),
    );
  }

  String _getLanguage(String extension) {
    return AppConstants.extensionToLanguage[extension.toLowerCase()] ??
        'plaintext';
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.surface,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
