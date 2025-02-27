import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class NewsPage extends StatefulWidget {
  const NewsPage({super.key});

  @override
  State<NewsPage> createState() => _NewsPageState();
}

class _NewsPageState extends State<NewsPage> {
  bool _mounted = true;
  List<NewsItem> _newsItems = [];
  bool _isLoading = true;
  bool _showDisasterOnly = true; // Toggle between disaster and general news
  List<NewsItem> _disasterNewsItems = []; // Store disaster news items
  List<NewsItem> _generalNewsItems = []; // Store general news items

  @override
  void initState() {
    super.initState();
    _loadMockNews();
  }

  @override
  void dispose() {
    _mounted = false;
    super.dispose();
  }

  // Get appropriate icon based on news category/keywords
  // ignore: unused_element
  IconData _getIconForNews(String title, String description) {
    final String combinedText = (title + description).toLowerCase();

    if (combinedText.contains('flood') || combinedText.contains('rain')) {
      return Icons.water;
    } else if (combinedText.contains('earthquake')) {
      return Icons.vibration;
    } else if (combinedText.contains('fire')) {
      return Icons.local_fire_department;
    } else if (combinedText.contains('storm') ||
        combinedText.contains('cyclone') ||
        combinedText.contains('hurricane') ||
        combinedText.contains('typhoon')) {
      return Icons.cyclone;
    } else if (combinedText.contains('landslide')) {
      return Icons.landscape;
    } else if (combinedText.contains('drought')) {
      return Icons.wb_sunny;
    } else if (combinedText.contains('covid') ||
        combinedText.contains('virus') ||
        combinedText.contains('outbreak') ||
        combinedText.contains('pandemic')) {
      return Icons.coronavirus;
    } else if (combinedText.contains('politics') ||
        combinedText.contains('government')) {
      return Icons.account_balance;
    } else if (combinedText.contains('business') ||
        combinedText.contains('economy')) {
      return Icons.business;
    } else if (combinedText.contains('tech') ||
        combinedText.contains('technology')) {
      return Icons.computer;
    } else if (combinedText.contains('sports') ||
        combinedText.contains('cricket')) {
      return Icons.sports_cricket;
    } else if (combinedText.contains('entertainment') ||
        combinedText.contains('film')) {
      return Icons.movie;
    } else {
      return Icons.article;
    }
  }

