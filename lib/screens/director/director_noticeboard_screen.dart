import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../config/app_config.dart';
import '../../models/notice_model.dart';
import '../../services/api_service.dart';

class DirectorNoticeboardScreen extends StatefulWidget {
  const DirectorNoticeboardScreen({super.key});

  @override
  State<DirectorNoticeboardScreen> createState() => _DirectorNoticeboardScreenState();
}

class _DirectorNoticeboardScreenState extends State<DirectorNoticeboardScreen> {
  List<NoticeModel> notices = [];
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    fetchNotices();
  }

  Future<void> fetchNotices() async {
    try {
      setState(() => isLoading = true);
      final response = await ApiService.get('/noticeboard/list.php');
      
      if (response.data['success'] == true) {
        final data = response.data['data'] as List;
        setState(() {
          notices = data.map((json) => NoticeModel.fromJson(json)).toList();
          isLoading = false;
        });
      } else {
        setState(() {
          error = 'Failed to load notices';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        error = 'Something went wrong. Please check your connection.';
        isLoading = false;
      });
    }
  }

  Future<void> _deleteNotice(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Notice'),
        content: const Text('Are you sure you want to delete this notice?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final response = await ApiService.post('/noticeboard/delete.php', data: {'id': id});
        if (response.data['success'] == true) {
          fetchNotices();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Notice deleted successfully')),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to delete notice')),
          );
        }
      }
    }
  }

  void _showNoticeForm([NoticeModel? notice]) {
    final titleController = TextEditingController(text: notice?.title);
    final contentController = TextEditingController(text: notice?.content);
    
    // Map database values to display values
    final priorityOptions = ['low', 'medium', 'high', 'urgent'];
    final priorityDisplayNames = {
      'low': 'Low',
      'medium': 'Medium', 
      'high': 'High',
      'urgent': 'Urgent',
    };
    
    // Ensure the current category is valid, default to 'medium' if not
    String selectedPriority = notice?.category ?? 'medium';
    if (!priorityOptions.contains(selectedPriority)) {
      selectedPriority = 'medium';
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  notice == null ? 'Create New Notice' : 'Edit Notice',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Title',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 15),
                TextField(
                  controller: contentController,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Content',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 15),
                DropdownButtonFormField<String>(
                  value: selectedPriority,
                  decoration: const InputDecoration(
                    labelText: 'Priority / Category',
                    border: OutlineInputBorder(),
                  ),
                  items: priorityOptions
                      .map((e) => DropdownMenuItem(
                            value: e,
                            child: Text(priorityDisplayNames[e]!),
                          ))
                      .toList(),
                  onChanged: (val) {
                    setModalState(() {
                      selectedPriority = val!;
                    });
                  },
                ),
                const SizedBox(height: 25),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (titleController.text.isEmpty || contentController.text.isEmpty) {
                        return;
                      }
                      
                      final data = {
                        'title': titleController.text,
                        'content': contentController.text,
                        'priority': selectedPriority,
                      };

                      if (notice != null) {
                        data['id'] = notice.id;
                      }

                      final endpoint = notice == null ? '/noticeboard/create.php' : '/noticeboard/update.php';
                      
                      try {
                        final response = await ApiService.post(endpoint, data: data);
                        if (response.data['success'] == true) {
                          Navigator.pop(ctx);
                          fetchNotices();
                        }
                      } catch (e) {
                        // error
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppConfig.primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: Text(notice == null ? 'Create' : 'Update'),
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConfig.bgLight,
      appBar: AppBar(
        title: const Text('Manage Noticeboard'),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showNoticeForm(),
        backgroundColor: AppConfig.primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: RefreshIndicator(
        onRefresh: fetchNotices,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (isLoading && notices.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (error != null) {
      return Center(child: Text(error!));
    }

    if (notices.isEmpty) {
      return const Center(child: Text('No notices found.'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: notices.length,
      itemBuilder: (context, index) {
        final notice = notices[index];
        return _buildNoticeCard(notice);
      },
    );
  }

  Widget _buildNoticeCard(NoticeModel notice) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: () => _showNoticeForm(notice),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: (notice.category?.toLowerCase() == 'urgent' ? Colors.red[50] : AppConfig.secondaryColor.withOpacity(0.1)),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        (notice.category ?? 'General').toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: notice.category?.toLowerCase() == 'urgent' ? Colors.redAccent : AppConfig.primaryColor,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        _buildActionCircle(
                          icon: Icons.edit_rounded,
                          color: Colors.blue,
                          onTap: () => _showNoticeForm(notice),
                        ),
                        const SizedBox(width: 10),
                        _buildActionCircle(
                          icon: Icons.delete_outline_rounded,
                          color: Colors.redAccent,
                          onTap: () => _deleteNotice(notice.id),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                Text(
                  notice.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppConfig.textColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  notice.content,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 15),
                Row(
                  children: [
                    Icon(Icons.calendar_today_rounded, size: 14, color: Colors.grey[400]),
                    const SizedBox(width: 6),
                    Text(
                      DateFormat('MMM dd, yyyy').format(notice.createdAt),
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionCircle({required IconData icon, required Color color, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 18, color: color),
      ),
    );
  }
}
