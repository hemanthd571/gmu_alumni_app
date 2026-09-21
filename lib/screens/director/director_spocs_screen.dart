import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../config/app_config.dart';
import '../../models/spoc_model.dart';

class DirectorSpocsScreen extends StatefulWidget {
  const DirectorSpocsScreen({super.key});

  @override
  State<DirectorSpocsScreen> createState() => _DirectorSpocsScreenState();
}

class _DirectorSpocsScreenState extends State<DirectorSpocsScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<SpocModel> _allSpocs = [];
  List<SpocModel> _filteredSpocs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchSpocs();
    _searchController.addListener(_filterSpocs);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchSpocs() async {
    print('🔄 DirectorSpocs: Starting to fetch SPOCs...');
    setState(() => _isLoading = true);
    
    try {
      print('🌐 DirectorSpocs: Creating Dio instance...');
      print('🌐 DirectorSpocs: Base URL: ${AppConfig.apiUrl}');
      
      final dio = Dio(BaseOptions(
        baseUrl: AppConfig.apiUrl,
        connectTimeout: const Duration(seconds: 30),
      ));
      
      print('📡 DirectorSpocs: Making GET request to /director/get_spocs.php');
      final response = await dio.get('/director/get_spocs.php');
      
      print('✅ DirectorSpocs: Response received');
      print('✅ DirectorSpocs: Status Code: ${response.statusCode}');
      print('✅ DirectorSpocs: Response Data: ${response.data}');
      
      if (response.statusCode == 200 && response.data['success']) {
        final List<dynamic> data = response.data['data'];
        print('✅ DirectorSpocs: Successfully parsed ${data.length} SPOC records');
        
        setState(() {
          _allSpocs = data.map((json) {
            print('📝 DirectorSpocs: Parsing SPOC: ${json['name']}');
            return SpocModel.fromJson(json);
          }).toList();
          _filteredSpocs = _allSpocs;
          _isLoading = false;
        });
        
        print('✅ DirectorSpocs: SPOCs list updated successfully');
      } else {
        print('❌ DirectorSpocs: Failed to fetch SPOCs');
        print('❌ DirectorSpocs: Status Code: ${response.statusCode}');
        print('❌ DirectorSpocs: Response Data: ${response.data}');
        setState(() => _isLoading = false);
      }
    } on DioException catch (e) {
      print('❌ DirectorSpocs: DioException occurred');
      print('❌ DirectorSpocs: Error Type: ${e.type}');
      print('❌ DirectorSpocs: Error Message: ${e.message}');
      print('❌ DirectorSpocs: Response: ${e.response?.data}');
      print('❌ DirectorSpocs: Status Code: ${e.response?.statusCode}');
      setState(() => _isLoading = false);
    } catch (e, stackTrace) {
      print('❌ DirectorSpocs: Unexpected error occurred');
      print('❌ DirectorSpocs: Error: $e');
      print('❌ DirectorSpocs: Stack Trace: $stackTrace');
      setState(() => _isLoading = false);
    }
  }

  void _filterSpocs() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredSpocs = _allSpocs.where((spoc) {
        return spoc.name.toLowerCase().contains(query) ||
               spoc.email.toLowerCase().contains(query) ||
               spoc.institute.toLowerCase().contains(query) ||
               spoc.branch.toLowerCase().contains(query);
      }).toList();
    });
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not launch phone dialer')),
        );
      }
    }
  }

  Future<void> _sendEmail(String email) async {
    final Uri emailUri = Uri(scheme: 'mailto', path: email);
    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not launch email client')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConfig.bgLight,
      appBar: AppBar(
        title: const Text('SPOCs Directory'),
        backgroundColor: AppConfig.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: AppConfig.primaryColor,
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search by name, email, institute...',
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
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppConfig.secondaryColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.people_alt_rounded, color: Colors.white, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        '${_filteredSpocs.length} SPOCs',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator())
              : _filteredSpocs.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.person_search_rounded, size: 80, color: Colors.grey[300]),
                        const SizedBox(height: 16),
                        Text(
                          'No SPOCs found',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[400],
                          ),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _fetchSpocs,
                    color: AppConfig.primaryColor,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _filteredSpocs.length,
                      itemBuilder: (context, index) {
                        final spoc = _filteredSpocs[index];
                        return _buildSpocCard(spoc);
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpocCard(SpocModel spoc) {
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
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            // Could show detailed view
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
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
                        radius: 30,
                        backgroundColor: AppConfig.primaryColor,
                        backgroundImage: spoc.profilePicture != 'default.jpg'
                          ? CachedNetworkImageProvider(AppConfig.getProfileImageUrl(spoc.profilePicture))
                          : null,
                        child: spoc.profilePicture == 'default.jpg'
                            ? Text(
                                spoc.name.isNotEmpty ? spoc.name[0].toUpperCase() : 'S',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 24,
                                ),
                              )
                            : null,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  spoc.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                    color: AppConfig.textColor,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppConfig.secondaryColor.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  'SPOC',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: AppConfig.primaryColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          if (spoc.institute.isNotEmpty)
                            Text(
                              spoc.institute,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          if (spoc.branch.isNotEmpty)
                            Text(
                              spoc.branch,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[500],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(height: 1),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildContactButton(
                        icon: Icons.email_rounded,
                        label: 'Email',
                        onTap: () => _sendEmail(spoc.email),
                      ),
                    ),
                    const SizedBox(width: 12),
                    if (spoc.phone.isNotEmpty)
                      Expanded(
                        child: _buildContactButton(
                          icon: Icons.phone_rounded,
                          label: 'Call',
                          onTap: () => _makePhoneCall(spoc.phone),
                        ),
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

  Widget _buildContactButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppConfig.primaryColor,
        side: BorderSide(color: AppConfig.primaryColor.withOpacity(0.3)),
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