  // Load mock news data
  void _loadMockNews() {
    if (!_mounted) return;

    setState(() {
      _isLoading = true;
    });

    // Simulate network delay
    Future.delayed(const Duration(seconds: 1), () {
      // Disaster news
      final List<NewsItem> mockDisasterNewsItems = [
        NewsItem(
          title: 'Floods in Kerala: Thousands Evacuated',
          description:
              'Heavy rainfall has caused severe flooding in Kerala, with thousands evacuated to relief camps. Local authorities have issued warnings for residents in low-lying areas to move to safer locations. Relief operations are underway with the help of national disaster response teams.',
          url: 'https://example.com/news/1',
          icon: Icons.water,
          time: DateTime.now().subtract(const Duration(hours: 2)),
          isDisaster: true,
          content:
              'Heavy rainfall over the past 48 hours has triggered severe flooding in multiple districts of Kerala, forcing authorities to evacuate thousands of residents to emergency relief camps. The state government has deployed disaster response teams to the worst-affected areas.\n\nWater levels in major rivers including the Periyar and Chalakudy have risen to dangerous levels. Several bridges have been submerged, and road connectivity to many villages has been cut off. Rescue operations are being conducted using boats and helicopters.\n\n"This is one of the worst floods we have seen in recent years," said the state\'s disaster management official. "We are working around the clock to ensure everyone\'s safety."\n\nThe meteorological department has predicted more rainfall in the coming days, raising concerns of further flooding. Residents are advised to follow official guidelines and emergency protocols.',
        ),
        NewsItem(
          title: 'Forest Fire in Uttarakhand',
          description:
              'A massive forest fire has broken out in the hills of Uttarakhand. Firefighters are working to contain it. Several hectares of forest land have been affected.',
          url: 'https://example.com/news/2',
          icon: Icons.local_fire_department,
          time: DateTime.now().subtract(const Duration(hours: 4)),
          isDisaster: true,
          content:
              'A large-scale forest fire has engulfed parts of Uttarakhand\'s pine forests, spreading rapidly due to dry conditions and strong winds. The fire, which started yesterday evening, has already consumed several hectares of valuable forest land.\n\nOver 200 firefighters and forest department personnel have been deployed to battle the blaze. Helicopters have been called in to conduct water-bombing operations in hard-to-reach areas.\n\n"The terrain makes this particularly challenging," explained the Chief Forest Conservator. "We have created fire lines to prevent further spread and are working non-stop to bring the situation under control."\n\nLocal communities have been put on high alert, with some villages near the forest edge being evacuated as a precautionary measure. Officials are concerned about air quality deterioration in nearby towns and cities.\n\nThe cause of the fire is still under investigation, though officials suspect it may have been triggered by human activity. This incident highlights the increasing vulnerability of Himalayan forests to fire hazards, especially during the dry pre-monsoon months.',
        ),
        NewsItem(
          title: 'Cyclone Warning for East Coast',
          description:
              'Meteorological Department has issued a cyclone warning for the eastern coastal areas. Residents advised to stay indoors and follow safety protocols.',
          url: 'https://example.com/news/3',
          icon: Icons.cyclone,
          time: DateTime.now().subtract(const Duration(hours: 8)),
          isDisaster: true,
          content:
              'The India Meteorological Department has issued a severe cyclone warning for the eastern coastal regions, with the storm expected to make landfall within the next 36 hours. Wind speeds could reach up to 120-130 km/h, accompanied by heavy rainfall.\n\nAuthorities have begun evacuating residents from vulnerable coastal villages to storm shelters. Fishing activities have been suspended, and fishermen have been advised not to venture into the sea. Emergency response teams are being positioned in strategic locations.\n\n"We are fully prepared to handle this situation," assured the Disaster Management Secretary. "Our priority is to ensure zero casualties."\n\nThe cyclone is expected to cause significant damage to infrastructure, including power lines and communication networks. Residents are advised to stock up on essential supplies and follow official communications.',
        ),
      ];

      // General news
      final List<NewsItem> mockGeneralNewsItems = [
        NewsItem(
          title: 'India\'s Economy Shows Signs of Growth',
          description:
              'The Indian economy has shown promising signs of growth in the last quarter, according to new reports. Experts predict continued improvement.',
          url: 'https://example.com/news/4',
          icon: Icons.business,
          time: DateTime.now().subtract(const Duration(hours: 1)),
          isDisaster: false,
          content:
              'India\'s economy has registered a remarkable 7.8% growth in the last quarter, exceeding most analyst predictions. This surge represents the highest growth rate in the past two years and positions India as one of the fastest-growing major economies globally.\n\nThe growth has been primarily driven by increased manufacturing output, robust service sector performance, and higher consumer spending. Foreign direct investment has also seen a significant uptick, particularly in technology and infrastructure sectors.\n\n"These numbers reflect the success of recent economic reforms and strategic policy decisions," commented the Finance Minister during a press conference. "We expect this momentum to continue in the coming quarters."\n\nMarket analysts have responded positively to the news, with stock indices reaching new highs. Several international organizations have revised their annual growth projections for India upward following this report.\n\nHowever, challenges remain, including inflation concerns and uneven regional development. The government has announced plans to address these issues through targeted interventions while maintaining the overall growth trajectory.',
        ),
        NewsItem(
          title: 'New Tech Campus Opens in Bangalore',
          description:
              'A major tech company has opened its new campus in Bangalore, creating thousands of jobs. The facility will focus on AI and machine learning research.',
          url: 'https://example.com/news/5',
          icon: Icons.computer,
          time: DateTime.now().subtract(const Duration(hours: 3)),
          isDisaster: false,
          content:
              'A leading global technology company has inaugurated its state-of-the-art campus in Bangalore\'s Electronic City, marking one of the largest tech investments in the city in recent years. The campus, spanning over 40 acres, will house more than 15,000 employees when fully operational.\n\nThe facility will serve as the company\'s artificial intelligence and machine learning research hub, focusing on developing cutting-edge solutions for global markets. It features sustainable design elements, including solar power generation and water recycling systems.\n\n"This campus represents our long-term commitment to India\'s digital future," said the company\'s CEO during the inauguration ceremony. "The talent pool here is exceptional, and we\'re excited to tap into it."\n\nLocal officials welcomed the development, noting its potential to create a ripple effect in the region\'s economy. Beyond direct employment, the campus is expected to generate thousands of additional jobs in supporting industries and services.\n\nThe company has also announced partnerships with several local universities to establish research collaborations and internship programs, further strengthening the local tech ecosystem.',
        ),
        NewsItem(
          title: 'Cricket Team Announces New Captain',
          description:
              'The Indian cricket board has announced a new captain for the upcoming series. The decision comes after much speculation within cricket circles.',
          url: 'https://example.com/news/6',
          icon: Icons.sports_cricket,
          time: DateTime.now().subtract(const Duration(hours: 5)),
          isDisaster: false,
          content:
              'In a move that has stirred excitement across the cricketing world, the Indian cricket board has appointed a new captain to lead the national team in the upcoming international series. The announcement follows weeks of speculation and debate among fans and experts alike.\n\nThe newly appointed captain, a consistent performer with an impressive track record, has been with the team for over eight years and has previously served as vice-captain. Cricket analysts have praised the decision, citing the player\'s tactical acumen and leadership qualities.\n\n"This is one of the greatest honors of my career," the new captain stated in a press conference. "I am committed to taking our team to new heights and making our nation proud."\n\nThe outgoing captain, who led the team for five years, will continue to play as a senior batsman. In a social media post, they expressed full support for their successor and pledged to contribute to the team\'s success in their new role.\n\nThe first assignment under the new captaincy will be a challenging away series, followed by a major tournament later in the year. Selectors have also announced some fresh faces in the squad, signaling a period of transition and renewal for the team.',
        ),
        NewsItem(
          title: 'New Film Breaks Box Office Records',
          description:
              'A recently released Bollywood film has broken all previous box office records in its opening weekend. Critics have praised the storyline and performances.',
          url: 'https://example.com/news/7',
          icon: Icons.movie,
          time: DateTime.now().subtract(const Duration(hours: 6)),
          isDisaster: false,
          content:
              'The latest blockbuster from one of Bollywood\'s most celebrated directors has shattered all previous box office records, collecting an unprecedented ₹150 crore in its opening weekend alone. The film, featuring an ensemble cast of top actors, has been running to packed houses across the country.\n\nCritics have hailed the movie as a landmark in Indian cinema, praising its innovative storytelling, exceptional performances, and state-of-the-art visual effects. Audience reactions have been overwhelmingly positive, with the film scoring high on various review platforms.\n\n"We always believed in the power of this story," the director shared during a success celebration. "But the response has exceeded our wildest expectations."\n\nThe film, which took three years to produce, tackles several contemporary social issues while delivering engaging entertainment. Industry analysts project it will set new benchmarks for total collections and overseas performance.\n\nThe unprecedented success has already triggered discussions about a sequel, with the production house hinting at potential developments in the near future. Meanwhile, the film continues its strong performance in theaters, with advance bookings still showing robust numbers.',
        ),
        NewsItem(
          title: 'Government Announces New Educational Policy',
          description:
              'The Indian government has announced a new educational policy aimed at improving the quality of education. The policy focuses on skill development and practical learning.',
          url: 'https://example.com/news/8',
          icon: Icons.account_balance,
          time: DateTime.now().subtract(const Duration(hours: 7)),
          isDisaster: false,
          content:
              'In a significant development for the education sector, the government has unveiled a comprehensive new education policy designed to transform the learning landscape across the country. The policy, which comes after extensive consultations with experts and stakeholders, aims to make education more holistic, flexible, and aligned with 21st-century needs.\n\nKey highlights of the policy include emphasis on practical skill development, reduced examination pressure, multiple entry and exit options in higher education, and integration of vocational education from an early stage. The policy also promotes multilingualism and the use of technology in teaching and assessment.\n\n"This marks a paradigm shift in how we approach education," the Education Minister explained at the policy launch. "Our focus is on creating well-rounded individuals rather than rote learners."\n\nThe implementation will be phased, with changes in curriculum and pedagogical approaches beginning next academic year. Teacher training programs will be revamped to prepare educators for the new methodologies.\n\nEducationists have generally welcomed the move, though some have expressed concerns about implementation challenges, particularly in rural areas. The government has assured that special provisions will be made to ensure equitable access across all regions and socioeconomic groups.',
        ),
      ];

      if (_mounted) {
        setState(() {
          // Store news items in separate lists
          _disasterNewsItems = mockDisasterNewsItems;
          _generalNewsItems = mockGeneralNewsItems;

          // Set news items based on current toggle state
          if (_showDisasterOnly) {
            _newsItems = List.from(_disasterNewsItems);
          } else {
            _newsItems = List.from(_generalNewsItems);
          }

          _isLoading = false;
        });
      }
    });
  }

