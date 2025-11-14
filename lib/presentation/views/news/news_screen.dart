import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:dev_flow/core/constants/app_colors.dart';
import 'package:dev_flow/core/utils/app_text_styles.dart';
import 'package:dev_flow/data/models/news_model.dart';
import 'package:dev_flow/services/news_service.dart';
import 'package:dev_flow/presentation/widgets/custom_search_bar.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:skeletonizer/skeletonizer.dart';

class NewsScreen extends StatefulWidget {
  const NewsScreen({super.key});

  @override
  State<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen>
    with SingleTickerProviderStateMixin {
  final NewsService _newsService = NewsService();
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  late AnimationController _animationController;
  List<NewsArticle> _articles = [];
  List<NewsArticle> _filteredArticles = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  String? _error;
  int _currentPage = 1;
  String _searchQuery = '';
  String _selectedCategory = 'All';

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _loadNews();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent * 0.8 &&
        !_isLoadingMore &&
        _searchQuery.isEmpty) {
      _loadMoreNews();
    }
  }

  Future<void> _loadNews({bool refresh = false}) async {
    if (refresh) {
      setState(() {
        _currentPage = 1;
        _articles.clear();
        _filteredArticles.clear();
        _isLoading = true;
      });
      _animationController.reset();
    }

    try {
      final articles = await _newsService.getTechNews(
        page: _currentPage,
        query: _searchQuery.isEmpty ? null : _searchQuery,
      );

      setState(() {
        if (refresh) {
          _articles = articles;
        } else {
          _articles.addAll(articles);
        }
        _filteredArticles = _articles;
        _isLoading = false;
        _error = null;
      });

      // Start animation after data is loaded
      _animationController.forward();
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _loadMoreNews() async {
    if (_isLoadingMore) return;

    setState(() {
      _isLoadingMore = true;
    });

    try {
      _currentPage++;
      final articles = await _newsService.getTechNews(
        page: _currentPage,
        query: _searchQuery.isEmpty ? null : _searchQuery,
      );

      setState(() {
        _articles.addAll(articles);
        _filteredArticles = _articles;
        _isLoadingMore = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingMore = false;
        _currentPage--; // Revert page on error
      });
    }
  }

  void _onSearch(String query) {
    setState(() {
      _searchQuery = query;
    });
    _loadNews(refresh: true);
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _searchQuery = '';
    });
    _loadNews(refresh: true);
  }

  Widget _buildCategoryChips() {
    final categories = ['All', 'AI & ML', 'Startups', 'Mobile', 'Security'];

    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = _selectedCategory == category;
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  setState(() {
                    _selectedCategory = category;
                  });
                  _filterByCategory(category);
                },
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? DarkThemeColors.primary100
                        : Colors.black,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected
                          ? DarkThemeColors.primary100
                          : DarkThemeColors.border,
                      width: 1,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      category,
                      style: TextStyle(
                        color: isSelected ? Colors.black : Colors.white,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _filterByCategory(String category) {
    if (category == 'All') {
      // Load general tech news
      _searchQuery = '';
      _loadNews(refresh: true);
    } else {
      // Search for category-specific news
      _searchQuery = category;
      _loadNews(refresh: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Column(
              children: [
                // Header with title and search
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      Text(
                        'Discover',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'New articles',
                        style: TextStyle(
                          color: DarkThemeColors.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Search Bar
                      CustomSearchBar(
                        controller: _searchController,
                        hintText: 'Search tech news...',
                        onChanged: (value) {
                          if (value.isEmpty) {
                            _clearSearch();
                          }
                        },
                        onSubmitted: _onSearch,
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 20),
                                onPressed: _clearSearch,
                                color: DarkThemeColors.textSecondary,
                              )
                            : null,
                      ),
                    ],
                  ),
                ),

                // Category Chips
                _buildCategoryChips(),

                const SizedBox(height: 16),

                // Content
                Expanded(child: _buildContent(constraints)),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildContent(BoxConstraints constraints) {
    if (_error != null && _articles.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: DarkThemeColors.error),
              const SizedBox(height: 16),
              Text(
                'Failed to load news',
                style: AppTextStyles.headlineSmall.copyWith(
                  color: DarkThemeColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _error!,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: DarkThemeColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => _loadNews(refresh: true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: DarkThemeColors.primary100,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_filteredArticles.isEmpty && !_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.article_outlined,
              size: 64,
              color: DarkThemeColors.textSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              'No news found',
              style: AppTextStyles.headlineSmall.copyWith(
                color: DarkThemeColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your search',
              style: AppTextStyles.bodyMedium.copyWith(
                color: DarkThemeColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    // Show skeleton articles when loading
    final articlesToDisplay = _isLoading && _filteredArticles.isEmpty
        ? List.generate(
            5,
            (index) => NewsArticle(
              title: 'Loading News Article Title',
              description: 'Loading article description and preview text here',
              url: '',
              urlToImage: 'https://via.placeholder.com/400x200',
              publishedAt: DateTime.now(),
              sourceName: 'Loading Source',
              author: 'Loading Author',
              content: 'Loading content',
            ),
          )
        : _filteredArticles;

    return Skeletonizer(
      enabled: _isLoading && _filteredArticles.isEmpty,
      child: RefreshIndicator(
        onRefresh: () => _loadNews(refresh: true),
        color: DarkThemeColors.primary100,
        backgroundColor: DarkThemeColors.surface,
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            // Featured Article (First article with large image)
            if (articlesToDisplay.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  child: SlideTransition(
                    position:
                        Tween<Offset>(
                          begin: const Offset(0, 0.3),
                          end: Offset.zero,
                        ).animate(
                          CurvedAnimation(
                            parent: _animationController,
                            curve: const Interval(
                              0.0,
                              0.3,
                              curve: Curves.easeOut,
                            ),
                          ),
                        ),
                    child: FadeTransition(
                      opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
                        CurvedAnimation(
                          parent: _animationController,
                          curve: const Interval(0.0, 0.3, curve: Curves.easeIn),
                        ),
                      ),
                      child: _FeaturedNewsCard(
                        article: articlesToDisplay[0],
                        onTap: () {
                          if (!_isLoading) {
                            context.push(
                              '/news/${Uri.encodeComponent(articlesToDisplay[0].url)}',
                              extra: articlesToDisplay[0],
                            );
                          }
                        },
                      ),
                    ),
                  ),
                ),
              ),

            // Rest of the articles in a masonry grid
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final articleIndex = index + 1; // Skip first article
                  if (articleIndex >= articlesToDisplay.length) {
                    return _isLoadingMore
                        ? const Padding(
                            padding: EdgeInsets.all(16),
                            child: Center(child: CircularProgressIndicator()),
                          )
                        : const SizedBox.shrink();
                  }

                  // Calculate stagger delay for animation
                  final double delay = 0.3 + (index * 0.1);
                  final double endDelay = delay + 0.2;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: SlideTransition(
                      position:
                          Tween<Offset>(
                            begin: const Offset(0, 0.2),
                            end: Offset.zero,
                          ).animate(
                            CurvedAnimation(
                              parent: _animationController,
                              curve: Interval(
                                delay.clamp(0.0, 1.0),
                                endDelay.clamp(0.0, 1.0),
                                curve: Curves.easeOut,
                              ),
                            ),
                          ),
                      child: FadeTransition(
                        opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
                          CurvedAnimation(
                            parent: _animationController,
                            curve: Interval(
                              delay.clamp(0.0, 1.0),
                              endDelay.clamp(0.0, 1.0),
                              curve: Curves.easeIn,
                            ),
                          ),
                        ),
                        child: _CompactNewsCard(
                          article: articlesToDisplay[articleIndex],
                          onTap: () {
                            if (!_isLoading) {
                              context.push(
                                '/news/${Uri.encodeComponent(articlesToDisplay[articleIndex].url)}',
                                extra: articlesToDisplay[articleIndex],
                              );
                            }
                          },
                        ),
                      ),
                    ),
                  );
                }, childCount: articlesToDisplay.length),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Featured News Card (Modern magazine-style with side image)
class _FeaturedNewsCard extends StatelessWidget {
  final NewsArticle article;
  final VoidCallback onTap;

  const _FeaturedNewsCard({required this.article, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 180,
        decoration: BoxDecoration(
          color: DarkThemeColors.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            // Image Section (40% width)
            if (article.urlToImage != null && article.urlToImage!.isNotEmpty)
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                ),
                child: CachedNetworkImage(
                  imageUrl: article.urlToImage!,
                  width: MediaQuery.of(context).size.width * 0.35,
                  height: 180,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    width: MediaQuery.of(context).size.width * 0.35,
                    color: DarkThemeColors.border,
                    child: Center(
                      child: CircularProgressIndicator(
                        color: DarkThemeColors.primary100,
                        strokeWidth: 2,
                      ),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    width: MediaQuery.of(context).size.width * 0.35,
                    color: DarkThemeColors.border,
                    child: Icon(
                      Icons.image_not_supported,
                      color: DarkThemeColors.textSecondary,
                      size: 32,
                    ),
                  ),
                ),
              ),

            // Content Section (60% width)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Category Badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: DarkThemeColors.primary100.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'FEATURED',
                            style: TextStyle(
                              color: DarkThemeColors.primary100,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Title
                        Text(
                          article.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            height: 1.3,
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),

                    // Bottom info
                    Row(
                      children: [
                        if (article.sourceName != null) ...[
                          Flexible(
                            child: Text(
                              article.sourceName!,
                              style: TextStyle(
                                color: DarkThemeColors.textSecondary,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            ' • ',
                            style: TextStyle(
                              color: DarkThemeColors.textSecondary,
                              fontSize: 11,
                            ),
                          ),
                        ],
                        Text(
                          article.formattedDate,
                          style: TextStyle(
                            color: DarkThemeColors.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
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

// Compact News Card (Modern list-style with larger image)
class _CompactNewsCard extends StatelessWidget {
  final NewsArticle article;
  final VoidCallback onTap;

  const _CompactNewsCard({required this.article, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: DarkThemeColors.surface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            if (article.urlToImage != null && article.urlToImage!.isNotEmpty)
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
                child: CachedNetworkImage(
                  imageUrl: article.urlToImage!,
                  width: double.infinity,
                  height: 160,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    height: 160,
                    color: DarkThemeColors.border,
                    child: Center(
                      child: CircularProgressIndicator(
                        color: DarkThemeColors.primary100,
                        strokeWidth: 2,
                      ),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    height: 160,
                    color: DarkThemeColors.border,
                    child: Icon(
                      Icons.image_not_supported,
                      color: DarkThemeColors.textSecondary,
                      size: 40,
                    ),
                  ),
                ),
              ),

            // Content
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Source and time
                  Row(
                    children: [
                      if (article.sourceName != null) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: DarkThemeColors.border,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            article.sourceName!.toUpperCase(),
                            style: TextStyle(
                              color: DarkThemeColors.textSecondary,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      if (article.formattedDate.isNotEmpty)
                        Flexible(
                          child: Row(
                            children: [
                              Icon(
                                Icons.access_time,
                                size: 12,
                                color: DarkThemeColors.textSecondary,
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  article.formattedDate,
                                  style: TextStyle(
                                    color: DarkThemeColors.textSecondary,
                                    fontSize: 11,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Title
                  Text(
                    article.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  // Description
                  if (article.description != null && article.description!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      article.description!,
                      style: TextStyle(
                        color: DarkThemeColors.textSecondary,
                        fontSize: 13,
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  
                  const SizedBox(height: 8),
                  
                  // Read more indicator
                  Row(
                    children: [
                      Text(
                        'Read more',
                        style: TextStyle(
                          color: DarkThemeColors.primary100,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.arrow_forward,
                        size: 12,
                        color: DarkThemeColors.primary100,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
