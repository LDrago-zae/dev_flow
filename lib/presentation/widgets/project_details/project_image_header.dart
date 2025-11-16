import 'package:flutter/material.dart';
import 'package:dev_flow/core/constants/app_colors.dart';
import 'package:dev_flow/core/utils/app_text_styles.dart';
import 'package:dev_flow/data/models/project_model.dart';
import 'package:dev_flow/presentation/widgets/animated_fade_slide.dart';

class ProjectImageHeader extends StatelessWidget {
  final Project project;
  final VoidCallback onEditImage;

  const ProjectImageHeader({
    super.key,
    required this.project,
    required this.onEditImage,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedFadeSlide(
      delay: 0.0,
      duration: const Duration(milliseconds: 800),
      child: Stack(
        children: [
          Container(
            width: double.infinity,
            height: 200,
            decoration: const BoxDecoration(color: Colors.black),
            child: _buildImage(),
          ),
          // Priority Badge
          Positioned(top: 12, left: 12, child: _buildPriorityBadge()),
          // Edit Icon - Pick Image
          Positioned(bottom: 12, right: 12, child: _buildEditButton()),
        ],
      ),
    );
  }

  Widget _buildImage() {
    if (project.imagePath == null) {
      return _buildPlaceholder();
    }

    if (project.imagePath!.startsWith('http')) {
      return Image.network(
        project.imagePath!,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            color: project.cardColor.withOpacity(0.3),
            child: Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                    : null,
                color: DarkThemeColors.primary100,
              ),
            ),
          );
        },
      );
    }

    return Image.asset(
      project.imagePath!,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: project.cardColor.withOpacity(0.3),
      child: Icon(
        Icons.image_outlined,
        size: 64,
        color: DarkThemeColors.textSecondary,
      ),
    );
  }

  Widget _buildPriorityBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _getPriorityColor(project.priority),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        _getPriorityText(project.priority),
        style: AppTextStyles.bodySmall.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          fontSize: 11,
        ),
      ),
    );
  }

  Widget _buildEditButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onEditImage,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: DarkThemeColors.primary100,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Icon(Icons.edit, color: Colors.white, size: 16),
        ),
      ),
    );
  }

  Color _getPriorityColor(ProjectPriority priority) {
    switch (priority) {
      case ProjectPriority.high:
        return Colors.red;
      case ProjectPriority.medium:
        return Colors.orange;
      case ProjectPriority.low:
        return Colors.green;
    }
  }

  String _getPriorityText(ProjectPriority priority) {
    switch (priority) {
      case ProjectPriority.high:
        return 'High';
      case ProjectPriority.medium:
        return 'Medium';
      case ProjectPriority.low:
        return 'Low';
    }
  }
}
