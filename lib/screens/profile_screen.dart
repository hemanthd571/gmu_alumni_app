import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../config/app_config.dart';
import '../models/post_model.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  List<PostModel> myPosts = [];
  bool isLoadingPosts = true;

  @override
  void initState() {
    super.initState();
    _fetchMyPosts();
  }

  Future<void> _fetchMyPosts() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.user?.id;
      if (userId == null) return;

      final response = await ApiService.get('/posts/list.php?author_id=$userId&user_id=$userId');
      if (response.data['success']) {
        if (mounted) {
          setState(() {
            myPosts = (response.data['data'] as List)
                .map((json) => PostModel.fromJson(json))
                .toList();
            isLoadingPosts = false;
          });
        }
      }
    } catch (e) {
      print('Error fetching my posts: $e');
      if (mounted) {
        setState(() => isLoadingPosts = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;
    
    print('DEBUG ProfileScreen: Building with user: ${user?.name}, phone: ${user?.phone}, dept: ${user?.department}, batch: ${user?.batch}, pic: ${user?.profilePicture}');

    return Scaffold(
      backgroundColor: AppConfig.bgLight,
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(context, user),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle('Professional Information'),
                  const SizedBox(height: 16),
                  _buildInfoCard(Icons.school_outlined, 'Department', user?.department ?? 'Not set'),
                  _buildInfoCard(Icons.calendar_today_outlined, 'Batch', user?.batch ?? 'Not set'),
                  _buildInfoCard(Icons.phone_outlined, 'Phone', user?.phone ?? 'Not set'),
                  
                  const SizedBox(height: 32),
                  _buildMyPostsSection(),
                  
                  const SizedBox(height: 32),
                  _buildSectionTitle('Account Settings'),
                  const SizedBox(height: 16),
                  _buildActionCard(
                    Icons.lock_outline, 
                    'Change Password', 
                    'Update your account security',
                    () => context.push('/edit-password'),
                  ),
                  _buildActionCard(
                    Icons.logout_rounded, 
                    'Logout', 
                    'Sign out of your account',
                    () => _showLogoutDialog(context, authProvider),
                    isDestructive: true,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context, user) {
    return SliverAppBar(
      expandedHeight: 320,
      pinned: true,
      elevation: 0,
      backgroundColor: AppConfig.primaryColor,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [AppConfig.primaryColor, AppConfig.primaryColor],
                ),
              ),
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 60),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: AppConfig.secondaryColor,
                    shape: BoxShape.circle,
                  ),
                  child: CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.white,
                    backgroundImage: user?.profilePicture != null 
                      ? NetworkImage(AppConfig.getProfileImageUrl(user!.profilePicture)) as ImageProvider
                      : null,
                    child: user?.profilePicture == null 
                      ? Text(
                          user?.name.substring(0, 1).toUpperCase() ?? 'A',
                          style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: AppConfig.primaryColor),
                        )
                      : null,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  user?.name ?? 'Alumni',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user?.email ?? '',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: () => context.push('/edit-profile'),
                  icon: const Icon(Icons.edit, size: 18),
                  label: const Text('Edit Profile'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppConfig.secondaryColor,
                    foregroundColor: AppConfig.primaryColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    elevation: 0,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: AppConfig.primaryColor,
      ),
    );
  }

  Widget _buildInfoCard(IconData icon, String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppConfig.primaryColor.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppConfig.primaryColor, size: 20),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 12, color: Colors.grey[500]),
              ),
              Text(
                value,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppConfig.textColor),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(IconData icon, String title, String subtitle, VoidCallback onTap, {bool isDestructive = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isDestructive ? Colors.red[50] : AppConfig.primaryColor.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: isDestructive ? Colors.red : AppConfig.primaryColor, size: 20),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 15, 
            fontWeight: FontWeight.bold, 
            color: isDestructive ? Colors.red : AppConfig.textColor,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(fontSize: 12, color: Colors.grey[500]),
        ),
        trailing: Icon(Icons.chevron_right, color: Colors.grey[300]),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, AuthProvider authProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              authProvider.logout();
              context.go('/login');
            },
            child: const Text('Logout', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildMyPostsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildSectionTitle('My Posts'),
            if (myPosts.isNotEmpty)
              Text(
                '${myPosts.length} posts',
                style: TextStyle(fontSize: 12, color: Colors.grey[500]),
              ),
          ],
        ),
        const SizedBox(height: 16),
        if (isLoadingPosts)
          const Center(child: Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: CircularProgressIndicator(),
          ))
        else if (myPosts.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Row(
              children: [
                Icon(Icons.post_add_rounded, color: Colors.grey[400]),
                const SizedBox(width: 12),
                Text('You haven\'t posted anything yet.', style: TextStyle(color: Colors.grey[500], fontSize: 13)),
              ],
            ),
          )
        else
          SizedBox(
            height: 150,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              itemCount: myPosts.length,
              itemBuilder: (context, index) {
                final post = myPosts[index];
                return GestureDetector(
                  onTap: () => context.push('/post/${post.id}'),
                  child: Container(
                    width: 200,
                    margin: const EdgeInsets.only(right: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Stack(
                        children: [
                          if (post.mediaType == 'image' && post.mediaUrl != null)
                            Positioned.fill(
                              child: CachedNetworkImage(
                                imageUrl: AppConfig.getPostImageUrl(post.mediaUrl),
                                fit: BoxFit.cover,
                                color: Colors.black.withOpacity(0.1),
                                colorBlendMode: BlendMode.darken,
                              ),
                            ),
                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  post.content,
                                  maxLines: post.mediaUrl != null ? 3 : 5,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 13,
                                    height: 1.3,
                                    color: post.mediaUrl != null ? Colors.white : AppConfig.textColor,
                                    fontWeight: post.mediaUrl != null ? FontWeight.w500 : FontWeight.normal,
                                  ),
                                ),
                                const Spacer(),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.favorite_rounded, 
                                      size: 14, 
                                      color: post.mediaUrl != null ? Colors.white70 : Colors.red[300]
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${post.likeCount}', 
                                      style: TextStyle(
                                        fontSize: 11, 
                                        color: post.mediaUrl != null ? Colors.white70 : Colors.grey[600]
                                      )
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}

