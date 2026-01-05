import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../core/themes/app_colors.dart';
import '../../models/file_node.dart';
import '../../services/file_service.dart';

class FileExplorer extends StatefulWidget {
  final String? rootPath;
  final Function(FileNode) onFileSelected;
  final Function(String)? onDirectoryChanged;
  final double width;

  const FileExplorer({
    super.key,
    this.rootPath,
    required this.onFileSelected,
    this.onDirectoryChanged,
    this.width = 260,
  });

  @override
  State<FileExplorer> createState() => _FileExplorerState();
}

class _FileExplorerState extends State<FileExplorer> {
  final FileService _fileService = FileService.instance;
  FileNode? _rootNode;
  bool _isLoading = true;
  String? _error;
  final Set<String> _expandedPaths = {};
  String? _selectedPath;

  @override
  void initState() {
    super.initState();
    _loadDirectory();
  }

  @override
  void didUpdateWidget(FileExplorer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.rootPath != widget.rootPath) {
      _loadDirectory();
    }
  }

  Future<void> _loadDirectory() async {
    if (widget.rootPath == null) {
      setState(() {
        _isLoading = false;
        _error = 'No directory selected';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final rootNode = FileNode.fromPath(widget.rootPath!);
      await rootNode.loadChildren();

      setState(() {
        _rootNode = rootNode;
        _isLoading = false;
        _expandedPaths.add(rootNode.path);
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Failed to load directory: $e';
      });
    }
  }

  void _toggleExpand(FileNode node) async {
    if (!node.isDirectory) return;

    setState(() {
      if (_expandedPaths.contains(node.path)) {
        _expandedPaths.remove(node.path);
      } else {
        _expandedPaths.add(node.path);
      }
    });

    if (_expandedPaths.contains(node.path) && node.children.isEmpty) {
      await node.loadChildren();
      setState(() {});
    }
  }

  void _selectFile(FileNode node) {
    setState(() {
      _selectedPath = node.path;
    });
    if (!node.isDirectory) {
      widget.onFileSelected(node);
    } else {
      _toggleExpand(node);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.width,
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(right: BorderSide(color: AppColors.border, width: 1)),
      ),
      child: Column(
        children: [
          _buildHeader(),
          Expanded(child: _buildContent()),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        border: Border(bottom: BorderSide(color: AppColors.border, width: 1)),
      ),
      child: Row(
        children: [
          Text(
            'EXPLORER',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
              letterSpacing: 0.5,
            ),
          ),
          const Spacer(),
          _buildHeaderAction(Iconsax.refresh, _loadDirectory),
          _buildHeaderAction(Iconsax.folder_add, _createNewFolder),
          _buildHeaderAction(Iconsax.add_circle, _createNewFile),
        ],
      ),
    );
  }

  Widget _buildHeaderAction(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Icon(icon, size: 16, color: AppColors.textSecondary),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: AppColors.primary,
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Iconsax.warning_2, color: AppColors.warning, size: 32),
              const SizedBox(height: 8),
              Text(
                _error!,
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              TextButton(onPressed: _loadDirectory, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }

    if (_rootNode == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Iconsax.folder_open, color: AppColors.textMuted, size: 48),
            const SizedBox(height: 12),
            Text(
              'Open a folder to start',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    if (_rootNode!.children.isEmpty) {
      return _buildEmptyFolderMessage();
    }

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 4),
      children: _buildFileTree(_rootNode!.children, 0),
    );
  }

  Widget _buildEmptyFolderMessage() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Iconsax.folder_open, size: 48, color: AppColors.textMuted),
            const SizedBox(height: 12),
            Text(
              'Folder is empty',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'No files or folders found',
              style: TextStyle(fontSize: 12, color: AppColors.textMuted),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildEmptyAction(
                  Iconsax.document_text,
                  'New File',
                  _createNewFile,
                ),
                const SizedBox(width: 12),
                _buildEmptyAction(
                  Iconsax.folder_add,
                  'New Folder',
                  _createNewFolder,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyAction(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: AppColors.primary),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildFileTree(List<FileNode> nodes, int depth) {
    final widgets = <Widget>[];

    for (final node in nodes) {
      widgets.add(
        FileItem(
          node: node,
          depth: depth,
          isExpanded: _expandedPaths.contains(node.path),
          isSelected: _selectedPath == node.path,
          onTap: () => _selectFile(node),
          onToggle: () => _toggleExpand(node),
          onMove: (src, dest) => _handleFileMove(src, dest),
        ).animate().fadeIn(duration: 150.ms).slideX(begin: -0.05, end: 0),
      );

      if (node.isDirectory && _expandedPaths.contains(node.path)) {
        widgets.addAll(_buildFileTree(node.children, depth + 1));
      }
    }

    return widgets;
  }

  Future<void> _handleFileMove(FileNode src, FileNode dest) async {
    if (src.path == dest.path) return;
    if (src.parentPath == dest.path) return;

    final newPath = '${dest.path}/${src.name}';

    try {
      await _fileService.move(src.path, newPath);
      await _loadDirectory();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to move ${src.name}: $e')),
        );
      }
    }
  }

  void _createNewFile() {
    _showCreateDialog(isDirectory: false);
  }

  void _createNewFolder() {
    _showCreateDialog(isDirectory: true);
  }

  void _showCreateDialog({required bool isDirectory}) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(
          isDirectory ? 'New Folder' : 'New File',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: TextStyle(color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: isDirectory ? 'folder name' : 'filename.dart',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              if (controller.text.isEmpty) return;
              Navigator.pop(context);

              final basePath = widget.rootPath ?? '';
              final newPath = '$basePath/${controller.text}';

              try {
                if (isDirectory) {
                  await _fileService.createDirectory(newPath);
                } else {
                  await _fileService.createFile(newPath);
                }
                await _loadDirectory();
              } catch (e) {
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }
}

class FileItem extends StatelessWidget {
  final FileNode node;
  final int depth;
  final bool isExpanded;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onToggle;
  final Function(FileNode, FileNode) onMove;

  const FileItem({
    super.key,
    required this.node,
    required this.depth,
    required this.isExpanded,
    required this.isSelected,
    required this.onTap,
    required this.onToggle,
    required this.onMove,
  });

  @override
  Widget build(BuildContext context) {
    return DragTarget<FileNode>(
      onWillAcceptWithDetails: (details) {
        final src = details.data;
        if (!node.isDirectory) return false;
        if (src.path == node.path) return false;
        if (src.parentPath == node.path) return false;
        if (node.path.startsWith(src.path)) return false;
        return true;
      },
      onAcceptWithDetails: (details) => onMove(details.data, node),
      builder: (context, candidateData, rejectedData) {
        final isHovered = candidateData.isNotEmpty;

        return LongPressDraggable<FileNode>(
          data: node,
          feedback: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.surface.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    node.isDirectory ? Iconsax.folder : Iconsax.document,
                    size: 16,
                    color: AppColors.textPrimary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    node.name,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      decoration: TextDecoration.none,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
          childWhenDragging: Opacity(
            opacity: 0.5,
            child: _buildItemContent(isHovered: isHovered),
          ),
          child: _buildItemContent(isHovered: isHovered),
        );
      },
    );
  }

  Widget _buildItemContent({required bool isHovered}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 24,
        padding: EdgeInsets.only(left: 8 + (depth * 16.0)),
        decoration: BoxDecoration(
          color: isHovered
              ? AppColors.primary.withValues(alpha: 0.3)
              : isSelected
              ? AppColors.primary.withValues(alpha: 0.15)
              : null,
          border: isSelected || isHovered
              ? Border(left: BorderSide(color: AppColors.primary, width: 2))
              : null,
        ),
        child: Row(
          children: [
            if (node.isDirectory)
              GestureDetector(
                onTap: onToggle,
                child: Icon(
                  isExpanded ? Iconsax.arrow_down_1 : Iconsax.arrow_right_3,
                  size: 12,
                  color: AppColors.textMuted,
                ),
              )
            else
              const SizedBox(width: 12),

            const SizedBox(width: 4),

            Icon(_getIcon(), size: 16, color: _getIconColor()),

            const SizedBox(width: 6),

            Expanded(
              child: Text(
                node.name,
                style: TextStyle(
                  fontSize: 13,
                  color: isSelected
                      ? AppColors.textPrimary
                      : AppColors.textSecondary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),

            if (node.gitStatus != GitStatus.none) ...[
              const SizedBox(width: 4),
              _buildGitIndicator(),
            ],

            const SizedBox(width: 8),
          ],
        ),
      ),
    );
  }

  IconData _getIcon() {
    if (node.isDirectory) {
      return isExpanded ? Iconsax.folder_open : Iconsax.folder;
    }

    switch (node.extension) {
      case 'dart':
        return Iconsax.code;
      case 'py':
      case 'python':
        return Iconsax.code;
      case 'js':
      case 'ts':
      case 'jsx':
      case 'tsx':
        return Iconsax.code;
      case 'html':
        return Iconsax.global;
      case 'css':
      case 'scss':
        return Iconsax.brush_1;
      case 'json':
      case 'yaml':
      case 'yml':
        return Iconsax.document;
      case 'md':
        return Iconsax.document_text;
      case 'png':
      case 'jpg':
      case 'jpeg':
      case 'gif':
      case 'svg':
        return Iconsax.image;
      default:
        return Iconsax.document_1;
    }
  }

  Color _getIconColor() {
    if (node.isDirectory) {
      return AppColors.warning;
    }

    switch (node.extension) {
      case 'dart':
        return AppColors.primary;
      case 'py':
        return const Color(0xFF3776AB);
      case 'js':
      case 'jsx':
        return const Color(0xFFF7DF1E);
      case 'ts':
      case 'tsx':
        return const Color(0xFF3178C6);
      case 'html':
        return const Color(0xFFE34F26);
      case 'css':
      case 'scss':
        return const Color(0xFF1572B6);
      case 'json':
        return const Color(0xFFFFA500);
      case 'yaml':
      case 'yml':
        return const Color(0xFFCB171E);
      case 'md':
        return AppColors.textSecondary;
      default:
        return AppColors.textMuted;
    }
  }

  Widget _buildGitIndicator() {
    Color color;
    switch (node.gitStatus) {
      case GitStatus.added:
        color = AppColors.gitAdded;
        break;
      case GitStatus.modified:
        color = AppColors.gitModified;
        break;
      case GitStatus.deleted:
        color = AppColors.gitDeleted;
        break;
      case GitStatus.untracked:
        color = AppColors.gitUntracked;
        break;
      default:
        return const SizedBox.shrink();
    }

    return Container(
      width: 6,
      height: 6,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
