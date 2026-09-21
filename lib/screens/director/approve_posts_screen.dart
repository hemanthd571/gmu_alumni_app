import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../config/app_config.dart';

class ApprovePostsScreen extends StatefulWidget {
  const ApprovePostsScreen({super.key});

  @override
  State<ApprovePostsScreen> createState() => _ApprovePostsScreenState();
}

class _ApprovePostsScreenState extends State<ApprovePostsScreen> {
  List<dynamic> _pendingPosts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchPendingPosts();
  }

  Future<void> _fetchPendingPosts() async {
    try {
      final dio = Dio(BaseOptions(baseUrl: AppConfig.apiUrl));
      final response = await dio.get('/director/get_pending_posts.php');

      if (response.data['success']) {
        setState(() {
          _pendingPosts = response.data['data'];
          _isLoading = false;
        });
      } else {
        print('Failed to fetch pending posts: ${response.statusCode} ${response.data}');
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print('Error fetching pending posts: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updatePostStatus(String postId, String action) async {
    // Optimistic update
    setState(() {
      _pendingPosts.removeWhere((post) => post['id'].toString() == postId);
    });

    try {
      final dio = Dio(BaseOptions(baseUrl: AppConfig.apiUrl));
      await dio.post('/director/update_post_status.php', data: {
        'post_id': postId,
        'action': action,
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(action == 'approve' ? 'Post Approved' : 'Post Rejected'),
          backgroundColor: action == 'approve' ? Colors.green : Colors.red,
          duration: const Duration(seconds: 1),
        ),
      );
    } catch (e) {
      // Revert if failed (omitted for brevity, but good practice)
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to $action post'), backgroundColor: Colors.red),
      );
      _fetchPendingPosts(); // Refresh to ensure valid state
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConfig.bgLight,
      appBar: AppBar(
        title: const Text('Approve Posts'),
        backgroundColor: AppConfig.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _pendingPosts.isEmpty
              ? const Center(child: Text('No pending posts'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _pendingPosts.length,
                  itemBuilder: (context, index) {
                    final post = _pendingPosts[index];
                    return _buildPostCard(post);
                  },
                ),
    );
  }

  Widget _buildPostCard(Map<String, dynamic> post) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppConfig.primaryColor.withOpacity(0.2), width: 2),
                  ),
                  child: CircleAvatar(
                    radius: 22,
                    backgroundColor: Colors.grey[100],
                    backgroundImage: post['author_image'] != null
                        ? CachedNetworkImageProvider(AppConfig.getProfileImageUrl(post['author_image']))
                        : null,
                    child: post['author_image'] == null 
                        ? Icon(Icons.person_rounded, color: Colors.grey[400]) 
                        : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post['author_name'] ?? 'Unknown User',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppConfig.textColor),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(Icons.access_time_rounded, size: 12, color: Colors.grey[400]),
                          const SizedBox(width: 4),
                          Text(
                            post['created_at'] ?? '',
                            style: TextStyle(color: Colors.grey[500], fontSize: 12, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.hourglass_empty_rounded, size: 12, color: Colors.orange),
                      const SizedBox(width: 4),
                      const Text(
                        'Pending',
                        style: TextStyle(color: Colors.orange, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (post['content'] != null && post['content'].toString().isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Text(
                post['content'],
                style: const TextStyle(fontSize: 15, height: 1.5, color: Colors.black87),
              ),
            ),
          const SizedBox(height: 16),
          if (post['image_url'] != null && post['image_url'].toString().isNotEmpty)
            Container(
              width: double.infinity,
              height: 250,
              decoration: BoxDecoration(
                color: Colors.grey[50],
                border: Border(
                  top: BorderSide(color: Colors.grey[100]!),
                  bottom: BorderSide(color: Colors.grey[100]!),
                ),
              ),
              child: CachedNetworkImage(
                imageUrl: AppConfig.getPostImageUrl(post['image_url']),
                fit: BoxFit.cover,
                placeholder: (context, url) => Center(child: Icon(Icons.image, size: 50, color: Colors.grey[300])),
                errorWidget: (context, url, error) => Center(child: Icon(Icons.broken_image, size: 50, color: Colors.grey[300])),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _updatePostStatus(post['id'].toString(), 'reject'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.red,
                      elevation: 0,
                      side: BorderSide(color: Colors.red.withOpacity(0.5)),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.close_rounded, size: 20),
                        SizedBox(width: 8),
                        Text('Reject', style: TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _updatePostStatus(post['id'].toString(), 'approve'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shadowColor: Colors.green.withOpacity(0.4),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_rounded, size: 20),
                        SizedBox(width: 8),
                        Text('Approve', style: TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
