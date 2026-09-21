import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import 'dart:io';
import '../config/app_config.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _batchController;
  late TextEditingController _departmentController;
  bool _isLoading = false;
  bool _isUploadingImage = false;
  final ImagePicker _imagePicker = ImagePicker();
  XFile? _selectedImage;

  @override
  void initState() {
    super.initState();
    final user = Provider.of<AuthProvider>(context, listen: false).user;
    _nameController = TextEditingController(text: user?.name);
    _phoneController = TextEditingController(text: user?.phone);
    _batchController = TextEditingController(text: user?.batch);
    _departmentController = TextEditingController(text: user?.department);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _batchController.dispose();
    _departmentController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 70,
      );
      
      if (image != null) {
        setState(() {
          _selectedImage = image;
        });
        await _uploadImage(image);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking image: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _uploadImage(XFile image) async {
    setState(() => _isUploadingImage = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      FormData formData = FormData.fromMap({
        'user_id': authProvider.user?.id,
        'profile_image': await MultipartFile.fromFile(
          image.path,
          filename: image.name,
        ),
      });

      final dio = Dio(BaseOptions(
        baseUrl: AppConfig.apiUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
      ));

      final response = await dio.post(
        '/auth/upload_profile_image.php',
        data: formData,
      );

      if (response.data['success'] == true) {
        // Update user data with new profile picture
        if (response.data['user'] != null) {
          await authProvider.updateUser(response.data['user']);
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile image updated successfully!')),
          );
        }
      } else {
        throw Exception(response.data['message'] ?? 'Failed to upload image');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error uploading image: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploadingImage = false);
    }
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final response = await ApiService.post('/auth/update_profile.php', data: {
        'id': authProvider.user?.id,
        'name': _nameController.text,
        'phone': _phoneController.text,
        'batch': _batchController.text,
        'department': _departmentController.text,
      });

      if (response.data['success'] == true) {
        print('DEBUG: Profile update API success. Response user data: ${response.data['user']}');
        // Update local state with the response from server
        if (response.data['user'] != null) {
          await authProvider.updateUser(response.data['user']);
          print('DEBUG: updateUser called with API response.');
        } else {
          // Fallback: Update local state manually if server doesn't return user data
          print('DEBUG: API did not return user data. Falling back to manual update.');
          final updatedData = Map<String, dynamic>.from(authProvider.user!.toJson());
          updatedData['name'] = _nameController.text;
          updatedData['phone'] = _phoneController.text;
          updatedData['batch'] = _batchController.text;
          updatedData['department'] = _departmentController.text;
          
          await authProvider.updateUser(updatedData);
          print('DEBUG: updateUser called with manual data: $updatedData');
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile updated successfully!')),
          );
          Navigator.pop(context);
        }
      } else {
        print('DEBUG: Profile update failed. Message: ${response.data['message']}');
        throw Exception(response.data['message'] ?? 'Failed to update profile');
      }
    } catch (e) {
      print('DEBUG: Profile update Exception caught: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConfig.bgLight,
      appBar: AppBar(
        title: const Text('Edit Profile'),
        centerTitle: true,
        elevation: 0,
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Update your professional profile',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  const SizedBox(height: 24),
                  
                  // Profile Image Section
                  Center(
                    child: Column(
                      children: [
                        GestureDetector(
                          onTap: _isUploadingImage ? null : _pickImage,
                          child: Stack(
                            children: [
                              Container(
                                width: 120,
                                height: 120,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: AppConfig.primaryColor, width: 3),
                                ),
                                child: ClipOval(
                                  child: _selectedImage != null
                                    ? Image.file(
                                        File(_selectedImage!.path),
                                        width: 120,
                                        height: 120,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) {
                                          return _buildDefaultAvatar();
                                        },
                                      )
                                    : Consumer<AuthProvider>(
                                        builder: (context, authProvider, child) {
                                          final user = authProvider.user;
                                          return user?.profilePicture != null
                                            ? Image.network(
                                                AppConfig.getProfileImageUrl(user!.profilePicture),
                                                width: 120,
                                                height: 120,
                                                fit: BoxFit.cover,
                                                errorBuilder: (context, error, stackTrace) {
                                                  return _buildDefaultAvatar();
                                                },
                                              )
                                            : _buildDefaultAvatar();
                                        },
                                      ),
                                ),
                              ),
                              if (_isUploadingImage)
                                const Positioned.fill(
                                  child: Center(
                                    child: CircularProgressIndicator(
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  ),
                                )
                              else
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color: AppConfig.primaryColor,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white, width: 2),
                                    ),
                                    child: const Icon(
                                      Icons.camera_alt,
                                      color: Colors.white,
                                      size: 18,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Tap to change profile picture',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  _buildTextField(_nameController, 'Full Name', Icons.person_outline),
                  const SizedBox(height: 16),
                  _buildTextField(_phoneController, 'Phone Number', Icons.phone_outlined, keyboardType: TextInputType.phone),
                  const SizedBox(height: 16),
                  _buildTextField(_batchController, 'Batch (Year)', Icons.calendar_today_outlined),
                  const SizedBox(height: 16),
                  _buildTextField(_departmentController, 'Department', Icons.school_outlined),
                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: _updateProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppConfig.primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        elevation: 0,
                      ),
                      child: const Text('Save Changes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  Widget _buildDefaultAvatar() {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final user = authProvider.user;
        return Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            color: AppConfig.primaryColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              user?.name.substring(0, 1).toUpperCase() ?? 'A',
              style: TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.bold,
                color: AppConfig.primaryColor,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {TextInputType keyboardType = TextInputType.text}) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppConfig.primaryColor),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: AppConfig.primaryColor, width: 1),
        ),
      ),
      validator: (value) => value == null || value.isEmpty ? 'This field is required' : null,
    );
  }
}
