import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../config/app_config.dart';
import '../models/post_model.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';

class PostsScreen extends StatefulWidget {
  const PostsScreen({super.key});

  @override
  State<PostsScreen> createState() => _PostsScreenState();
}

class _PostsScreenState extends State<PostsScreen> {
  List<PostModel> posts = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchPosts();
  }

  Future<void> fetchPosts() async {
    if (!mounted) return;
    setState(() => isLoading = true);
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.user?.id;
      
      final response = await ApiService.get('/posts/list.php?user_id=$userId');
      if (!mounted) return;
      final data = response.data;
      if (data['success']) {
        setState(() {
          posts = (data['data'] as List)
              .map((json) => PostModel.fromJson(json))
              .toList();
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading posts: $e')),
        );
      }
    }
  }

  Future<void> likePost(int postId, int index) async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.user?.id ?? '1';
      
      final response = await ApiService.post('/posts/like.php', data: {
        'user_id': int.parse(userId),
        'post_id': postId,
      });
      
      if (!mounted) return;
      final data = response.data;
      if (data['success']) {
        setState(() {
          final post = posts[index];
          posts[index] = PostModel(
            id: post.id,
            userId: post.userId,
            content: post.content,
            mediaType: post.mediaType,
            mediaUrl: post.mediaUrl,
            status: post.status,
            createdAt: post.createdAt,
            user: post.user,
            likeCount: post.isLiked ? post.likeCount - 1 : post.likeCount + 1,
            shareCount: post.shareCount,
            isLiked: !post.isLiked,
          );
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  String _getTimeAgo(String dateTimeStr) {
    try {
      if (dateTimeStr.isEmpty) return '';
      final dateTime = DateTime.parse(dateTimeStr);
      final difference = DateTime.now().difference(dateTime);

      if (difference.inDays > 7) {
        return DateFormat('MMM d, yyyy').format(dateTime);
      } else if (difference.inDays >= 1) {
        return '${difference.inDays}d ago';
      } else if (difference.inHours >= 1) {
        return '${difference.inHours}h ago';
      } else if (difference.inMinutes >= 1) {
        return '${difference.inMinutes}m ago';
      } else {
        return 'Just now';
      }
    } catch (e) {
      return dateTimeStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConfig.bgLight,
      appBar: AppBar(
        title: const Text('Community Posts'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: () {
              context.push('/create_post').then((_) => fetchPosts());
            },
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: fetchPosts,
              color: AppConfig.primaryColor,
              child: posts.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.feed_outlined, size: 64, color: Colors.grey[300]),
                          const SizedBox(height: 16),
                          const Text(
                            'No posts found',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: posts.length,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemBuilder: (context, index) {
                        final post = posts[index];
                        return _buildPostCard(post, index);
                      },
                    ),
            ),
    );
  }

  Widget _buildPostCard(PostModel post, int index) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppConfig.primaryColor.withOpacity(0.1),
                  foregroundImage: post.user.profilePicture != 'default.jpg'
                      ? CachedNetworkImageProvider(AppConfig.getProfileImageUrl(post.user.profilePicture))
                      : null,
                  child: Text(
                    post.user.name[0].toUpperCase(),
                    style: TextStyle(color: AppConfig.primaryColor, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post.user.name,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Text(
                        '${post.user.usn} • ${_getTimeAgo(post.createdAt)}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                ),
                if (Provider.of<AuthProvider>(context, listen: false).user?.id == post.userId.toString())
                  PopupMenuButton<String>(
                    icon: Icon(Icons.more_vert, color: Colors.grey[400]),
                    onSelected: (value) async {
                      if (value == 'delete') {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Delete Post'),
                            content: const Text('Are you sure you want to delete this post?'),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                              TextButton(
                                onPressed: () => Navigator.pop(context, true), 
                                child: const Text('Delete', style: TextStyle(color: Colors.red))
                              ),
                            ],
                          ),
                        );

                        if (confirm == true) {
                          try {
                            final userId = Provider.of<AuthProvider>(context, listen: false).user?.id;
                            final response = await ApiService.post('/posts/delete.php', data: {
                              'user_id': int.parse(userId!),
                              'post_id': post.id,
                            });
                            if (response.data['success']) {
                              setState(() => posts.removeAt(index));
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Post deleted')));
                            }
                          } catch (e) {
                             ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to delete post')));
                          }
                        }
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete_outline, color: Colors.red, size: 20),
                            SizedBox(width: 8),
                            Text('Delete', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Text(
              post.content,
              style: const TextStyle(fontSize: 15, height: 1.4, color: AppConfig.textColor),
            ),
          ),
          if (post.mediaType == 'image' && post.mediaUrl != null) ...[
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: CachedNetworkImage(
                  imageUrl: AppConfig.getPostImageUrl(post.mediaUrl),
                  width: double.infinity,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    height: 200,
                    color: Colors.grey[100],
                    child: const Center(child: CircularProgressIndicator()),
                  ),
                  errorWidget: (context, url, error) => Container(
                    height: 200,
                    color: Colors.grey[100],
                    child: const Icon(Icons.broken_image, size: 40, color: Colors.grey),
                  ),
                ),
              ),
            ),
          ],
          const Divider(height: 24, thickness: 0.5),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 16, 8),
            child: Row(
              children: [
                _buildActionButton(
                  icon: post.isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                  label: '${post.likeCount}',
                  color: post.isLiked ? Colors.red : Colors.grey[600]!,
                  onTap: () => likePost(post.id, index),
                ),
                const SizedBox(width: 16),
                _buildActionButton(
                  icon: Icons.chat_bubble_outline_rounded,
                  label: 'Comment',
                  color: Colors.grey[600]!,
                  onTap: () {},
                ),
                const Spacer(),
                IconButton(
                  icon: Icon(Icons.share_outlined, color: Colors.grey[600], size: 20),
                  onPressed: () {},
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}

