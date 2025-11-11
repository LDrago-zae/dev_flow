import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../data/models/news_model.dart';

class NewsService {
  final Dio _dio = Dio();
  static const String _baseUrl = 'https://newsapi.org/v2';

  NewsService() {
    _dio.options.baseUrl = _baseUrl;
    _dio.options.connectTimeout = const Duration(seconds: 10);
    _dio.options.receiveTimeout = const Duration(seconds: 10);
    _dio.options.headers = {'Content-Type': 'application/json'};
  }

  /// Fetch tech news articles
  Future<List<NewsArticle>> getTechNews({
    int page = 1,
    int pageSize = 20,
    String? query,
  }) async {
    try {
      final apiKey = dotenv.env['NEWS_API'];
      if (apiKey == null || apiKey.isEmpty) {
        throw Exception('NEWS_API_KEY not found in .env file');
      }

      String endpoint;
      Map<String, dynamic> queryParams = {
        'apiKey': apiKey,
        'page': page,
        'pageSize': pageSize,
        'language': 'en',
        'sortBy': 'publishedAt',
      };

      if (query != null && query.isNotEmpty) {
        // Search endpoint for custom queries
        endpoint = '/everything';
        queryParams['q'] = query;
        queryParams['domains'] =
            'techcrunch.com,theverge.com,arstechnica.com,wired.com,engadget.com';
      } else {
        // Top headlines for tech category
        endpoint = '/top-headlines';
        queryParams['category'] = 'technology';
        queryParams['country'] = 'us';
      }

      final response = await _dio.get(endpoint, queryParameters: queryParams);

      if (response.statusCode == 200) {
        final newsResponse = NewsResponse.fromJson(response.data);
        // Filter out articles without title or url
        return newsResponse.articles
            .where(
              (article) => article.title.isNotEmpty && article.url.isNotEmpty,
            )
            .toList();
      } else {
        throw Exception('Failed to fetch news: ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw Exception(
          'Connection timeout. Please check your internet connection.',
        );
      } else if (e.type == DioExceptionType.badResponse) {
        throw Exception('Server error: ${e.response?.statusCode}');
      } else {
        throw Exception('Failed to fetch news: ${e.message}');
      }
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }

  /// Search news articles
  Future<List<NewsArticle>> searchNews(String query, {int page = 1}) async {
    return getTechNews(query: query, page: page);
  }
}
