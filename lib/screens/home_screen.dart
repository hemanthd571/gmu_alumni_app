

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:shimmer/shimmer.dart';
import '../config/app_config.dart';
import '../models/post_model.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../services/follow_service.dart';
import '../widgets/app_drawer.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<PostModel> posts = [];
  bool isLoading = true;
  bool _hasNewAlerts = false;

  @override
  void initState() {
    super.initState();
    fetchPosts();
    _updateLocation();
    _checkNewAlerts();
  }

  Future<void> _checkNewAlerts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastSeen = prefs.getString('last_alert_time') ?? '';
      
      final response = await ApiService.get('/noticeboard/list.php');
      if (response.data['success'] == true) {
        final notices = response.data['data'] as List;
        if (notices.isNotEmpty) {
          final latestNoticeTime = notices[0]['created_at']?.toString() ?? '';
          if (latestNoticeTime.isNotEmpty && latestNoticeTime.compareTo(lastSeen) > 0) {
            if (mounted) setState(() => _hasNewAlerts = true);
          }
        }
      }
      
      final eventResponse = await ApiService.get('/events/list.php');
      if (eventResponse.data['success'] == true) {
        final events = eventResponse.data['data'] as List;
        if (events.isNotEmpty) {
          final latestEventTime = events[0]['created_at']?.toString() ?? '';
          if (latestEventTime.isNotEmpty && latestEventTime.compareTo(lastSeen) > 0) {
            if (mounted) setState(() => _hasNewAlerts = true);
          }
        }
      }
    } catch (e) {
      debugPrint('Error checking alerts: ');
    }
  }

  Future<void> _updateLocation() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.user?.id ?? '1';
      
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      
      if (permission == LocationPermission.deniedForever) return;

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
      );
      
      await ApiService.post('/location/update.php', data: {
        'user_id': int.parse(userId),
        'latitude': position.latitude,
        'longitude': position.longitude,
      });
    } catch (e) {
      debugPrint('Location update error: $e');
    }
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
      // Silently fail
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

  Future<void> _deletePost(int postId) async {
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

    if (confirm != true) return;

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.user?.id;
      
      final response = await ApiService.post('/posts/delete.php', data: {
        'user_id': int.parse(userId!),
        'post_id': postId,
      });

      if (response.data['success']) {
        setState(() {
          posts.removeWhere((p) => p.id == postId);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Post deleted successfully')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to delete post')),
      );
    }
  }

  Future<void> _sharePostInternally(PostModel post, int receiverId) async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.user?.id ?? '1';
      
      final shareMessage = '[POST_SHARE:${post.id}]';
      
      final response = await ApiService.post('/messages/send.php', data: {
        'sender_id': int.parse(userId),
        'receiver_id': receiverId,
        'message': shareMessage,
      });

      if (response.data['success']) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Post shared successfully!')),
          );
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to share: $e')),
        );
      }
    }
  }

  void _showShareSheet(PostModel post) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final userId = int.parse(authProvider.user?.id ?? '0');

        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(30),
              topRight: Radius.circular(30),
            ),
          ),
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  'Share internally',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              FutureBuilder<List<Map<String, dynamic>>>(
                future: FollowService.getFollowingDetails(userId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: Padding(
                      padding: EdgeInsets.all(20),
                      child: CircularProgressIndicator(),
                    ));
                  }
                  
                  final following = snapshot.data ?? [];
                  if (following.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                      child: Text('No followed users found to share with.', 
                        style: TextStyle(color: Colors.grey, fontSize: 13)),
                    );
                  }

                  return SizedBox(
                    height: 100,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: following.length,
                      itemBuilder: (context, index) {
                        final user = following[index];
                        return GestureDetector(
                          onTap: () => _sharePostInternally(post, user['id']),
                          child: Container(
                            width: 80,
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Column(
                              children: [
                                CircleAvatar(
                                  radius: 28,
                                  backgroundColor: AppConfig.primaryColor,
                                  foregroundImage: user['profile_picture'] != null
                                      ? CachedNetworkImageProvider(AppConfig.getProfileImageUrl(user['profile_picture']))
                                      : null,
                                  child: Text(user['name'][0].toUpperCase(), 
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  user['name'].split(' ')[0],
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Divider(height: 32),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  'Share externally',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildExternalShareIcon(
                      'WhatsApp',
                      Icons.chat_rounded,
                      AppConfig.primaryColor,
                      () => Share.share('${post.content}\n\nCheck this out on GMU Alumni App!'),
                    ),
                    _buildExternalShareIcon(
                      'Snapchat',
                      Icons.snapchat_rounded,
                      AppConfig.primaryColor,
                      () => Share.share('${post.content}\n\nCheck this out on GMU Alumni App!'),
                    ),
                    _buildExternalShareIcon(
                      'Instagram',
                      Icons.camera_alt_rounded,
                      AppConfig.primaryColor,
                      () => Share.share('${post.content}\n\nCheck this out on GMU Alumni App!'),
                    ),
                    _buildExternalShareIcon(
                      'More',
                      Icons.more_horiz_rounded,
                      AppConfig.primaryColor,
                      () => Share.share('${post.content}\n\nCheck this out on GMU Alumni App!'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  Widget _buildExternalShareIcon(String name, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 6),
          Text(name, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: AppConfig.bgLight,
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: AppConfig.primaryColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'Gems of GM',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: Colors.white,
              ),
            ),
            Text(
              'Alumni Network',
              style: TextStyle(
                fontSize: 12,
                color: Colors.white70,
              ),
            ),
          ],
        ),
        actions: [
          if (authProvider.user?.is_spoc ?? false)
            IconButton(
              icon: const Icon(Icons.how_to_reg_rounded, color: Colors.white),
              tooltip: 'Registration Requests',
              onPressed: () => context.push('/spoc-dashboard'),
            ),
          IconButton(
            icon: const Icon(Icons.person_rounded, color: Colors.white),
            onPressed: () => context.push('/discover'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      drawer: const AppDrawer(),
      extendBody: true,
      bottomNavigationBar: Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 20),
        height: 55,
        decoration: BoxDecoration(
          color: AppConfig.primaryColor,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: AppConfig.primaryColor.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavIcon(Icons.home_rounded, 'Home', () {}),
              _buildNavIcon(Icons.notifications_none_rounded, 'Alerts', () async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.setString('last_alert_time', DateTime.now().toIso8601String());
                if (mounted) setState(() => _hasNewAlerts = false);
                if (mounted) context.push('/noticeboard');
              }, hasBadge: _hasNewAlerts),
              _buildAddButton(context),
              _buildNavIcon(Icons.forum_outlined, 'Chats', () => context.push('/conversations')),
              _buildNavIcon(Icons.person_outline_rounded, 'Profile', () => context.push('/profile')),
            ],
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: fetchPosts,
        color: AppConfig.primaryColor,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // Welcome Header
            SliverToBoxAdapter(
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
                decoration: const BoxDecoration(
                  color: AppConfig.primaryColor,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(30),
                    bottomRight: Radius.circular(30),
                  ),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: Colors.white,
                      foregroundImage: authProvider.user?.profilePicture != null && 
                                     authProvider.user!.profilePicture!.isNotEmpty
                          ? CachedNetworkImageProvider(AppConfig.getProfileImageUrl(authProvider.user!.profilePicture))
                          : null,
                      child: Text(
                        authProvider.user?.name[0].toUpperCase() ?? 'U',
                        style: const TextStyle(
                          color: AppConfig.primaryColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 22,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Welcome back,',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            authProvider.user?.name ?? 'Alumni',
                            style: const TextStyle(
                              color: AppConfig.secondaryColor,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Post Input Area
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: InkWell(
                  onTap: () => context.push('/create_post').then((_) => fetchPosts()),
                  borderRadius: BorderRadius.circular(15),
                  splashColor: AppConfig.primaryColor.withOpacity(0.1),
                  highlightColor: Colors.transparent,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        Icon(Icons.edit_note_rounded, color: AppConfig.secondaryColor),
                        const SizedBox(width: 12),
                        Text(
                          'What\'s on your mind?',
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 16,
                          ),
                        ),
                        const Spacer(),
                        Icon(Icons.photo_library_rounded, color: Colors.green[400], size: 20),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Section Title
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(20, 16, 16, 8),
                child: Text(
                  'Recent Updates',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
            ),

            // Posts List
            isLoading
                ? SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => _buildShimmerPost(),
                      childCount: 3,
                    ),
                  )
                : posts.isEmpty
                    ? SliverFillRemaining(
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.auto_awesome_mosaic_rounded, size: 80, color: Colors.grey[300]),
                              const SizedBox(height: 16),
                              Text(
                                'No updates yet',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[400],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Be the first to share your journey!',
                                style: TextStyle(color: Colors.grey[500]),
                              ),
                              const SizedBox(height: 24),
                              ElevatedButton.icon(
                                onPressed: () => context.push('/create_post').then((_) => fetchPosts()),
                                icon: const Icon(Icons.add),
                                label: const Text('Create Post'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppConfig.primaryColor,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : AnimationLimiter(
                        child: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final post = posts[index];
                              return AnimationConfiguration.staggeredList(
                                position: index,
                                duration: const Duration(milliseconds: 500),
                                child: SlideAnimation(
                                  verticalOffset: 50.0,
                                  child: FadeInAnimation(
                                    child: _buildPostCard(post, index),
                                  ),
                                ),
                              );
                            },
                            childCount: posts.length,
                          ),
                        ),
                      ),
            const SliverToBoxAdapter(child: SizedBox(height: 80)),
          ],
        ),
      ),
    );
  }

  Widget _buildPostCard(PostModel post, int index) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            spreadRadius: 0,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: AppConfig.primaryColor.withOpacity(0.02),
            blurRadius: 20,
            spreadRadius: 2,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: Colors.grey.withOpacity(0.05),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppConfig.primaryColor.withOpacity(0.08),
                  foregroundImage: post.user.profilePicture != null
                      ? CachedNetworkImageProvider(AppConfig.getProfileImageUrl(post.user.profilePicture))
                      : null,
                  child: Text(
                    post.user.name[0].toUpperCase(),
                    style: TextStyle(
                      color: AppConfig.primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post.user.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          letterSpacing: -0.2,
                        ),
                      ),
                      Row(
                        children: [
                          Text(
                            post.user.usn,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[500],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(Icons.circle, size: 3, color: Colors.grey[400]),
                          const SizedBox(width: 4),
                          Text(
                            _getTimeAgo(post.createdAt),
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[400],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (authProvider.user?.id == post.userId.toString())
                  PopupMenuButton<String>(
                    icon: Icon(Icons.more_horiz_rounded, color: Colors.grey[400]),
                    onSelected: (value) {
                      if (value == 'delete') {
                        _deletePost(post.id);
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

          // Content
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Text(
              post.content,
              style: const TextStyle(
                fontSize: 15,
                height: 1.5,
                color: AppConfig.textColor,
              ),
            ),
          ),

          // Media
          if (post.mediaType == 'image' && post.mediaUrl != null) ...[
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(15),
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
                    child: Icon(Icons.broken_image_rounded, size: 40, color: Colors.grey[300]),
                  ),
                ),
              ),
            ),
          ],

          const SizedBox(height: 12),
          // Actions
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 16, 12),
            child: Row(
              children: [
                _buildActionButton(
                  icon: post.isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                  label: '${post.likeCount}',
                  color: post.isLiked ? Colors.red : Colors.grey[600]!,
                  onTap: () => likePost(post.id, index),
                ),
                const Spacer(),
                _buildActionButton(
                  icon: Icons.ios_share_rounded,
                  label: 'Share',
                  color: Colors.grey[600]!,
                  onTap: () => _showShareSheet(post),
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
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 22, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavIcon(IconData icon, String label, VoidCallback onTap, {bool hasBadge = false}) {
    return InkResponse(
      onTap: onTap,
      radius: 25,
      splashColor: Colors.white.withOpacity(0.1),
      highlightColor: Colors.transparent,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Icon(icon, color: Colors.white),
              if (hasBadge)
                Positioned(
                  right: -2,
                  top: -2,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppConfig.primaryColor, width: 1.5),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 10, color: Colors.white70)),
        ],
      ),
    );
  }

  Widget _buildAddButton(BuildContext context) {
    return InkWell(
      onTap: () => context.push('/create_post').then((_) => fetchPosts()),
      customBorder: const CircleBorder(),
      child: Hero(
        tag: 'create_post_btn',
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 8,
                spreadRadius: 2,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(Icons.add, color: AppConfig.primaryColor, size: 28),
        ),
      ),
    );
  }

  Widget _buildShimmerPost() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Shimmer.fromColors(
        baseColor: Colors.grey[200]!,
        highlightColor: Colors.grey[100]!,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        height: 14,
                        color: Colors.white,
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: 100,
                        height: 12,
                        color: Colors.white,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              height: 14,
              color: Colors.white,
            ),
            const SizedBox(height: 8),
            Container(
              width: MediaQuery.of(context).size.width * 0.7,
              height: 14,
              color: Colors.white,
            ),
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              height: 150,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

