import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../config/app_config.dart';
import '../../providers/auth_provider.dart';
import 'video_player_screen.dart';
import 'audio_player_screen.dart';
import '../../services/api_service.dart';

class DirectorFeedbackScreen extends StatefulWidget {
  const DirectorFeedbackScreen({super.key});

  @override
  State<DirectorFeedbackScreen> createState() => _DirectorFeedbackScreenState();
}

class _DirectorFeedbackScreenState extends State<DirectorFeedbackScreen> {
  List<dynamic> feedbackList = [];
  List<dynamic> eventsList = [];
  bool isLoading = true;
  bool isEventsLoading = true;
  String? selectedEventId;
  bool _isDownloading = false;

  @override
  void initState() {
    super.initState();
    fetchEvents();
    fetchFeedback();
  }

  Future<void> fetchEvents() async {
    try {
      final response = await ApiService.get('/events/list.php');
      if (!mounted) return;
      if (response.data != null && response.data['success']) {
        setState(() {
          eventsList = response.data['data'] ?? [];
          isEventsLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        isEventsLoading = false;
      });
      // Silently fail events fetch
    }
  }

  Future<void> fetchFeedback() async {
    if (!mounted) return;
    setState(() => isLoading = true);
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.user?.id;
      
      String url = '/director/get_feedback.php?user_id=$userId';
      if (selectedEventId != null) {
        url += '&event_id=$selectedEventId';
      }

      final response = await ApiService.get(url);
      if (!mounted) return;
      final data = response.data;
      if (data['success']) {
        setState(() {
          feedbackList = data['data'] ?? [];
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load feedback: $e')),
        );
      }
    }
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('MMM d, yyyy • h:mm a').format(date);
    } catch (e) {
      return dateString;
    }
  }

