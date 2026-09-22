import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../config/app_config.dart';
import '../services/api_service.dart';

class FeedbackEventListScreen extends StatefulWidget {
  const FeedbackEventListScreen({super.key});

  @override
  State<FeedbackEventListScreen> createState() => _FeedbackEventListScreenState();
}

class _FeedbackEventListScreenState extends State<FeedbackEventListScreen> {
  bool _isLoadingEvents = true;
  List<dynamic> _events = [];
  List<dynamic> _filteredEvents = [];
  String? _eventsError;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchEvents();
    _searchController.addListener(_filterEvents);
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterEvents() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredEvents = _events;
      } else {
        _filteredEvents = _events.where((event) {
          final title = (event['title'] ?? '').toString().toLowerCase();
          return title.contains(query);
        }).toList();
      }
    });
  }

  Future<void> _fetchEvents() async {
    try {
      final response = await ApiService.get('/alumni/get_registered_events.php');

      if (response.statusCode == 200) {
        final data = response.data;
        if (data is Map && data['success'] == true) {
          final listData = data['data'] ?? [];
          setState(() {
            _events = listData;
            _filteredEvents = listData;
            _isLoadingEvents = false;
          });
        } else {
          setState(() {
            _eventsError = (data is Map ? data['message'] : null) ?? 'Failed to load events';
            _isLoadingEvents = false;
          });
        }
      } else {
        setState(() {
          _eventsError = 'Failed to load events. Status: ${response.statusCode}';
          _isLoadingEvents = false;
        });
      }
    } catch (e) {
      setState(() {
        _eventsError = 'Network error: $e';
        _isLoadingEvents = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEFE8DE),
      appBar: AppBar(
        backgroundColor: AppConfig.primaryColor,
        elevation: 0,
        title: const Text(
          'Share Feedback',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoadingEvents) {
      return const Center(child: CircularProgressIndicator(color: AppConfig.primaryColor));
    }

    if (_eventsError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 64),
              const SizedBox(height: 16),
              Text(
                _eventsError!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red, fontSize: 16),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _isLoadingEvents = true;
                    _eventsError = null;
                  });
                  _fetchEvents();
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
          width: double.infinity,
          decoration: const BoxDecoration(
            color: AppConfig.primaryColor,
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(32),
              bottomRight: Radius.circular(32),
            ),
          ),
          child: Column(
            children: [
              const Icon(Icons.campaign_rounded, color: Colors.white, size: 48),
              const SizedBox(height: 16),
              const Text(
                'Select an Event',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontFamily: 'Georgia',
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Choose an event below to share your thoughts',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search events...',
                  hintStyle: const TextStyle(color: Colors.black54),
                  prefixIcon: const Icon(Icons.search, color: AppConfig.primaryColor),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _events.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.qr_code_scanner_rounded, size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 16),
                        const Text(
                          "You haven't registered for any events yet.",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black54,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Scan an event QR code to unlock feedback for that event.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.black38),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _filteredEvents.length + 1, // +1 for General Feedback
                  itemBuilder: (context, index) {
                    if (index == _filteredEvents.length) {
                      return _buildEventCard(
                        title: 'General App Feedback',
                        date: 'Not event specific',
                        icon: Icons.app_shortcut_rounded,
                        onTap: () => context.push('/feedback-options'),
                      );
                    }
                    
                    final event = _filteredEvents[index];
                    final bool isSubmitted = event['has_submitted_feedback'] == 1 || event['has_submitted_feedback'] == '1' || event['has_submitted_feedback'] == true;
                    return _buildEventCard(
                      title: event['title'] ?? 'Unnamed Event',
                      date: event['event_date']?.substring(0, 10) ?? 'Unknown Date',
                      icon: Icons.event,
                      isSubmitted: isSubmitted,
                      onTap: isSubmitted ? null : () async {
                        await context.push('/feedback-options', extra: int.tryParse(event['id'].toString()));
                        _fetchEvents();
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildEventCard({
    required String title,
    required String date,
    required IconData icon,
    required VoidCallback? onTap,
    bool isSubmitted = false,
  }) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppConfig.primaryColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: AppConfig.primaryColor),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      date,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
              if (isSubmitted)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.check_circle, color: Colors.green, size: 14),
                      SizedBox(width: 4),
                      Text(
                        'Submitted',
                        style: TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                )
              else
                const Icon(Icons.arrow_forward_ios_rounded, color: Colors.grey, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}
