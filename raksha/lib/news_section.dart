import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class NewsPage extends StatefulWidget {
  const NewsPage({super.key});

  @override
  State<NewsPage> createState() => _NewsPageState();
}

class _NewsPageState extends State<NewsPage> {
  bool _mounted = true;
  List<NewsItem> _newsItems = [];
  bool _isLoading = true;
  bool _showDisasterOnly = true;
  List<NewsItem> _disasterNewsItems = [];
  List<NewsItem> _generalNewsItems = [];
  String _errorMessage = '';

  // News API configuration
  final String _apiKey = 'f82374814ea84371833c5fc4db4972e2';
  final String _baseUrl = 'https://newsapi.org/v2/';

  @override
  void initState() {
    super.initState();
    _fetchNews();
  }

  @override
  void dispose() {
    _mounted = false;
    super.dispose();
  }

  // Optimized icon selection with map lookup
  IconData _getIconForNews(String title, String description) {
    final String combinedText = (title + description).toLowerCase();

    final Map<String, IconData> iconMap = {
      'flood': Icons.water,
      'rain': Icons.water,
      'earthquake': Icons.vibration,
      'fire': Icons.local_fire_department,
      'storm': Icons.cyclone,
      'cyclone': Icons.cyclone,
      'hurricane': Icons.cyclone,
      'typhoon': Icons.cyclone,
      'landslide': Icons.landscape,
      'drought': Icons.wb_sunny,
      'covid': Icons.coronavirus,
      'virus': Icons.coronavirus,
      'outbreak': Icons.coronavirus,
      'pandemic': Icons.coronavirus,
      'politics': Icons.account_balance,
      'government': Icons.account_balance,
      'business': Icons.business,
      'economy': Icons.business,
      'tech': Icons.computer,
      'technology': Icons.computer,
      'sports': Icons.sports_cricket,
      'cricket': Icons.sports_cricket,
      'entertainment': Icons.movie,
      'film': Icons.movie,
      'movie': Icons.movie,
    };

    for (final entry in iconMap.entries) {
      if (combinedText.contains(entry.key)) {
        return entry.value;
      }
    }

    return Icons.article;
  }

  // Optimized disaster news detection with a set lookup
  final Set<String> _disasterKeywords = {
    'flood',
    'earthquake',
    'fire',
    'storm',
    'cyclone',
    'hurricane',
    'typhoon',
    'landslide',
    'drought',
    'disaster',
    'emergency',
    'evacuation',
    'tsunami',
    'volcanic',
    'eruption',
    'outbreak',
    'pandemic',
    'accident',
    'collapse',
    'explosion',
    'crash',
    'catastrophe',
    'severe weather',
    'extreme weather',
    'wildfire',
    'casualties',
    'relief effort',
    'rescue operation',
    'warning issued',
    'alert issued',
    'damage reported'
  };

  bool _isDisasterContent(String content) {
    final lowerContent = content.toLowerCase();
    return _disasterKeywords.any((keyword) => lowerContent.contains(keyword));
  }

  // Fetch news from the API with improved error handling and timeout
  Future<void> _fetchNews() async {
    if (!_mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // Fetch general news globally instead of country-specific
      final generalResponse = await http
          .get(
            Uri.parse('${_baseUrl}top-headlines?language=en&apiKey=$_apiKey'),
          )
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () =>
                throw Exception('Connection timeout. Please try again.'),
          );

      // Fetch disaster/emergency news
      final disasterResponse = await http
          .get(
            Uri.parse(
                '${_baseUrl}everything?q=disaster OR emergency OR flood OR earthquake&language=en&sortBy=publishedAt&apiKey=$_apiKey'),
          )
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () =>
                throw Exception('Connection timeout. Please try again.'),
          );

      if (!_mounted) return;

