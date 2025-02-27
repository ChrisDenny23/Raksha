// ignore_for_file: sort_child_properties_last, unused_local_variable

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:path_provider/path_provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:io';

class VideoListScreen extends StatelessWidget {
  final List<Map<String, dynamic>> videos = [
    {
      'title': 'Earthquake Safety Tips',
      'path': 'assets/videos/Earthquake_Safety_Tips.mp4',
      'thumbnail': 'assets/thumbnails/Earthquake.jpg'
    },
    {
      'title': 'Flood Safety Tips',
      'path': 'assets/videos/Flood.mp4',
      'thumbnail': 'assets/thumbnails/Flood.jpg'
    },
    {
      'title': 'Landslide Safety Tips',
      'path': 'assets/videos/Landslide.mp4',
      'thumbnail': 'assets/thumbnails/Landslide.jpg'
    },
    {
      'title': 'CPR Training',
      'path': 'assets/videos/CPR_Training.mp4',
      'thumbnail': 'assets/thumbnails/CPR.jpg'
    },
    {
      'title': 'Fire Safety',
      'path': 'assets/videos/Fire_Safety.mp4',
      'thumbnail': 'assets/thumbnails/Fire.jpg'
    },
    {
      'title': 'Tsunami Safety',
      'path': 'assets/videos/Tsunami.mp4',
      'thumbnail': 'assets/thumbnails/Tsunami.jpg'
    },
  ];

  VideoListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Safety Tips',
          style: TextStyle(
            fontFamily: 'Poppy',
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: isDark ? Colors.black : Colors.white,
        foregroundColor: isDark ? Colors.white : theme.primaryColor,
        elevation: 0,
      ),
      body: ListView.builder(
        itemCount: videos.length,
        itemBuilder: (context, index) {
          return VideoThumbnailCard(
            title: videos[index]['title'],
            videoPath: videos[index]['path'],
            thumbnailPath: videos[index]['thumbnail'],
          );
        },
      ),
    );
  }
}

class VideoThumbnailCard extends StatelessWidget {
  final String title;
  final String videoPath;
  final String thumbnailPath;

