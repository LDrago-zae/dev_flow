import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:dev_flow/core/constants/app_colors.dart';
import 'package:dev_flow/core/utils/app_text_styles.dart';
import 'package:dev_flow/data/models/news_model.dart';
import 'package:dev_flow/presentation/widgets/responsive_layout.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/services.dart';

class NewsDetailScreen extends StatefulWidget {
  final NewsArticle article;

  const NewsDetailScreen({super.key, required this.article});

  @override
  State<NewsDetailScreen> createState() => _NewsDetailScreenState();
}

class _NewsDetailScreenState extends State<NewsDetailScreen> {
  @override
  void initState() {
    super.initState();
  }

  Future<void> _openArticle(BuildContext context) async {
    final uri = Uri.parse(widget.article.url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Could not open article'),
            backgroundColor: DarkThemeColors.error,
          ),
        );
      }
    }
  }

  Future<void> _shareArticle() async {
    try {
      await Clipboard.setData(ClipboardData(text: widget.article.url));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Article link copied to clipboard'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to copy link'),
            backgroundColor: DarkThemeColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // App Bar
            SliverAppBar(
              expandedHeight: 300,
              pinned: true,
              backgroundColor: Colors.black,
              leading: IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: DarkThemeColors.surface,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.arrow_back,
                    color: DarkThemeColors.textPrimary,
                  ),
                ),
                onPressed: () => Navigator.of(context).pop(),
              ),
              actions: [
                IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: DarkThemeColors.surface,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.share_outlined,
                      color: DarkThemeColors.textPrimary,
                    ),
                  ),
                  onPressed: _shareArticle,
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background:
                    widget.article.urlToImage != null &&
                        widget.article.urlToImage!.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: widget.article.urlToImage!,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: DarkThemeColors.border,
                          child: Center(
                            child: CircularProgressIndicator(
                              color: DarkThemeColors.primary100,
                            ),
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: DarkThemeColors.border,
                          child: Icon(
                            Icons.image_not_supported,
                            color: DarkThemeColors.textSecondary,
                            size: 64,
                          ),
                        ),
                      )
                    : Container(
                        color: DarkThemeColors.surface,
                        child: Icon(
                          Icons.article,
                          size: 64,
                          color: DarkThemeColors.textSecondary,
                        ),
                      ),
              ),
            ),

            // Content
            SliverToBoxAdapter(
              child: ResponsiveLayout(
                padding: const EdgeInsets.all(20),
                centerContent: true,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Source and Date
                    Row(
                      children: [
                        if (widget.article.sourceName != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: DarkThemeColors.primary100.withOpacity(
                                0.2,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              widget.article.sourceName!,
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: DarkThemeColors.primary100,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        if (widget.article.sourceName != null)
                          const SizedBox(width: 12),
                        if (widget.article.formattedDate.isNotEmpty)
                          Text(
                            widget.article.formattedDate,
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: DarkThemeColors.textSecondary,
                            ),
                          ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Title
                    Text(
                      widget.article.title,
                      style: AppTextStyles.headlineLarge.copyWith(
                        color: DarkThemeColors.textPrimary,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    if (widget.article.author != null) ...[
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Icon(
                            Icons.person_outline,
                            size: 20,
                            color: DarkThemeColors.textSecondary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            widget.article.author!,
                            style: AppTextStyles.bodyLarge.copyWith(
                              color: DarkThemeColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],

                    const SizedBox(height: 24),

                    // Description
                    if (widget.article.description != null &&
                        widget.article.description!.isNotEmpty) ...[
                      Text(
                        widget.article.description!,
                        style: AppTextStyles.bodyLarge.copyWith(
                          color: DarkThemeColors.textPrimary,
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Content
                    if (widget.article.content != null &&
                        widget.article.content!.isNotEmpty) ...[
                      Text(
                        widget.article.content!
                            .replaceAll(RegExp(r'\[.*?\]'), '')
                            .trim(),
                        style: AppTextStyles.bodyLarge.copyWith(
                          color: DarkThemeColors.textPrimary,
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Read More Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => _openArticle(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: DarkThemeColors.primary100,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              'Read Full Article',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(Icons.open_in_new, size: 20),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
