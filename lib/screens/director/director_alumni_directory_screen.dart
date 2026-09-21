import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import '../../config/app_config.dart';
import '../../models/user_model.dart';
import '../../widgets/confirmation_dialog.dart';

class DirectorAlumniDirectoryScreen extends StatefulWidget {
  const DirectorAlumniDirectoryScreen({super.key});

  @override
  State<DirectorAlumniDirectoryScreen> createState() => _DirectorAlumniDirectoryScreenState();
}

class _DirectorAlumniDirectoryScreenState extends State<DirectorAlumniDirectoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<UserModel> _allAlumni = [];
  List<UserModel> _filteredAlumni = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchAlumni();
    _searchController.addListener(_filterAlumni);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchAlumni() async {
    print('🔄 DirectorAlumniDirectory: Starting to fetch alumni...');
    setState(() => _isLoading = true);
    
    try {
      print('🌐 DirectorAlumniDirectory: Creating Dio instance...');
      print('🌐 DirectorAlumniDirectory: Base URL: ${AppConfig.apiUrl}');
      
      final dio = Dio(BaseOptions(
        baseUrl: AppConfig.apiUrl,
        connectTimeout: const Duration(seconds: 30),
      ));
      
      print('📡 DirectorAlumniDirectory: Making GET request to /director/get_all_alumni.php');
      final response = await dio.get('/director/get_all_alumni.php');
      
      print('✅ DirectorAlumniDirectory: Response received');
      print('✅ DirectorAlumniDirectory: Status Code: ${response.statusCode}');
      print('✅ DirectorAlumniDirectory: Response Data: ${response.data}');
      
      if (response.statusCode == 200 && response.data['success']) {
        final List<dynamic> data = response.data['data'];
        print('✅ DirectorAlumniDirectory: Successfully parsed ${data.length} alumni records');
        
        setState(() {
          _allAlumni = data.map((json) {
            print('📝 DirectorAlumniDirectory: Parsing user: ${json['name']}');
            return UserModel.fromJson(json);
          }).toList();
          _filteredAlumni = _allAlumni;
          _isLoading = false;
        });
        
        print('✅ DirectorAlumniDirectory: Alumni list updated successfully');
      } else {
        print('❌ DirectorAlumniDirectory: Failed to fetch alumni');
        print('❌ DirectorAlumniDirectory: Status Code: ${response.statusCode}');
        print('❌ DirectorAlumniDirectory: Response Data: ${response.data}');
        setState(() => _isLoading = false);
      }
    } on DioException catch (e) {
      print('❌ DirectorAlumniDirectory: DioException occurred');
      print('❌ DirectorAlumniDirectory: Error Type: ${e.type}');
      print('❌ DirectorAlumniDirectory: Error Message: ${e.message}');
      print('❌ DirectorAlumniDirectory: Response: ${e.response?.data}');
      print('❌ DirectorAlumniDirectory: Status Code: ${e.response?.statusCode}');
      setState(() => _isLoading = false);
    } catch (e, stackTrace) {
      print('❌ DirectorAlumniDirectory: Unexpected error occurred');
      print('❌ DirectorAlumniDirectory: Error: $e');
      print('❌ DirectorAlumniDirectory: Stack Trace: $stackTrace');
      setState(() => _isLoading = false);
    }
  }

  void _filterAlumni() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredAlumni = _allAlumni.where((user) {
        return user.name.toLowerCase().contains(query) ||
               user.email.toLowerCase().contains(query) ||
               (user.department?.toLowerCase().contains(query) ?? false) ||
               (user.batch?.contains(query) ?? false);
      }).toList();
    });
  }

  Future<void> _deleteUser(String userId) async {
    print('🗑️ DirectorAlumniDirectory: Attempting to delete user with ID: $userId');
    
    final confirm = await showConfirmationDialog(
      context, 
      title: 'Delete User', 
      content: 'Are you sure you want to delete this user? This action cannot be undone.',
      confirmLabel: 'Delete',
      isDestructive: true
    );

    if (confirm != true) {
      print('❌ DirectorAlumniDirectory: User deletion cancelled');
      return;
    }

    try {
      print('🌐 DirectorAlumniDirectory: Creating Dio instance for delete request...');
      final dio = Dio(BaseOptions(baseUrl: AppConfig.apiUrl));
      
      print('📡 DirectorAlumniDirectory: Sending DELETE request to /director/delete_user.php');
      print('📡 DirectorAlumniDirectory: Request data: {user_id: $userId}');
      
      final response = await dio.post('/director/delete_user.php', data: {'user_id': userId});
      
      print('✅ DirectorAlumniDirectory: Delete response received');
      print('✅ DirectorAlumniDirectory: Response: ${response.data}');
       
      setState(() {
        _allAlumni.removeWhere((user) => user.id == userId);
        _filterAlumni();
      });
      
      print('✅ DirectorAlumniDirectory: User deleted successfully from local list');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User deleted successfully')),
        );
      }
    } on DioException catch (e) {
      print('❌ DirectorAlumniDirectory: DioException during delete');
      print('❌ DirectorAlumniDirectory: Error Type: ${e.type}');
      print('❌ DirectorAlumniDirectory: Error Message: ${e.message}');
      print('❌ DirectorAlumniDirectory: Response: ${e.response?.data}');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete user: ${e.message}'), backgroundColor: Colors.red),
        );
      }
    } catch (e, stackTrace) {
      print('❌ DirectorAlumniDirectory: Unexpected error during delete');
      print('❌ DirectorAlumniDirectory: Error: $e');
      print('❌ DirectorAlumniDirectory: Stack Trace: $stackTrace');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete user: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showAddEditUserDialog([UserModel? user]) {
    final isEditing = user != null;
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: user?.name);
    final emailController = TextEditingController(text: user?.email);
    final usnController = TextEditingController(text: user?.usn);
    final batchController = TextEditingController(text: user?.batch);
    final phoneController = TextEditingController(text: user?.phone);
    final passwordController = TextEditingController(); // Only for new users
    
    String? selectedDepartment = user?.department;
    bool obscurePassword = true;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text(isEditing ? 'Edit Member' : 'Add New Member'),
            content: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: nameController,
                        decoration: const InputDecoration(labelText: 'Full Name', prefixIcon: Icon(Icons.person)),
                        validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: emailController,
                        decoration: const InputDecoration(labelText: 'Email Address', prefixIcon: Icon(Icons.email)),
                        validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: usnController,
                        decoration: const InputDecoration(labelText: 'USN', prefixIcon: Icon(Icons.badge)),
                        validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: selectedDepartment,
                        decoration: const InputDecoration(labelText: 'Department', prefixIcon: Icon(Icons.school)),
                        items: ['CSE', 'AIML', 'ISE', 'CY-IY', 'DS-IoT', 'CC-BS', 'ME/ED', 'CE', 'R&A', 'BT', 'ECE', 'EEE', 'FBAS', 'FCIT', 'FCM', 'GMBS', 'GMSAS', 'GMSL', 'Pharmacy', 'GM Poly']
                            .map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
                        onChanged: (v) => setState(() => selectedDepartment = v),
                        validator: (v) => v == null ? 'Required' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: batchController,
                        decoration: const InputDecoration(labelText: 'Passout Year', prefixIcon: Icon(Icons.calendar_today)),
                        validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: phoneController,
                        decoration: const InputDecoration(labelText: 'Phone (Optional)', prefixIcon: Icon(Icons.phone)),
                      ),
                      if (!isEditing) ...[
                         const SizedBox(height: 12),
                         TextFormField(
                          controller: passwordController,
                          obscureText: obscurePassword,
                          decoration: InputDecoration(
                            labelText: 'Password', 
                            prefixIcon: const Icon(Icons.lock),
                            suffixIcon: IconButton(
                              icon: Icon(obscurePassword ? Icons.visibility : Icons.visibility_off),
                              onPressed: () => setState(() => obscurePassword = !obscurePassword),
                            )
                          ),
                          validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                        ),
                      ]
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () {
                  if (formKey.currentState!.validate()) {
                    if (isEditing) {
                      _updateUser(
                        userId: user!.id,
                        name: nameController.text,
                        email: emailController.text,
                        usn: usnController.text,
                        department: selectedDepartment!,
                        batch: batchController.text,
                        phone: phoneController.text,
                      );
                    } else {
                      _addUser(
                        name: nameController.text,
                        email: emailController.text,
                        usn: usnController.text,
                        department: selectedDepartment!,
                        batch: batchController.text,
                        phone: phoneController.text,
                        password: passwordController.text
                      );
                    }
                    Navigator.pop(context);
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: AppConfig.primaryColor, foregroundColor: Colors.white),
                child: Text(isEditing ? 'Save Changes' : 'Add Member'),
              ),
            ],
          );
        }
      ),
    );
  }

  Future<void> _addUser({
    required String name,
    required String email,
    required String usn,
    required String department,
    required String batch,
    required String phone,
    required String password,
  }) async {
    print('➕ DirectorAlumniDirectory: Starting to add new user...');
    print('➕ DirectorAlumniDirectory: User details:');
    print('   - Name: $name');
    print('   - Email: $email');
    print('   - USN: $usn');
    print('   - Department: $department');
    print('   - Batch: $batch');
    print('   - Phone: $phone');
    
    setState(() => _isLoading = true);
    
    try {
      print('🌐 DirectorAlumniDirectory: Creating Dio instance for add user request...');
      final dio = Dio(BaseOptions(baseUrl: AppConfig.apiUrl));
      
      final requestData = {
        'name': name,
        'email': email,
        'usn': usn,
        'department': department,
        'batch': batch,
        'phone': phone,
        'password': password
      };
      
      print('📡 DirectorAlumniDirectory: Sending POST request to /director/add_user.php');
      print('📡 DirectorAlumniDirectory: Request data: $requestData');
      
      final response = await dio.post('/director/add_user.php', data: requestData);
      
      print('✅ DirectorAlumniDirectory: Add user response received');
      print('✅ DirectorAlumniDirectory: Status Code: ${response.statusCode}');
      print('✅ DirectorAlumniDirectory: Response Data: ${response.data}');

      if (response.data['success']) {
        print('✅ DirectorAlumniDirectory: User added successfully');
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('User added successfully'))
          );
        }
        
        print('🔄 DirectorAlumniDirectory: Refreshing alumni list...');
        _fetchAlumni(); // Refresh list
      } else {
        print('❌ DirectorAlumniDirectory: Failed to add user');
        print('❌ DirectorAlumniDirectory: Error message: ${response.data['message']}');
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response.data['message'] ?? 'Failed to add user'), 
              backgroundColor: Colors.red
            )
          );
        }
        setState(() => _isLoading = false);
      }
    } on DioException catch (e) {
      print('❌ DirectorAlumniDirectory: DioException during add user');
      print('❌ DirectorAlumniDirectory: Error Type: ${e.type}');
      print('❌ DirectorAlumniDirectory: Error Message: ${e.message}');
      print('❌ DirectorAlumniDirectory: Response: ${e.response?.data}');
      print('❌ DirectorAlumniDirectory: Status Code: ${e.response?.statusCode}');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error adding user'), backgroundColor: Colors.red)
        );
      }
      setState(() => _isLoading = false);
    } catch (e, stackTrace) {
      print('❌ DirectorAlumniDirectory: Unexpected error during add user');
      print('❌ DirectorAlumniDirectory: Error: $e');
      print('❌ DirectorAlumniDirectory: Stack Trace: $stackTrace');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error adding user'), backgroundColor: Colors.red)
        );
      }
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateUser({
    required String userId,
    required String name,
    required String email,
    required String usn,
    required String department,
    required String batch,
    required String phone,
  }) async {
    print('✏️ DirectorAlumniDirectory: Starting to update user...');
    
    setState(() => _isLoading = true);
    
    try {
      final dio = Dio(BaseOptions(baseUrl: AppConfig.apiUrl));
      
      final requestData = {
        'user_id': userId,
        'name': name,
        'email': email,
        'usn': usn,
        'department': department,
        'batch': batch,
        'phone': phone,
      };
      
      print('📡 DirectorAlumniDirectory: Sending POST request to /director/update_user.php');
      final response = await dio.post('/director/update_user.php', data: requestData);
      
      if (response.data['success']) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('User updated successfully'))
          );
        }
        _fetchAlumni(); // Refresh list
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response.data['message'] ?? 'Failed to update user'), 
              backgroundColor: Colors.red
            )
          );
        }
        setState(() => _isLoading = false);
      }
    } on DioException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error updating user'), backgroundColor: Colors.red)
        );
      }
      setState(() => _isLoading = false);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error updating user'), backgroundColor: Colors.red)
        );
      }
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConfig.bgLight,
      appBar: AppBar(
        title: const Text('Alumni Directory'),
        backgroundColor: AppConfig.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditUserDialog(),
        backgroundColor: AppConfig.secondaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: AppConfig.primaryColor,
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by name, email, USN...',
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),
          Expanded(
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator())
              : _filteredAlumni.isEmpty
                ? const Center(child: Text('No alumni found'))
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _filteredAlumni.length,
                    itemBuilder: (context, index) {
                      final user = _filteredAlumni[index];
                      return _buildUserCard(user);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserCard(UserModel user) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: ExpansionTile(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          childrenPadding: const EdgeInsets.all(0),
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppConfig.primaryColor.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: CircleAvatar(
              radius: 25,
              backgroundColor: AppConfig.primaryColor,
              backgroundImage: user.profilePicture != null 
                ? CachedNetworkImageProvider(AppConfig.getProfileImageUrl(user.profilePicture))
                : null,
              child: user.profilePicture == null
                  ? Text(
                      user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    )
                  : null,
            ),
          ),
          title: Text(
            user.name,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: AppConfig.textColor,
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Row(
              children: [
                if (user.department != null && user.department!.isNotEmpty)
                  _buildTag(user.department!, Colors.blue),
                if (user.batch != null && user.batch!.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  _buildTag(user.batch!, Colors.orange),
                ],
              ],
            ),
          ),
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _buildModernInfoRow(Icons.email_rounded, 'Email', user.email),
                  if (user.phone != null && user.phone!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _buildModernInfoRow(Icons.phone_rounded, 'Phone', user.phone!),
                  ],
                  if (user.usn != null && user.usn!.isNotEmpty) ...[
                     const SizedBox(height: 12),
                    _buildModernInfoRow(Icons.badge_rounded, 'USN', user.usn!),
                  ],
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _showAddEditUserDialog(user),
                          icon: const Icon(Icons.edit_rounded, size: 18),
                          label: const Text('Edit Profile'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppConfig.primaryColor,
                            side: const BorderSide(color: AppConfig.primaryColor),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _deleteUser(user.id),
                          icon: const Icon(Icons.delete_outline_rounded, size: 18),
                          label: const Text('Delete'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red[50],
                            foregroundColor: Colors.red,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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

  Widget _buildTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color.withOpacity(0.8),
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildModernInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Icon(icon, size: 18, color: Colors.grey[600]),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.black54)),
          Expanded(child: Text(value, style: const TextStyle(color: Colors.black87))),
        ],
      ),
    );
  }
}
