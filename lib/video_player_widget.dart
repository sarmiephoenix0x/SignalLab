import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class VideoPlayerWidget extends StatefulWidget {
  final String videoUrl;

  const VideoPlayerWidget({required this.videoUrl});

  @override
  VideoPlayerWidgetState createState() => VideoPlayerWidgetState();
}

class VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  late YoutubePlayerController _youtubeController;
  bool _isError = false;

  @override
  void initState() {
    super.initState();
    _initializeYoutubePlayer();
  }

  void _initializeYoutubePlayer() {
    try {
      final videoId = YoutubePlayer.convertUrlToId(widget.videoUrl);
      if (videoId != null) {
        _youtubeController = YoutubePlayerController(
          initialVideoId: videoId,
          flags: YoutubePlayerFlags(
            autoPlay: true,
            mute: false,
          ),
        );
        _isError = false;
      } else {
        setState(() {
          _isError = true;
        });
      }
    } catch (e) {
      setState(() {
        _isError = true;
      });
      print("Error loading YouTube video: $e");
    }
  }

  @override
  void dispose() {
    _youtubeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, color: Colors.red, size: 50),
            const SizedBox(height: 10),
            const Text(
              'Failed to load the video',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                fontFamily: 'Inconsolata',
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _isError = false; // Hide the error message and show loader
                });
                _initializeYoutubePlayer(); // Retry loading the video
              },
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.black,
              ), // Retry loading the video
              child: const Text(
                'Retry',
                style: TextStyle(
                  fontFamily: 'Inconsolata',
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return YoutubePlayer(
      controller: _youtubeController,
      showVideoProgressIndicator: true,
      progressIndicatorColor: Colors.black,
      onReady: () {
        print('YouTube Player Ready');
      },
      onEnded: (metadata) {
        // You can handle video end logic here if needed
      },
    );
  }
}
