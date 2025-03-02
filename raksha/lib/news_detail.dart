import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

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
                  errorBuilder: (context, error, stackTrace) {
                    return Container(height: 0);
                  },
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

  NewsItem({
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