  const VideoThumbnailCard({
    super.key,
    required this.title,
    required this.videoPath,
    required this.thumbnailPath,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = const Color(0xFF2196F3); // AppThemes.primaryBlue

    return Card(
      margin: EdgeInsets.all(10),
      elevation: 2,
      color: isDark ? theme.cardColor : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => VideoPlayerScreen(
                videoPath: videoPath,
                title: title,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail image with fallback
            Stack(
              alignment: Alignment.center,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                  child: SizedBox(
                    height: 160,
                    width: double.infinity,
                    child: _buildThumbnail(),
                  ),
                ),
                Icon(
                  Icons.play_circle_filled,
                  size: 50,
                  color: Colors.white.withOpacity(0.8),
                ),
              ],
            ),
            // Title
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                children: [
                  Icon(
                    Icons.play_circle_filled,
                    size: 24,
                    color: primaryColor,
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontFamily: 'Poppy',
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: theme.textTheme.bodyLarge?.color,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThumbnail() {
    // Directly try to load the image, with fallback if it fails
    return Image.asset(
      thumbnailPath,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      errorBuilder: (context, error, stackTrace) {
        // If there's an error loading the asset, show fallback
        return _buildFallbackThumbnail(context);
      },
    );
  }

  Widget _buildFallbackThumbnail(BuildContext context) {
    final theme = Theme.of(context);
    // Create a fallback colored container based on the title
    final Color placeholderColor = _generateColorFromTitle(title);

    return Container(
      color: placeholderColor,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _getCategoryIcon(),
              size: 40,
              color: Colors.white,
            ),
            SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                title,
                style: TextStyle(
                  fontFamily: 'Poppy',
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getCategoryIcon() {
    // Return an appropriate icon based on the video title
    final String lowerTitle = title.toLowerCase();

    if (lowerTitle.contains('fire')) return Icons.local_fire_department;
    if (lowerTitle.contains('flood') || lowerTitle.contains('water')) {
      return Icons.water;
    }
    if (lowerTitle.contains('cpr') || lowerTitle.contains('training')) {
      return Icons.medical_services;
    }
    if (lowerTitle.contains('landslide')) return Icons.landscape;
    if (lowerTitle.contains('drowning')) return Icons.pool;
    if (lowerTitle.contains('cyclone')) return Icons.cyclone;
    if (lowerTitle.contains('chemical')) return Icons.science;
    if (lowerTitle.contains('tsunami')) return Icons.waves;
    if (lowerTitle.contains('transport')) return Icons.medical_services;
    if (lowerTitle.contains('bomb')) return Icons.warning;
    if (lowerTitle.contains('building')) return Icons.domain;

    // Default icon
    return Icons.warning;
  }

  // Generate a consistent color from the video title
  Color _generateColorFromTitle(String title) {
    int hash = 0;
    for (var i = 0; i < title.length; i++) {
      hash = title.codeUnitAt(i) + ((hash << 5) - hash);
    }

    final int r = ((hash & 0xFF0000) >> 16) & 0xFF;
    final int g = ((hash & 0x00FF00) >> 8) & 0xFF;
    final int b = hash & 0xFF;

    // Make sure the color is dark enough for white text
    return Color.fromARGB(
        255, (r * 0.7).round(), (g * 0.7).round(), (b * 0.7).round());
  }
}

class VideoPlayerScreen extends StatefulWidget {
  final String videoPath;
  final String title;

  const VideoPlayerScreen(
      {super.key, required this.videoPath, required this.title});

  @override
  _VideoPlayerScreenState createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  bool _isBuffering = false;
  bool _hasError = false;
  double _currentPosition = 0;
  double _totalDuration = 0;
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _initializeVideoPlayer();
  }

  Future<void> _initializeVideoPlayer() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = '';
    });

    try {
      print('Attempting to load video: ${widget.videoPath}');

      // Create the controller with error catching
      try {
        _controller = VideoPlayerController.asset(widget.videoPath);

        // Initialize with detailed error catching
        await _controller.initialize();
        print('Video successfully initialized: ${widget.videoPath}');

        if (mounted) {
          _controller.addListener(_videoListener);
          setState(() {
            _isInitialized = true;
            _isLoading = false;
            _totalDuration =
                _controller.value.duration.inMilliseconds.toDouble();
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _hasError = true;
            _isLoading = false;
            _errorMessage = 'Video initialization failed: $e';
          });
          print(_errorMessage);
        }
      }
    } catch (e) {
      print('Unhandled error in video initialization: $e');
      if (mounted) {
        setState(() {
          _hasError = true;
          _isLoading = false;
          _errorMessage = 'Unhandled error: $e';
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to load video: $e',
              style: TextStyle(fontFamily: 'PoppyLight'),
            ),
            duration: Duration(seconds: 5),
          ),
        );
      }
    }
  }

  void _videoListener() {
    if (mounted) {
      setState(() {
        _currentPosition = _controller.value.position.inMilliseconds.toDouble();
        _isBuffering = _controller.value.isBuffering;
      });
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "$twoDigitMinutes:$twoDigitSeconds";
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final backgroundColor =
        isDark ? Colors.black : theme.scaffoldBackgroundColor;
    final textColor = isDark ? Colors.white : theme.textTheme.bodyLarge?.color;
    final primaryColor = const Color(0xFF2196F3); // AppThemes.primaryBlue

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(
          widget.title,
          style: TextStyle(
            fontFamily: 'Poppy',
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: isDark ? Colors.black : Colors.white,
        foregroundColor: isDark ? Colors.white : primaryColor,
        elevation: 0,
      ),
      body: SafeArea(
        child: _buildContent(theme, textColor, primaryColor),
      ),
    );
  }

  Widget _buildContent(ThemeData theme, Color? textColor, Color accentColor) {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: accentColor),
            SizedBox(height: 16),
            Text(
              'Loading video...',
              style: TextStyle(
                fontFamily: 'PoppyLight',
                color: textColor?.withOpacity(0.7),
              ),
            ),
            Text(
              widget.videoPath,
              style: TextStyle(
                fontFamily: 'PoppyLight',
                color: textColor?.withOpacity(0.5),
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
    }

    if (_hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: theme.colorScheme.error, size: 48),
            SizedBox(height: 16),
            Text(
              'Failed to load video',
              style: TextStyle(
                fontFamily: 'Poppy',
                color: textColor,
                fontSize: 18,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                _errorMessage,
                style: TextStyle(
                  fontFamily: 'PoppyLight',
                  color: textColor?.withOpacity(0.7),
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            SizedBox(height: 8),
            ElevatedButton(
              onPressed: _initializeVideoPlayer,
              child: Text(
                'Retry',
                style: TextStyle(fontFamily: 'Poppy'),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: accentColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            SizedBox(height: 16),
            OutlinedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text(
                'Go Back',
                style: TextStyle(
                  fontFamily: 'Poppy',
                  color: textColor,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(
                    color: textColor?.withOpacity(0.7) ?? Colors.grey),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (_isInitialized) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: Center(
              child: AspectRatio(
                aspectRatio: _controller.value.aspectRatio,
                child: Stack(
                  alignment: Alignment.bottomCenter,
                  children: [
                    VideoPlayer(_controller),
                    if (_isBuffering)
                      Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      ),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              children: [
                // Progress bar
                Slider(
                  value: _currentPosition,
                  min: 0,
                  max: _totalDuration > 0 ? _totalDuration : 1,
                  activeColor: accentColor,
                  inactiveColor: theme.brightness == Brightness.dark
                      ? Colors.grey.shade800
                      : Colors.grey.shade300,
                  onChanged: (value) {
                    setState(() {
                      _currentPosition = value;
                      _controller.seekTo(Duration(milliseconds: value.toInt()));
                    });
                  },
                ),
                // Duration display
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _formatDuration(_controller.value.position),
                        style: TextStyle(
                          fontFamily: 'PoppyLight',
                          color: textColor?.withOpacity(0.7),
                        ),
                      ),
                      Text(
                        _formatDuration(_controller.value.duration),
                        style: TextStyle(
                          fontFamily: 'PoppyLight',
                          color: textColor?.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                // Controls
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      IconButton(
                        icon: Icon(Icons.replay_10, color: textColor),
                        onPressed: () {
                          final newPosition = _controller.value.position -
                              Duration(seconds: 10);
                          _controller.seekTo(newPosition);
                        },
                      ),
                      IconButton(
                        icon: Icon(
                          _controller.value.isPlaying
                              ? Icons.pause_circle_filled
                              : Icons.play_circle_filled,
                          color: accentColor,
                          size: 56,
                        ),
                        onPressed: () {
                          setState(() {
                            _controller.value.isPlaying
                                ? _controller.pause()
                                : _controller.play();
                          });
                        },
                      ),
                      IconButton(
                        icon: Icon(Icons.forward_10, color: textColor),
                        onPressed: () {
                          final newPosition = _controller.value.position +
                              Duration(seconds: 10);
                          _controller.seekTo(newPosition);
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    // Fallback
    return Center(
      child: CircularProgressIndicator(color: accentColor),
    );
  }

  @override
  void dispose() {
    if (_isInitialized) {
      _controller.removeListener(_videoListener);
      _controller.pause();
      _controller.dispose();
    }
    super.dispose();
  }
}
