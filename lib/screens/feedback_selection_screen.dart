import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import 'package:go_router/go_router.dart';
import '../config/app_config.dart';

class FeedbackSelectionScreen extends StatefulWidget {
  final int? eventId;
  const FeedbackSelectionScreen({super.key, this.eventId});

  @override
  State<FeedbackSelectionScreen> createState() => _FeedbackSelectionScreenState();
}

class _FeedbackSelectionScreenState extends State<FeedbackSelectionScreen> {
  final ImagePicker _picker = ImagePicker();
  File? _recordedVideo;
  VideoPlayerController? _videoController;
  bool _isInitializing = false;
  bool _hasError = false;

  Future<void> _recordVideo() async {
    try {
      final XFile? video = await _picker.pickVideo(
        source: ImageSource.camera,
        maxDuration: const Duration(minutes: 2),
      );

      if (video != null) {
        setState(() {
          _recordedVideo = File(video.path);
          _hasError = false;
        });
        _initializeVideoPlayer(_recordedVideo!);
      }
    } catch (e) {
      setState(() {
        _hasError = true;
      });
    }
  }

  void _initializeVideoPlayer(File file) {
    setState(() {
      _isInitializing = true;
    });

    _videoController?.dispose();
    _videoController = VideoPlayerController.file(file)
      ..initialize().then((_) {
        setState(() {
          _isInitializing = false;
        });
        _videoController!.play();
      }).catchError((error) {
        setState(() {
          _isInitializing = false;
          _hasError = true;
        });
      });
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEFE8DE),
      appBar: AppBar(
        backgroundColor: AppConfig.primaryColor,
        elevation: 0,
        title: const Text(
          'Feedback Method',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_recordedVideo != null) {
      if (_isInitializing || _videoController == null || !_videoController!.value.isInitialized) {
        return const Center(child: CircularProgressIndicator(color: AppConfig.primaryColor));
      }

      return Column(
        children: [
          Expanded(
            child: Container(
              color: Colors.black,
              child: Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  Center(
                    child: AspectRatio(
                      aspectRatio: _videoController!.value.aspectRatio,
                      child: VideoPlayer(_videoController!),
                    ),
                  ),
                  VideoProgressIndicator(_videoController!, allowScrubbing: true),
                  Center(
                    child: IconButton(
                      iconSize: 64,
                      color: Colors.white.withOpacity(0.7),
                      icon: Icon(
                        _videoController!.value.isPlaying ? Icons.pause_circle : Icons.play_circle,
                      ),
                      onPressed: () {
                        setState(() {
                          _videoController!.value.isPlaying
                              ? _videoController!.pause()
                              : _videoController!.play();
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _recordVideo,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppConfig.primaryColor,
                      side: const BorderSide(color: AppConfig.primaryColor),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Retake'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      _videoController?.pause();
                      context.push('/feedback-questions', extra: {
                        'mode': 'video', 
                        'file': _recordedVideo,
                        'event_id': widget.eventId,
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppConfig.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Confirm'),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF9F6F0), Color(0xFFEBE0D2)],
        ),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: AppConfig.primaryColor.withOpacity(0.08),
                  blurRadius: 24,
                  spreadRadius: 4,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.rate_review_rounded,
                  size: 48,
                  color: AppConfig.primaryColor,
                ),
                const SizedBox(height: 24),
                const Text(
                  'How would you like to share your feedback?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppConfig.primaryColor,
                    fontFamily: 'Georgia',
                  ),
                ),
                const SizedBox(height: 32),
                _buildOptionCard(
                  icon: Icons.videocam_rounded,
                  title: 'Video',
                  subtitle: 'Record a short video message',
                  onTap: _recordVideo,
                ),
                const SizedBox(height: 16),
                _buildOptionCard(
                  icon: Icons.mic_rounded,
                  title: 'Audio',
                  subtitle: 'Record a voice message',
                  onTap: () {
                    context.push('/record-audio', extra: widget.eventId);
                  },
                ),
                const SizedBox(height: 16),
                _buildOptionCard(
                  icon: Icons.notes_rounded,
                  title: 'Text',
                  subtitle: 'Write your thoughts',
                  onTap: () {
                    context.push('/feedback-questions', extra: {
                      'mode': 'text', 
                      'file': null,
                      'event_id': widget.eventId,
                    });
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOptionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: AppConfig.primaryColor.withOpacity(0.3), width: 2),
          borderRadius: BorderRadius.circular(16),
          color: AppConfig.primaryColor.withOpacity(0.05),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppConfig.primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppConfig.primaryColor, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppConfig.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, color: AppConfig.primaryColor, size: 20),
          ],
        ),
      ),
    );
  }
}
