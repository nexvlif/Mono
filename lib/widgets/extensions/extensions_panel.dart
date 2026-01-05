import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../core/themes/app_colors.dart';

class Extension {
  final String name;
  final String description;
  final String author;
  final String version;
  bool isInstalled;

  Extension({
    required this.name,
    required this.description,
    required this.author,
    required this.version,
    this.isInstalled = false,
  });
}

class ExtensionsPanel extends StatefulWidget {
  final double width;

  const ExtensionsPanel({super.key, required this.width});

  @override
  State<ExtensionsPanel> createState() => _ExtensionsPanelState();
}

class _ExtensionsPanelState extends State<ExtensionsPanel> {
  final TextEditingController _searchController = TextEditingController();

  final List<Extension> _extensions = [
    Extension(
      name: 'Flutter',
      description: 'Flutter support for VS Code',
      author: 'Dart Code',
      version: '3.76.0',
      isInstalled: true,
    ),
    Extension(
      name: 'Dart',
      description: 'Dart language support and debugger',
      author: 'Dart Code',
      version: '3.76.0',
      isInstalled: true,
    ),
    Extension(
      name: 'Python',
      description: 'IntelliSense, linting, debugging',
      author: 'Microsoft',
      version: '2024.2.0',
    ),
    Extension(
      name: 'One Dark Pro',
      description: 'Atom\'s iconic One Dark theme',
      author: 'binaryify',
      version: '3.19.0',
    ),
    Extension(
      name: 'Prettier',
      description: 'Code formatter',
      author: 'Prettier',
      version: '10.1.0',
    ),
    Extension(
      name: 'GitLens',
      description: 'Supercharge Git within VS Code',
      author: 'GitKraken',
      version: '14.6.0',
    ),
    Extension(
      name: 'Material Icon Theme',
      description: 'Material Design Icons',
      author: 'Philipp Kief',
      version: '4.34.0',
    ),
  ];

  List<Extension> _filteredExtensions = [];

  @override
  void initState() {
    super.initState();
    _filteredExtensions = _extensions;
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredExtensions = _extensions.where((ext) {
        return ext.name.toLowerCase().contains(query) ||
            ext.description.toLowerCase().contains(query);
      }).toList();
    });
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
          _buildDevelopmentBanner(),
          _buildSearchBox(),
          Expanded(child: _buildList()),
        ],
      ),
    );
  }

  Widget _buildDevelopmentBanner() {
    return Container(
      width: double.infinity,
      color: AppColors.info.withValues(alpha: 0.1),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      child: Row(
        children: [
          Icon(Iconsax.info_circle, size: 16, color: AppColors.info),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Development Process',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.info,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
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
            'EXTENSIONS',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
              letterSpacing: 0.5,
            ),
          ),
          const Spacer(),
          _buildHeaderAction(Iconsax.refresh, () {}),
          _buildHeaderAction(Iconsax.filter, () {}),
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

  Widget _buildSearchBox() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: TextField(
        controller: _searchController,
        style: TextStyle(fontSize: 13, color: AppColors.textPrimary),
        decoration: InputDecoration(
          hintText: 'Search Extensions in Marketplace',
          hintStyle: TextStyle(fontSize: 13, color: AppColors.textMuted),
          filled: true,
          fillColor: AppColors.background,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 8,
          ),
          prefixIcon: Icon(
            Iconsax.search_normal,
            size: 14,
            color: AppColors.textMuted,
          ),
        ),
      ),
    );
  }

  Widget _buildList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 4),
      itemCount: _filteredExtensions.length,
      itemBuilder: (context, index) {
        return _buildExtensionItem(_filteredExtensions[index]);
      },
    );
  }

  Widget _buildExtensionItem(Extension ext) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.border.withValues(alpha: 0.5)),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            color: AppColors.surfaceLight,
            child: Icon(Iconsax.box_1, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        ext.name,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (ext.isInstalled)
                      Icon(
                        Iconsax.tick_circle,
                        size: 14,
                        color: AppColors.success,
                      ),
                  ],
                ),
                Text(
                  ext.description,
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      ext.author,
                      style: TextStyle(
                        fontSize: 10,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (!ext.isInstalled)
                      InkWell(
                        onTap: () {
                          setState(() => ext.isInstalled = true);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Installing ${ext.name}...'),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(2),
                          ),
                          child: Text(
                            'Install',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
