import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:dev_flow/core/utils/app_text_styles.dart';

class ProjectDetailsAppBar extends StatelessWidget {
  final VoidCallback onAddDesignSprintTemplate;
  final VoidCallback onAddProductLaunchTemplate;

  const ProjectDetailsAppBar({
    super.key,
    required this.onAddDesignSprintTemplate,
    required this.onAddProductLaunchTemplate,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
            onPressed: () => context.pop(),
          ),
          Expanded(
            child: Center(
              child: Text(
                'Project Details',
                style: AppTextStyles.headlineSmall.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onPressed: () => _showOptionsMenu(context),
          ),
        ],
      ),
    );
  }

  void _showOptionsMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.black,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.playlist_add, color: Colors.white),
                  title: const Text(
                    'Add Design Sprint template tasks',
                    style: TextStyle(color: Colors.white),
                  ),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    onAddDesignSprintTemplate();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.rocket_launch, color: Colors.white),
                  title: const Text(
                    'Add Product Launch template tasks',
                    style: TextStyle(color: Colors.white),
                  ),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    onAddProductLaunchTemplate();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