      if (generalResponse.statusCode == 200 &&
          disasterResponse.statusCode == 200) {
        final generalData = json.decode(generalResponse.body);
        final disasterData = json.decode(disasterResponse.body);

        _processGeneralNews(generalData);
        _processDisasterNews(disasterData);

        if (_mounted) {
          setState(() {
            _newsItems = _showDisasterOnly
                ? List.from(_disasterNewsItems)
                : List.from(_generalNewsItems);
            _isLoading = false;
          });
        }
      } else {
        if (_mounted) {
          setState(() {
            _errorMessage =
                'API Error: ${generalResponse.statusCode}. ${_parseErrorResponse(generalResponse.body)}';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (_mounted) {
        setState(() {
          _errorMessage = 'Network error: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }

  // Added error response parsing for better error messages
  String _parseErrorResponse(String body) {
    try {
      final data = json.decode(body);
      return data['message'] ?? 'Unknown error';
    } catch (_) {
      return 'Could not parse error response';
    }
  }

  // Optimized news processing with null safety
  void _processGeneralNews(Map<String, dynamic> data) {
    if (data['status'] == 'ok' && data['articles'] != null) {
      final List<dynamic> articles = data['articles'];
      _generalNewsItems = articles.map<NewsItem>((article) {
        final DateTime publishDate = _parseDateTime(article['publishedAt']);
        final String title = article['title'] ?? 'No Title';
        final String description =
            article['description'] ?? 'No description available';

        return NewsItem(
          title: title,
          description: description,
          url: article['url'] ?? '',
          icon: _getIconForNews(title, description),
          time: publishDate,
          isDisaster: false,
          content: article['content'] ?? description,
          imageUrl: article['urlToImage'],
          source: article['source']?['name'] ?? 'Unknown Source',
        );
      }).toList();
    }
  }

  void _processDisasterNews(Map<String, dynamic> data) {
    if (data['status'] == 'ok' && data['articles'] != null) {
      final List<dynamic> articles = data['articles'];

      _disasterNewsItems = articles.where((article) {
        final String title = article['title'] ?? '';
        final String description = article['description'] ?? '';
        final String content = article['content'] ?? '';

        final String combinedText =
            (title + description + content).toLowerCase();
        return _isDisasterContent(combinedText);
      }).map<NewsItem>((article) {
        final DateTime publishDate = _parseDateTime(article['publishedAt']);
        final String title = article['title'] ?? 'No Title';
        final String description =
            article['description'] ?? 'No description available';

        return NewsItem(
          title: title,
          description: description,
          url: article['url'] ?? '',
          icon: _getIconForNews(title, description),
          time: publishDate,
          isDisaster: true,
          content: article['content'] ?? description,
          imageUrl: article['urlToImage'],
          source: article['source']?['name'] ?? 'Unknown Source',
        );
      }).toList();

      if (_disasterNewsItems.isEmpty) {
        _disasterNewsItems = [
          NewsItem(
            title: 'No Disaster Alerts',
            description:
                'Currently there are no major disaster alerts reported.',
            url: '',
            icon: Icons.check_circle,
            time: DateTime.now(),
            isDisaster: true,
            content: 'No disaster alerts at this time. Stay safe!',
            source: 'Disaster Alert System',
          )
        ];
      }
    }
  }

  // Helper for parsing dates with error handling
  DateTime _parseDateTime(String? dateString) {
    if (dateString == null) return DateTime.now();

    try {
      return DateTime.parse(dateString);
    } catch (_) {
      return DateTime.now();
    }
  }

  void _toggleNewsType() {
    setState(() {
      _showDisasterOnly = !_showDisasterOnly;
      _newsItems = _showDisasterOnly
          ? List.from(_disasterNewsItems)
          : List.from(_generalNewsItems);
    });
  }

  void _openFullNewsPage(BuildContext context, NewsItem item) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NewsDetailPage(newsItem: item),
      ),
    );
  }

  Widget _buildNewsCard(NewsItem item, BuildContext context) {
    final Color cardBorderColor = item.isDisaster ? Colors.red : Colors.blue;
    final Color iconColor = item.isDisaster ? Colors.red : Colors.blue;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: BorderSide(
            color: cardBorderColor, width: item.isDisaster ? 1.5 : 0.5),
      ),
      child: InkWell(
        onTap: () => _openFullNewsPage(context, item),
        borderRadius: BorderRadius.circular(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (item.imageUrl != null && item.imageUrl!.isNotEmpty)
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(15),
                  topRight: Radius.circular(15),
                ),
                child: Image.network(
                  item.imageUrl!,
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(height: 0),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(item.icon, color: iconColor, size: 24),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          item.title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Source: ${item.source}',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 13,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    item.description,
                    style: const TextStyle(fontSize: 16),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        DateFormat('MMM d, yyyy - h:mm a')
                            .format(item.time.toLocal()),
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                      const Icon(Icons.arrow_forward,
                          color: Colors.blue, size: 16),
                    ],
                  ),
                  if (item.isDisaster) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.red, width: 0.5),
                      ),
                      child: const Text(
                        'ALERT',
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: Colors.red,
                        size: 48,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Error loading news',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _errorMessage,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _fetchNews,
                        child: const Text('Try Again'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _fetchNews,
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Icon(
                                  _showDisasterOnly
                                      ? Icons.warning_amber
                                      : Icons.newspaper,
                                  color: _showDisasterOnly
                                      ? Colors.red
                                      : Colors.blue,
                                  size: 24,
                                ),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    _showDisasterOnly
                                        ? 'Disaster Alerts'
                                        : 'News Headlines',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: _showDisasterOnly
                                          ? Colors.red
                                          : Colors.blue,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Switch(
                            value: _showDisasterOnly,
                            activeColor: Colors.red,
                            activeTrackColor: Colors.red.withOpacity(0.5),
                            inactiveThumbColor: Colors.blue,
                            inactiveTrackColor: Colors.blue.withOpacity(0.5),
                            onChanged: (_) => _toggleNewsType(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              'Last updated: ${DateFormat('MMM d, yyyy - h:mm a').format(DateTime.now().toLocal())}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            _showDisasterOnly ? 'Alerts Only' : 'General News',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color:
                                  _showDisasterOnly ? Colors.red : Colors.blue,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: _newsItems.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      _showDisasterOnly
                                          ? Icons.check_circle
                                          : Icons.article_outlined,
                                      size: 48,
                                      color: _showDisasterOnly
                                          ? Colors.green
                                          : Colors.blue,
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      _showDisasterOnly
                                          ? 'No disaster alerts at this time'
                                          : 'No news articles available',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Pull down to refresh',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : ListView.builder(
                                itemCount: _newsItems.length,
                                itemBuilder: (context, index) {
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: _buildNewsCard(
                                        _newsItems[index], context),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
    );
  }
}

class NewsDetailPage extends StatelessWidget {
  final NewsItem newsItem;

  const NewsDetailPage({super.key, required this.newsItem});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          newsItem.isDisaster ? 'Disaster Alert' : 'News Article',
          style: TextStyle(
            color: newsItem.isDisaster ? Colors.red : Colors.blue,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: newsItem.isDisaster
            ? Colors.red.withOpacity(0.1)
            : Colors.blue.withOpacity(0.1),
        iconTheme: IconThemeData(
          color: newsItem.isDisaster ? Colors.red : Colors.blue,
        ),
        actions: [
          if (newsItem.url.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.open_in_browser),
              onPressed: () {
                // You'll need to add the url_launcher package for this functionality
                // launchUrl(Uri.parse(newsItem.url));
              },
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (newsItem.imageUrl != null && newsItem.imageUrl!.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  newsItem.imageUrl!,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(height: 0),
                ),
              ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(
                  newsItem.icon,
                  color: newsItem.isDisaster ? Colors.red : Colors.blue,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    newsItem.title,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Source: ${newsItem.source}',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 12),
            if (newsItem.isDisaster)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.red, width: 0.5),
                ),
                child: const Text(
                  'DISASTER ALERT',
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            const SizedBox(height: 16),
            Text(
              'Published: ${DateFormat('MMMM d, yyyy - h:mm a').format(newsItem.time.toLocal())}',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              newsItem.description,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            Text(
              newsItem.content,
              style: const TextStyle(
                fontSize: 16,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            if (newsItem.isDisaster)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Safety Information',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '• Stay tuned to official emergency broadcasts\n'
                      '• Follow evacuation orders immediately if issued\n'
                      '• Keep emergency contacts and supplies ready\n'
                      '• Check on vulnerable neighbors if safe to do so\n'
                      '• Report any emergency situations to authorities',
                      style: TextStyle(fontSize: 15),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}

class NewsItem {
  final String title;
  final String description;
  final String url;
  final IconData icon;
  final DateTime time;
  final bool isDisaster;
  final String content;
  final String? imageUrl;
  final String source;

  const NewsItem({
    required this.title,
    required this.description,
    required this.url,
    required this.icon,
    required this.time,
    required this.isDisaster,
    required this.content,
    this.imageUrl,
    required this.source,
  });
}
