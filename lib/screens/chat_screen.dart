import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../config/app_config.dart';
import '../models/message_model.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';

class ChatScreen extends StatefulWidget {
  final int otherUserId;
  final String? otherUserName;
  final String? otherUserProfile;
  
  const ChatScreen({
    super.key, 
    required this.otherUserId,
    this.otherUserName,
    this.otherUserProfile,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  List<MessageModel> messages = [];
  final _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool isLoading = true;
  bool isSending = false;
  String? otherUserName;
  String? otherUserProfile;

  @override
  void initState() {
    super.initState();
    // Use provided user details if available
    otherUserName = widget.otherUserName;
    otherUserProfile = widget.otherUserProfile;
    
    // Fetch user details if not provided
    if (otherUserName == null) {
      _fetchUserDetails();
    }
    
    fetchMessages();
  }

  Future<void> _fetchUserDetails() async {
    try {
      final response = await ApiService.get('/users/discover.php?search=');
      if (response.data['success']) {
        final users = response.data['data'] as List;
        final otherUser = users.firstWhere(
          (u) => u['id'].toString() == widget.otherUserId.toString(),
          orElse: () => null,
        );
        
        if (otherUser != null && mounted) {
          setState(() {
            otherUserName = otherUser['name'];
            otherUserProfile = otherUser['profile_picture'];
          });
        }
      }
    } catch (e) {
      print('Error fetching user details: $e');
    }
  }

  Future<void> fetchMessages() async {
    if (!mounted) return;
    setState(() => isLoading = true);
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.user?.id ?? '1';
      
      final response = await ApiService.get(
        '/messages/list.php?user_id=$userId&other_user_id=${widget.otherUserId}',
      );
      if (!mounted) return;
      final data = response.data;
      if (data['success']) {
        setState(() {
          messages = (data['data'] as List)
              .map((json) => MessageModel.fromJson(json))
              .toList();
          
          // Only update user details from messages if we don't have them yet
          if (messages.isNotEmpty && otherUserName == null) {
            final firstMessageFromOther = messages.firstWhere(
              (m) => m.senderId == widget.otherUserId, 
              orElse: () => messages[0]
            );
            otherUserName = firstMessageFromOther.senderName;
            otherUserProfile = firstMessageFromOther.senderProfilePicture;
          }
          
          isLoading = false;
        });
        _scrollToBottom();
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

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    if (!mounted) return;

    setState(() => isSending = true);
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.user?.id ?? '1';
      
      final response = await ApiService.post('/messages/send.php', data: {
        'sender_id': int.parse(userId),
        'receiver_id': widget.otherUserId,
        'message': text,
      });

      if (!mounted) return;
      final data = response.data;
      if (data['success']) {
        _messageController.clear();
        await fetchMessages();
      }
      if (mounted) {
        setState(() => isSending = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => isSending = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  String _formatMessageTime(String time) {
    try {
      final dt = DateTime.parse(time);
      return DateFormat.jm().format(dt);
    } catch (e) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final currentUserId = int.parse(authProvider.user?.id ?? '0');

    return Scaffold(
      backgroundColor: AppConfig.bgLight,
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: Colors.white24,
              foregroundImage: otherUserProfile != null
                ? CachedNetworkImageProvider(AppConfig.getProfileImageUrl(otherUserProfile))
                : null,
              child: Text(
                otherUserName != null ? otherUserName![0].toUpperCase() : 'U',
                style: const TextStyle(fontSize: 14, color: Colors.white),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                otherUserName ?? 'Chat',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        actions: const [
          SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : messages.isEmpty
                    ? _buildEmptyChat()
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          final message = messages[index];
                          final isMe = message.senderId == currentUserId;
                          
                          // Show date divider if different from previous message
                          bool showDate = false;
                          if (index == 0) {
                            showDate = true;
                          } else {
                            final prevDate = DateTime.parse(messages[index-1].createdAt).toLocal();
                            final currDate = DateTime.parse(message.createdAt).toLocal();
                            if (prevDate.day != currDate.day) showDate = true;
                          }

                          return Column(
                            children: [
                              if (showDate) _buildDateDivider(message.createdAt),
                              _buildMessageBubble(message, isMe),
                            ],
                          );
                        },
                      ),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildDateDivider(String dateStr) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 24),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          DateFormat('EEEE, MMMM d').format(DateTime.parse(dateStr)),
          style: TextStyle(
            fontSize: 11, 
            color: Colors.grey[600], 
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyChat() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline_rounded, size: 60, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'Wave to ${otherUserName ?? "them"}! 👋',
            style: TextStyle(color: Colors.grey[500], fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(MessageModel message, bool isMe) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!isMe) ...[
                CircleAvatar(
                  radius: 14,
                  backgroundColor: AppConfig.primaryColor.withOpacity(0.1),
                  foregroundImage: otherUserProfile != null
                      ? CachedNetworkImageProvider(AppConfig.getProfileImageUrl(otherUserProfile))
                      : null,
                  child: Text(
                    otherUserName != null ? otherUserName![0].toUpperCase() : 'U',
                    style: const TextStyle(fontSize: 10, color: AppConfig.primaryColor),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: isMe ? const LinearGradient(
                      colors: [AppConfig.primaryColor, Color(0xFF8B2E2E)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ) : null,
                    color: isMe ? null : Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(20),
                      topRight: const Radius.circular(20),
                      bottomLeft: Radius.circular(isMe ? 20 : 4),
                      bottomRight: Radius.circular(isMe ? 4 : 20),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isMe 
                            ? AppConfig.primaryColor.withOpacity(0.2) 
                            : Colors.black.withOpacity(0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: message.message.startsWith('[POST_SHARE:')
                      ? _buildPostShareMessage(message.message, isMe)
                      : Text(
                          message.message,
                          style: TextStyle(
                            color: isMe ? Colors.white : AppConfig.textColor,
                            fontSize: 15,
                            height: 1.4,
                            fontWeight: isMe ? FontWeight.w500 : FontWeight.normal,
                          ),
                        ),
                ),
              ),
              if (isMe) const SizedBox(width: 4),
            ],
          ),
          const SizedBox(height: 4),
          Padding(
            padding: EdgeInsets.only(
              left: isMe ? 0 : 40,
              right: isMe ? 8 : 0,
            ),
            child: Text(
              _formatMessageTime(message.createdAt),
              style: TextStyle(
                fontSize: 10, 
                color: Colors.grey[400],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06), 
            blurRadius: 20, 
            offset: const Offset(0, -5)
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: AppConfig.bgLight,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: TextField(
                controller: _messageController,
                maxLines: 4,
                minLines: 1,
                style: const TextStyle(fontSize: 15),
                decoration: InputDecoration(
                  hintText: 'Type your message...',
                  border: InputBorder.none,
                  hintStyle: TextStyle(fontSize: 15, color: Colors.grey[400]),
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: isSending ? null : sendMessage,
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppConfig.primaryColor, Color(0xFF8B2E2E)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppConfig.primaryColor.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: isSending
                    ? const SizedBox(
                        width: 22, 
                        height: 22, 
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)
                      )
                    : const Icon(Icons.send_rounded, color: Colors.white, size: 22),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostShareMessage(String content, bool isMe) {
    try {
      final postId = content.replaceAll('[POST_SHARE:', '').replaceAll(']', '');
      return InkWell(
        onTap: () => context.push('/post/$postId'),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 220,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isMe ? Colors.white12 : AppConfig.primaryColor.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isMe ? Colors.white24 : AppConfig.primaryColor.withOpacity(0.1),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: isMe ? Colors.white24 : AppConfig.primaryColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.share_rounded, 
                      color: isMe ? Colors.white : AppConfig.primaryColor, 
                      size: 14
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Shared Post',
                    style: TextStyle(
                      color: isMe ? Colors.white : AppConfig.primaryColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Explore amazing memories shared by your alumni.',
                style: TextStyle(
                  color: isMe ? Colors.white.withOpacity(0.9) : Colors.grey[700],
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isMe ? Colors.white24 : AppConfig.primaryColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(
                  child: Text(
                    'View Details',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      return Text(content, style: TextStyle(color: isMe ? Colors.white : AppConfig.textColor));
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}

