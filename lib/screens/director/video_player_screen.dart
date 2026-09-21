import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../config/app_config.dart';

class VideoPlayerScreen extends StatefulWidget {
  final String videoUrl;

  const VideoPlayerScreen({super.key, required this.videoUrl});

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late VideoPlayerController _controller;
  bool _isError = false;
  bool _isDownloading = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl))
      ..initialize().then((_) {
        setState(() {});
        _controller.play();
      }).catchError((error) {
        setState(() {
          _isError = true;
        });
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _downloadVideo() async {
    setState(() {
      _isDownloading = true;
    });

    try {
      // Download to temporary directory to bypass Android 11+ Scoped Storage restrictions
      Directory dir = await getTemporaryDirectory();
      String fileName = 'GMU_Alumni_Video_${DateTime.now().millisecondsSinceEpoch}.mp4';
      String savePath = '${dir.path}/$fileName';

      // Download file directly
      Dio dio = Dio();
      await dio.download(widget.videoUrl, savePath);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Video ready! Choose "Save to device" or share it.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }
      
      // Open the share sheet so the user can save it to their gallery or share it
      await Share.shareXFiles([XFile(savePath)], text: 'Alumni Feedback Video');

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Download failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isDownloading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Video Playback'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        actions: [
          _isDownloading
              ? const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  ),
                )
              : IconButton(
                  icon: const Icon(Icons.download),
                  tooltip: 'Download Video',
                  onPressed: _downloadVideo,
                ),
        ],
      ),
      body: Center(
        child: _isError 
            ? const Text(
                'Failed to load video',
                style: TextStyle(color: Colors.white),
              )
            : _controller.value.isInitialized
                ? AspectRatio(
                    aspectRatio: _controller.value.aspectRatio,
                    child: Stack(
                      alignment: Alignment.bottomCenter,
                      children: [
                        VideoPlayer(_controller),
                        VideoProgressIndicator(_controller, allowScrubbing: true),
                        Center(
                          child: IconButton(
                            iconSize: 64,
                            color: Colors.white.withOpacity(0.7),
                            icon: Icon(
                              _controller.value.isPlaying ? Icons.pause_circle : Icons.play_circle,
                            ),
                            onPressed: () {
                              setState(() {
                                _controller.value.isPlaying
                                    ? _controller.pause()
                                    : _controller.play();
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  )
                : const CircularProgressIndicator(color: AppConfig.primaryColor),
      ),
    );
  }
}
