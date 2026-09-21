import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../config/app_config.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';
import '../services/follow_service.dart';
import '../providers/auth_provider.dart';

class UserDiscoveryScreen extends StatefulWidget {
  const UserDiscoveryScreen({super.key});

  @override
  State<UserDiscoveryScreen> createState() => _UserDiscoveryScreenState();
}

class _UserDiscoveryScreenState extends State<UserDiscoveryScreen> {
  List<UserModel> users = [];
  bool isLoading = true;
  final _searchController = TextEditingController();
  List<int> followingIds = [];

  @override
  void initState() {
    super.initState();
    _loadFollowingList();
    fetchUsers();
  }

  Future<void> _loadFollowingList() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = int.parse(authProvider.user?.id ?? '0');
    
    if (userId > 0) {
      followingIds = await FollowService.getFollowingList(userId);
      if (mounted) setState(() {});
    }
  }

  Future<void> fetchUsers([String search = '']) async {
    if (!mounted) return;
    setState(() => isLoading = true);
    try {
      final response = await ApiService.get(
        '/users/discover.php?search=$search',
      );
      if (!mounted) return;
      final data = response.data;
      if (data['success']) {
        setState(() {
          users = (data['data'] as List)
              .map((json) => UserModel.fromJson(json))
              .toList();
          
          // Update isFollowed status based on followingIds
          for (var user in users) {
            user.isFollowed = followingIds.contains(int.parse(user.id));
          }
          
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConfig.bgLight,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),
          SliverToBoxAdapter(
            child: _buildSearchSection(),
          ),
          isLoading && users.isEmpty
              ? const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                )
              : users.isEmpty
                  ? SliverFillRemaining(
                      child: _buildEmptyState(),
                    )
                  : SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final user = users[index];
                            return _buildUserCard(user);
                          },
                          childCount: users.length,
                        ),
                      ),
                    ),
          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 0,
      pinned: true,
      elevation: 0,
      backgroundColor: AppConfig.primaryColor,
      title: const Text('Connect with Alumni', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
      centerTitle: true,
    );
  }

  Widget _buildSearchSection() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      decoration: const BoxDecoration(
        color: AppConfig.primaryColor,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Find your classmates',
            style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            'Search by name, USN, or department',
            style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13),
          ),
          const SizedBox(height: 20),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 5)),
              ],
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (value) => fetchUsers(value),
              decoration: InputDecoration(
                hintText: 'Search alumni...',
                prefixIcon: const Icon(Icons.search_rounded, color: AppConfig.primaryColor),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserCard(UserModel user) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          Hero(
            tag: 'user-${user.id}',
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: user.isFollowed ? AppConfig.secondaryColor : Colors.grey[200]!, width: 2),
              ),
              child: CircleAvatar(
                radius: 30,
                backgroundColor: AppConfig.primaryColor.withOpacity(0.05),
                foregroundImage: user.profilePicture != null
                    ? CachedNetworkImageProvider(AppConfig.getProfileImageUrl(user.profilePicture))
                    : null,
                child: Text(
                  user.name[0].toUpperCase(),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: AppConfig.primaryColor),
                ),
              ),
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.name,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppConfig.textColor),
                ),
                const SizedBox(height: 2),
                Text(
                  user.department ?? 'Alumni',
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                ),
                if (user.batch != null)
                  Text(
                    'Class of ${user.batch}',
                    style: TextStyle(fontSize: 11, color: AppConfig.primaryColor.withOpacity(0.7), fontWeight: FontWeight.w600),
                  ),
              ],
            ),
          ),
          _buildInteractionButton(user),
        ],
      ),
    );
  }

  Widget _buildInteractionButton(UserModel user) {
    if (user.isFollowed) {
      return IconButton(
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppConfig.primaryColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.forum_rounded, color: AppConfig.primaryColor, size: 20),
        ),
        onPressed: () => context.push('/chat', extra: {
          'userId': int.parse(user.id),
          'userName': user.name,
          'userProfile': user.profilePicture,
        }),
      );
    } else {
      return TextButton(
        onPressed: () async {
          final authProvider = Provider.of<AuthProvider>(context, listen: false);
          final currentUserId = int.parse(authProvider.user?.id ?? '0');
          
          if (currentUserId == 0) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Please log in to follow users'),
                backgroundColor: Colors.red,
              ),
            );
            return;
          }

          // Show loading state
          setState(() {
            user.isFollowed = true;
          });

          // Call backend API
          final result = await FollowService.toggleFollow(
            followerId: currentUserId,
            followingId: int.parse(user.id),
          );

          if (result['success']) {
            // Update local state based on backend response
            setState(() {
              user.isFollowed = result['is_following'];
              if (result['is_following']) {
                followingIds.add(int.parse(user.id));
              } else {
                followingIds.remove(int.parse(user.id));
              }
            });

            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(result['is_following'] 
                      ? 'You are now following ${user.name}' 
                      : 'Unfollowed ${user.name}'),
                  behavior: SnackBarBehavior.floating,
                  backgroundColor: AppConfig.primaryColor,
                  duration: const Duration(seconds: 2),
                  action: result['is_following'] 
                      ? SnackBarAction(
                          label: 'Message',
                          textColor: Colors.white,
                          onPressed: () {
                            context.push('/chat', extra: {
                              'userId': int.parse(user.id),
                              'userName': user.name,
                              'userProfile': user.profilePicture,
                            });
                          },
                        )
                      : null,
                ),
              );
            }
          } else {
            // Revert on failure
            setState(() {
              user.isFollowed = false;
            });
            
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(result['message'] ?? 'Failed to follow user'),
                  backgroundColor: Colors.red,
                  duration: const Duration(seconds: 2),
                ),
              );
            }
          }
        },
        style: TextButton.styleFrom(
          backgroundColor: AppConfig.primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
        child: const Text('Follow', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
      );
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search_off_rounded, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'No alumni found',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey[400]),
          ),
          const SizedBox(height: 8),
          Text(
            'Try searching with a different name or USN',
            style: TextStyle(color: Colors.grey[400]),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
