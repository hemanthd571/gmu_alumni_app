import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import '../config/app_config.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final TextEditingController _contentController = TextEditingController();
  bool _isLoading = false;
  File? _selectedMedia;
  bool _isUploadingMedia = false;

  Future<void> _createPost() async {
    if (_contentController.text.trim().isEmpty && _selectedMedia == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please share some thoughts or an image'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (!mounted) return;
    setState(() => _isLoading = true);
    
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.user?.id ?? '1';
      
      String? mediaUrl;
      String mediaType = 'none';
      
      // Upload image if selected
      if (_selectedMedia != null) {
        setState(() => _isUploadingMedia = true);
        
        try {
          final dio = Dio(BaseOptions(baseUrl: AppConfig.baseUrl));
          final formData = FormData.fromMap({
            'image': await MultipartFile.fromFile(
              _selectedMedia!.path,
              filename: _selectedMedia!.path.split('/').last,
            ),
          });
          
          final uploadResponse = await dio.post('/api/upload/image.php', data: formData);
          
          if (uploadResponse.data['success']) {
            mediaUrl = uploadResponse.data['url'];
            mediaType = 'image';
          } else {
            throw Exception(uploadResponse.data['message'] ?? 'Upload failed');
          }
        } catch (e) {
          if (mounted) {
            setState(() {
              _isLoading = false;
              _isUploadingMedia = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Image upload failed: $e'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }
        
        setState(() => _isUploadingMedia = false);
      }
      
      // Create post
      final response = await ApiService.post('/posts/create.php', data: {
        'user_id': int.parse(userId),
        'content': _contentController.text.trim(),
        'media_type': mediaType,
        'media_url': mediaUrl,
      });

      if (!mounted) return;
      final data = response.data;
      
      if (data['success']) {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✨ Post shared successfully!'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
          Navigator.pop(context);
        }
      } else {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(data['message'] ?? 'Failed to create post'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: source,
      maxWidth: 1200,
      maxHeight: 1200,
      imageQuality: 85,
    );

    if (pickedFile != null) {
      setState(() {
        _selectedMedia = File(pickedFile.path);
      });
    }
  }

  void _removeMedia() {
    setState(() {
      _selectedMedia = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Create Post'),
        elevation: 0,
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: ElevatedButton(
              onPressed: _isLoading ? null : _createPost,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConfig.primaryColor,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                padding: const EdgeInsets.symmetric(horizontal: 20),
              ),
              child: _isLoading
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Share', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          if (_isUploadingMedia) const LinearProgressIndicator(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // User Header
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 22,
                        backgroundColor: AppConfig.primaryColor.withOpacity(0.1),
                        foregroundImage: authProvider.user?.profilePicture != null
                            ? CachedNetworkImageProvider('${AppConfig.baseUrl}/uploads/profiles/${authProvider.user!.profilePicture}')
                            : null,
                        child: Text(authProvider.user?.name[0].toUpperCase() ?? 'U', 
                                  style: TextStyle(color: AppConfig.primaryColor, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            authProvider.user?.name ?? 'Alumni',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.public, size: 12, color: Colors.grey[600]),
                                const SizedBox(width: 4),
                                Text('Public', style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  
                  // Text Area
                  TextField(
                    controller: _contentController,
                    decoration: const InputDecoration(
                      hintText: 'What\'s on your mind?',
                      border: InputBorder.none,
                      hintStyle: TextStyle(fontSize: 18, color: Colors.black26),
                    ),
                    maxLines: null,
                    minLines: 5,
                    style: const TextStyle(fontSize: 18, height: 1.5),
                  ),
                  
                  // Media Preview
                  if (_selectedMedia != null) ...[
                    const SizedBox(height: 20),
                    Stack(
                    alignment: Alignment.topRight,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(15),
                          child: Image.file(
                            _selectedMedia!,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: CircleAvatar(
                            backgroundColor: Colors.black54,
                            child: IconButton(
                              icon: const Icon(Icons.close, color: Colors.white, size: 20),
                              onPressed: _removeMedia,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
          
          // Bottom Actions
          Container(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).padding.bottom + 10,
              top: 10,
              left: 20,
              right: 20,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))],
            ),
            child: Row(
              children: [
                const Text('Add to your post', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black54)),
                const Spacer(),
                _buildActionButton(
                  icon: Icons.photo_library_rounded,
                  color: Colors.green,
                  onTap: () => _pickImage(ImageSource.gallery),
                ),
                _buildActionButton(
                  icon: Icons.camera_alt_rounded,
                  color: Colors.blue,
                  onTap: () => _pickImage(ImageSource.camera),
                ),
                _buildActionButton(
                  icon: Icons.location_on_rounded,
                  color: Colors.redAccent,
                  onTap: () {},
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({required IconData icon, required Color color, required VoidCallback onTap}) {
    return IconButton(
      icon: Icon(icon, color: color),
      onPressed: onTap,
      style: IconButton.styleFrom(
        backgroundColor: color.withOpacity(0.1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }
}