  void _toggleNewsType() {
    setState(() {
      _showDisasterOnly = !_showDisasterOnly;

      if (_showDisasterOnly) {
        // Show disaster news only
        if (_disasterNewsItems.isEmpty) {
          _newsItems = [
            NewsItem(
              title: 'No Disaster Alerts',
              description:
                  'Currently there are no major disaster alerts reported in India.',
              url: '',
              icon: Icons.check_circle,
              time: DateTime.now(),
              isDisaster: true,
              content: '',
            )
          ];
        } else {
          _newsItems = List.from(_disasterNewsItems);
        }
      } else {
        // Show general news only
        if (_generalNewsItems.isEmpty) {
          _newsItems = [
            NewsItem(
              title: 'No News Available',
              description: 'No news articles are currently available.',
              url: '',
              icon: Icons.info_outline,
              time: DateTime.now(),
              isDisaster: false,
              content: '',
            )
          ];
        } else {
          _newsItems = List.from(_generalNewsItems);
        }
      }
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
    Color cardBorderColor = item.isDisaster ? Colors.red : Colors.blue;
    Color iconColor = item.isDisaster ? Colors.red : Colors.blue;

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
        child: Padding(
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
                  const Icon(Icons.arrow_forward, color: Colors.blue, size: 16),
                ],
              ),
              if (item.isDisaster) ...[
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () async {
                _loadMockNews();
              },
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
                              color:
                                  _showDisasterOnly ? Colors.red : Colors.blue,
                              size: 24,
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                _showDisasterOnly
                                    ? 'India Disaster Alerts'
                                    : 'India News Headlines',
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
                        onChanged: (value) => _toggleNewsType(),
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
                          color: _showDisasterOnly ? Colors.red : Colors.blue,
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
                                child:
                                    _buildNewsCard(_newsItems[index], context),
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

// News detail page
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
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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

  NewsItem({
    required this.title,
    required this.description,
    required this.url,
    required this.icon,
    required this.time,
    required this.isDisaster,
    required this.content,
  });
}
