import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../config/app_config.dart';
import '../models/message_model.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';

class ConversationsScreen extends StatefulWidget {
  const ConversationsScreen({super.key});

  @override
  State<ConversationsScreen> createState() => _ConversationsScreenState();
}

class _ConversationsScreenState extends State<ConversationsScreen> {
  List<ConversationModel> conversations = [];
  bool isLoading = true;
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    fetchConversations();
  }

  Future<void> fetchConversations() async {
    if (!mounted) return;
    setState(() => isLoading = true);
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.user?.id ?? '1';
      
      final response = await ApiService.get('/messages/conversations.php?user_id=$userId');
      if (!mounted) return;
      final data = response.data;
      if (data['success']) {
        setState(() {
          conversations = (data['data'] as List)
              .map((json) => ConversationModel.fromJson(json))
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
          SnackBar(
            content: Text('Error loading messages: $e'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  String _formatTime(String time) {
    try {
      if (time.isEmpty) return '';
      final DateTime dateTime = DateTime.parse(time);
      final DateTime now = DateTime.now();
      final Duration difference = now.difference(dateTime);

      if (difference.inDays == 0) {
        return DateFormat.jm().format(dateTime); // e.g. 4:30 PM
      } else if (difference.inDays == 1) {
        return 'Yesterday';
      } else if (difference.inDays < 7) {
        return DateFormat.E().format(dateTime); // e.g. Mon
      } else {
        return DateFormat('dd/MM/yy').format(dateTime);
      }
    } catch (e) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Search messages...',
                  border: InputBorder.none,
                ),
                style: const TextStyle(fontSize: 16),
                onChanged: (value) {
                  setState(() => _searchQuery = value);
                },
              )
            : const Text('Messages'),
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search_rounded),
            onPressed: () {
              setState(() {
                if (_isSearching) {
                  _isSearching = false;
                  _searchController.clear();
                  _searchQuery = '';
                } else {
                  _isSearching = true;
                }
              });
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: fetchConversations,
        color: AppConfig.primaryColor,
        child: isLoading && conversations.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : conversations.isEmpty
                ? _buildEmptyState()
                : Builder(
                    builder: (context) {
                      final filtered = conversations.where((c) {
                        final q = _searchQuery.toLowerCase();
                        return c.name.toLowerCase().contains(q) || 
                               c.lastMessage.toLowerCase().contains(q);
                      }).toList();

                      if (filtered.isEmpty && _searchQuery.isNotEmpty) {
                        return Center(
                          child: Text(
                            'No results found for "$_searchQuery"',
                            style: TextStyle(color: Colors.grey[600], fontSize: 16),
                          ),
                        );
                      }

                      return ListView.separated(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: filtered.length,
                        separatorBuilder: (context, index) => const Divider(
                          indent: 85,
                          endIndent: 20,
                          height: 1,
                          thickness: 0.5,
                        ),
                        itemBuilder: (context, index) {
                          final conv = filtered[index];
                          return _buildConversationTile(conv);
                        },
                      );
                    },
                  ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.7,
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.forum_outlined, size: 80, color: Colors.grey[200]),
            const SizedBox(height: 16),
            Text(
              'No messages yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[400],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Start a conversation with fellow alumni!',
              style: TextStyle(color: Colors.grey[400]),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.push('/discover'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConfig.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Find Alumni'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConversationTile(ConversationModel conv) {
    return InkWell(
      onTap: () {
        context.push('/chat', extra: conv.userId).then((_) => fetchConversations());
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: AppConfig.primaryColor.withOpacity(0.1),
                  foregroundImage: conv.profilePicture != null
                    ? CachedNetworkImageProvider(AppConfig.getProfileImageUrl(conv.profilePicture))
                    : null,
                  child: Text(
                    conv.name[0].toUpperCase(),
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppConfig.primaryColor,
                    ),
                  ),
                ),
                // Could add online status indicator here if needed
              ],
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        conv.name,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: conv.unreadCount > 0 ? FontWeight.bold : FontWeight.w600,
                          color: AppConfig.textColor,
                        ),
                      ),
                      Text(
                        _formatTime(conv.lastMessageTime),
                        style: TextStyle(
                          fontSize: 12,
                          color: conv.unreadCount > 0 ? AppConfig.primaryColor : Colors.grey[500],
                          fontWeight: conv.unreadCount > 0 ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          conv.lastMessage,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14,
                            color: conv.unreadCount > 0 ? Colors.black87 : Colors.grey[600],
                            fontWeight: conv.unreadCount > 0 ? FontWeight.w500 : FontWeight.normal,
                          ),
                        ),
                      ),
                      if (conv.unreadCount > 0)
                        Container(
                          margin: const EdgeInsets.only(left: 8),
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: AppConfig.primaryColor,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            '${conv.unreadCount}',
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

