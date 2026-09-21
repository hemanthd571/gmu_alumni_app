import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';
import '../config/app_config.dart';
import '../providers/auth_provider.dart';
import '../widgets/app_drawer.dart';

class SpocDashboardScreen extends StatefulWidget {
  const SpocDashboardScreen({super.key});

  @override
  State<SpocDashboardScreen> createState() => _SpocDashboardScreenState();
}

class _SpocDashboardScreenState extends State<SpocDashboardScreen> {
  List<dynamic> _pendingUsers = [];
  List<dynamic> _acceptedUsers = [];
  bool _isLoadingPending = true;
  bool _isLoadingAccepted = true;

  @override
  void initState() {
    super.initState();
    _fetchPendingUsers();
    _fetchAcceptedUsers();
  }

  Future<void> _fetchPendingUsers() async {
    setState(() => _isLoadingPending = true);
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final department = authProvider.user?.department ?? '';

      final dio = Dio(BaseOptions(
        baseUrl: AppConfig.apiUrl,
        connectTimeout: const Duration(seconds: 10),
      ));
      
      final response = await dio.get('/spoc/get_pending_users.php', queryParameters: {
        if (department.isNotEmpty) 'department': department,
      });
      
      if (response.data != null && response.data['success']) {
        if (mounted) {
          setState(() {
            _pendingUsers = response.data['data'] ?? [];
            _isLoadingPending = false;
          });
        }
      } else {
        if (mounted) {
          setState(() => _isLoadingPending = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(response.data['message'] ?? 'Failed to load pending requests')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingPending = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error connecting to server. Please try again.')),
        );
      }
    }
  }

  Future<void> _fetchAcceptedUsers() async {
    setState(() => _isLoadingAccepted = true);
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final department = authProvider.user?.department ?? '';

      final dio = Dio(BaseOptions(
        baseUrl: AppConfig.apiUrl,
        connectTimeout: const Duration(seconds: 10),
      ));
      
      final response = await dio.get('/spoc/get_accepted_users.php', queryParameters: {
        if (department.isNotEmpty) 'department': department,
      });
      
      if (response.data != null && response.data['success']) {
        if (mounted) {
          setState(() {
            _acceptedUsers = response.data['data'] ?? [];
            _isLoadingAccepted = false;
          });
        }
      } else {
        if (mounted) {
          setState(() => _isLoadingAccepted = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(response.data['message'] ?? 'Failed to load accepted requests')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingAccepted = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error connecting to server. Please try again.')),
        );
      }
    }
  }

  Future<void> _handleAction(int userId, String action) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => const Center(child: CircularProgressIndicator()),
      );

      final dio = Dio(BaseOptions(
        baseUrl: AppConfig.apiUrl,
        connectTimeout: const Duration(seconds: 10),
      ));
      
      final endpoint = action == 'approve' ? '/spoc/approve_user.php' : '/spoc/reject_user.php';
      
      final response = await dio.post(
        endpoint,
        data: {'user_id': userId},
      );
      
      Navigator.of(context).pop(); // dismiss loading dialog
      
      if (response.data != null && response.data['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response.data['message']),
            backgroundColor: action == 'approve' ? Colors.green : Colors.red,
          ),
        );
        _fetchPendingUsers(); // refresh the lists
        _fetchAcceptedUsers();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response.data['message'] ?? 'Failed to $action user'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      Navigator.of(context).pop(); // dismiss loading dialog
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error connecting to server. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppConfig.bgLight,
        appBar: AppBar(
          title: const Text('Registration Requests'),
          centerTitle: true,
          backgroundColor: AppConfig.primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Pending'),
              Tab(text: 'Accepted'),
            ],
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
          ),
        ),
        drawer: const AppDrawer(),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
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
                    'Registration Requests',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Approve or reject pending alumni registrations from your department.',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _buildRequestList(
                    _pendingUsers,
                    _isLoadingPending,
                    _fetchPendingUsers,
                    isPending: true,
                  ),
                  _buildRequestList(
                    _acceptedUsers,
                    _isLoadingAccepted,
                    _fetchAcceptedUsers,
                    isPending: false,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRequestList(List<dynamic> users, bool isLoading, Future<void> Function() onRefresh, {required bool isPending}) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppConfig.primaryColor));
    }

    if (users.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(isPending ? Icons.check_circle_outline : Icons.people_outline, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              isPending ? 'No pending requests' : 'No accepted alumni yet',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      color: AppConfig.primaryColor,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: users.length,
        itemBuilder: (context, index) {
          final user = users[index];
          return _buildUserCard(user, isPending: isPending);
        },
      ),
    );
  }

  Widget _buildUserCard(Map<String, dynamic> user, {required bool isPending}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 25,
                  backgroundColor: AppConfig.primaryColor.withOpacity(0.1),
                  child: Text(
                    user['name']?.toString().substring(0, 1).toUpperCase() ?? 'U',
                    style: const TextStyle(
                      color: AppConfig.primaryColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user['name'] ?? 'Unknown',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      Text(
                        user['email'] ?? 'No email',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                if (!isPending)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'ACTIVE',
                      style: TextStyle(
                        color: Colors.green,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            _buildDetailRow(Icons.badge_rounded, 'USN/ID', user['usn']?.toString()),
            _buildDetailRow(Icons.school_rounded, 'Department', user['department']?.toString()),
            _buildDetailRow(Icons.calendar_today_rounded, 'Batch', user['batch']?.toString()),
            _buildDetailRow(Icons.phone_rounded, 'Phone', user['phone']?.toString()),
            if (isPending) ...[
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        _showConfirmDialog(
                          'Reject User',
                          'Are you sure you want to reject and delete this registration request?',
                          () => _handleAction(int.parse(user['id'].toString()), 'reject'),
                          isDestructive: true,
                        );
                      },
                      icon: const Icon(Icons.close_rounded, color: Colors.red),
                      label: const Text('Reject', style: TextStyle(color: Colors.red)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.red),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        _showConfirmDialog(
                          'Approve User',
                          'Are you sure you want to approve this user? They will gain full access to the app.',
                          () => _handleAction(int.parse(user['id'].toString()), 'approve'),
                        );
                      },
                      icon: const Icon(Icons.check_rounded, color: Colors.white),
                      label: const Text('Approve', style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String? value) {
    if (value == null || value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: TextStyle(
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showConfirmDialog(String title, String content, VoidCallback onConfirm, {bool isDestructive = false}) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title, style: TextStyle(color: isDestructive ? Colors.red : Colors.black)),
        content: Text(content),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              onConfirm();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isDestructive ? Colors.red : Colors.green,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(isDestructive ? 'Reject' : 'Approve'),
          ),
        ],
      ),
    );
  }
}