  Future<void> _launchVideo(String videoPath) async {
    final url = '${AppConfig.apiUrl}/$videoPath';
    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => VideoPlayerScreen(videoUrl: url),
        ),
      );
    }
  }
  
  Future<void> _launchAudio(String audioPath) async {
    final url = '${AppConfig.apiUrl}/$audioPath';
    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AudioPlayerScreen(audioUrl: url),
        ),
      );
    }
  }

  Future<void> _downloadMedia(String path, String type) async {
    setState(() => _isDownloading = true);
    try {
      Directory dir = await getTemporaryDirectory();
      String ext = type == 'video' ? 'mp4' : 'm4a';
      String fileName = 'GMU_Alumni_Feedback_${DateTime.now().millisecondsSinceEpoch}.$ext';
      String savePath = '${dir.path}/$fileName';

      Dio dio = Dio();
      final url = '${AppConfig.apiUrl}/$path';
      await dio.download(url, savePath);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('File ready! Choose "Save to device" or share it.'), backgroundColor: Colors.green),
        );
      }
      await Share.shareXFiles([XFile(savePath)], text: 'Alumni Feedback $type');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Download failed: $e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isDownloading = false);
    }
  }

  void _showStudentDetails(BuildContext context, Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Alumni Details', style: TextStyle(color: AppConfig.primaryColor, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _detailRow('Name', data['name']?.toString() ?? 'N/A'),
            _detailRow('USN', (data['usn'] ?? data['submitter_identifier'])?.toString() ?? 'N/A'),
            _detailRow('Branch', data['branch']?.toString() ?? 'N/A'),
            _detailRow('Batch', data['batch']?.toString() ?? 'N/A'),
            _detailRow('Phone', data['phone']?.toString() ?? 'N/A'),
            _detailRow('Position', data['current_position']?.toString() ?? 'N/A'),
            _detailRow('Institute', data['institute']?.toString() ?? 'N/A'),
          ],
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(color: Colors.black87, fontSize: 14),
          children: [
            TextSpan(text: '$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }

  Widget _buildFeedbackCard(Map<String, dynamic> feedback, int index) {
    final name = feedback['name'] ?? 'Alumnus';
    final usn = feedback['usn'] ?? feedback['submitter_identifier'] ?? '';
    final profilePic = feedback['profile_picture'];
    final rating = feedback['rating'] ?? 0;
    final createdAt = feedback['created_at'] ?? '';
    final mediaPath = feedback['video_path'];
    final eventTitle = feedback['event_title'];
    
    // Parse feedback JSON
    List<Map<String, String>> questions = [];
    String mode = 'text'; // Default
    
    try {
      if (feedback['feedback_text'] != null && feedback['feedback_text'].isNotEmpty) {
        final decoded = jsonDecode(feedback['feedback_text']);
        if (decoded is Map) {
          if (decoded.containsKey('mode')) {
            mode = decoded['mode'];
          }
          
          if (mode == 'text') {
            int index = 1;
            while (decoded.containsKey('question_$index')) {
              questions.add({
                'question': decoded['question_$index'].toString(),
                'answer': decoded['answer_$index']?.toString() ?? '',
              });
              index++;
            }
          }
        }
      } else if (mediaPath != null && mediaPath.isNotEmpty) {
         // Legacy feedback with video
         mode = 'video';
      }
    } catch (e) {
      print('Failed to parse feedback text: $e');
    }

    bool isAudio = mediaPath != null && (mediaPath.endsWith('.m4a') || mediaPath.endsWith('.mp3') || mediaPath.endsWith('.aac') || mediaPath.endsWith('.wav'));
    bool isVideo = mediaPath != null && !isAudio && mediaPath.isNotEmpty;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: AppConfig.primaryColor.withOpacity(0.1),
                  backgroundImage: (profilePic != null && profilePic.isNotEmpty)
                      ? CachedNetworkImageProvider(AppConfig.getProfileImageUrl(profilePic))
                      : null,
                  child: (profilePic == null || profilePic.isEmpty)
                      ? Text(
                          name.substring(0, 1).toUpperCase(),
                          style: const TextStyle(
                            color: AppConfig.primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GestureDetector(
                        onTap: () => _showStudentDetails(context, feedback),
                        child: Text(
                          name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold, 
                            fontSize: 16,
                            color: AppConfig.primaryColor,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                      if (usn.isNotEmpty)
                        Text(
                          'USN: $usn',
                          style: TextStyle(color: Colors.grey[600], fontSize: 13),
                        ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.star_rounded, color: Colors.amber, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        '$rating/5',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.amber,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (eventTitle != null && eventTitle.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blueGrey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.event, size: 14, color: Colors.blueGrey),
                    const SizedBox(width: 6),
                    Text(
                      eventTitle,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blueGrey),
                    ),
                  ],
                ),
              ),
            
            if (mode == 'video') ...[
              InkWell(
                onTap: () => _launchVideo(mediaPath!),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade100),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.videocam, color: Colors.blue),
                      SizedBox(width: 8),
                      Text('Video Feedback Attached', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ] else if (mode == 'audio' || isAudio) ...[
               InkWell(
                onTap: () => _launchAudio(mediaPath!),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.shade100),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.mic, color: Colors.orange),
                      SizedBox(width: 8),
                      Text('Audio Feedback Attached', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ] else if (questions.isNotEmpty) ...[
              const Divider(height: 1),
              const SizedBox(height: 12),
              ...questions.asMap().entries.map((entry) {
                int idx = entry.key;
                var q = entry.value;
                bool isLast = idx == questions.length - 1;
                return Padding(
                  padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        q['question'] ?? 'Question',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: AppConfig.primaryColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        (q['answer'] != null && q['answer']!.isNotEmpty) 
                            ? q['answer']! 
                            : 'No response',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[800],
                          fontStyle: (q['answer'] == null || q['answer']!.isEmpty)
                              ? FontStyle.italic 
                              : FontStyle.normal,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ],
            
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _formatDate(createdAt),
                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Wrap(
                    alignment: WrapAlignment.end,
                    spacing: 4.0,
                    runSpacing: 4.0,
                    children: [
                      if (isVideo) ...[
                        TextButton.icon(
                          onPressed: _isDownloading ? null : () => _downloadMedia(mediaPath!, 'video'),
                          icon: const Icon(Icons.download_rounded, size: 18),
                          label: const Text('Download'),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.blue,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        )
                      ] else if (isAudio) ...[
                        TextButton.icon(
                          onPressed: _isDownloading ? null : () => _downloadMedia(mediaPath!, 'audio'),
                          icon: const Icon(Icons.download_rounded, size: 18),
                          label: const Text('Download'),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.orange,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        )
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConfig.bgLight,
      appBar: AppBar(
        title: const Text('Alumni Feedback'),
        centerTitle: true,
        backgroundColor: AppConfig.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Event Filter Dropdown
          if (!isEventsLoading && eventsList.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: selectedEventId,
                    hint: const Text('All Events (General Feedback)'),
                    icon: const Icon(Icons.filter_list, color: AppConfig.primaryColor),
                    items: [
                      const DropdownMenuItem<String>(
                        value: null,
                        child: Text('All Events (General Feedback)'),
                      ),
                      ...eventsList.map((event) {
                        return DropdownMenuItem<String>(
                          value: event['id'].toString(),
                          child: Text(
                            event['title'] ?? 'Event ${event['id']}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                    ],
                    onChanged: (value) {
                      setState(() {
                        selectedEventId = value;
                      });
                      fetchFeedback();
                    },
                  ),
                ),
              ),
            ),
          
          Expanded(
            child: RefreshIndicator(
              onRefresh: fetchFeedback,
              color: AppConfig.primaryColor,
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : feedbackList.isEmpty
                      ? CustomScrollView(
                    slivers: [
                      SliverFillRemaining(
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.feedback_outlined, size: 80, color: Colors.grey[300]),
                              const SizedBox(height: 16),
                              Text(
                                'No feedback yet',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[400],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  )
                : AnimationLimiter(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: feedbackList.length,
                      itemBuilder: (context, index) {
                        return AnimationConfiguration.staggeredList(
                          position: index,
                          duration: const Duration(milliseconds: 375),
                          child: SlideAnimation(
                            verticalOffset: 50.0,
                            child: FadeInAnimation(
                              child: _buildFeedbackCard(feedbackList[index], index),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
          ],
      ),
    );
  }
}
