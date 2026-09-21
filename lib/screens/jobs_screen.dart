import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/job_model.dart';
import '../services/api_service.dart';
import '../config/app_config.dart';

class JobsScreen extends StatefulWidget {
  const JobsScreen({super.key});

  @override
  State<JobsScreen> createState() => _JobsScreenState();
}

class _JobsScreenState extends State<JobsScreen> {
  List<JobModel> allJobs = [];
  List<JobModel> filteredJobs = [];
  bool isLoading = true;
  String? error;
  String selectedFilter = 'All';

  final List<String> filters = ['All', 'Full-time', 'Internship', 'Part-time', 'Contract'];

  @override
  void initState() {
    super.initState();
    fetchJobs();
  }

  void _applyFilter(String filter) {
    setState(() {
      selectedFilter = filter;
      if (filter == 'All') {
        filteredJobs = allJobs;
      } else {
        filteredJobs = allJobs.where((j) => j.jobType == filter).toList();
      }
    });
  }

  Future<void> fetchJobs() async {
    try {
      final response = await ApiService.get('/jobs/list.php');
      if (response.data['success'] == true) {
        final data = response.data['data'] as List;
        setState(() {
          allJobs = data.map((json) => JobModel.fromJson(json)).toList();
          filteredJobs = allJobs;
          isLoading = false;
        });
      } else {
        setState(() {
          error = 'Failed to load jobs';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        error = 'Error: ${e.toString()}';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConfig.bgLight,
      appBar: AppBar(
        title: const Text('Opportunities'),
        centerTitle: true,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await context.push('/create-job');
          if (result == true) fetchJobs();
        },
        backgroundColor: AppConfig.primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Column(
        children: [
          _buildFilterBar(),
          Expanded(
            child: _buildBody(),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: filters.length,
        itemBuilder: (context, index) {
          final filter = filters[index];
          final isSelected = selectedFilter == filter;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(filter),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) _applyFilter(filter);
              },
              selectedColor: AppConfig.primaryColor,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : AppConfig.textColor,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              backgroundColor: Colors.white,
              elevation: 0,
              pressElevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isSelected ? AppConfig.primaryColor : Colors.grey[200]!,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBody() {
    if (isLoading) return const Center(child: CircularProgressIndicator());
    if (error != null) return _buildErrorState();
    if (filteredJobs.isEmpty) return _buildEmptyState();

    return RefreshIndicator(
      onRefresh: fetchJobs,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: filteredJobs.length,
        itemBuilder: (context, index) {
          return _buildJobCard(filteredJobs[index]);
        },
      ),
    );
  }

  Widget _buildJobCard(JobModel job) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showJobDetails(job),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppConfig.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: const Icon(Icons.business_center, color: AppConfig.primaryColor),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            job.title,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppConfig.textColor),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            job.company,
                            style: TextStyle(color: Colors.grey[600], fontSize: 14, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _buildIconInfo(Icons.location_on_outlined, job.location ?? 'Remote'),
                    const SizedBox(width: 16),
                    _buildIconInfo(Icons.access_time, job.jobType ?? 'Full-time'),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      job.salaryMax != null ? 'Up to ${job.salaryMax}' : 'Competitive Pay',
                      style: const TextStyle(color: AppConfig.primaryColor, fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    Text(
                      '${DateTime.now().difference(job.createdAt).inDays}d ago',
                      style: TextStyle(color: Colors.grey[400], fontSize: 12),
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

  Widget _buildIconInfo(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[400]),
        const SizedBox(width: 4),
        Text(text, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
      ],
    );
  }

  void _showJobDetails(JobModel job) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (_, controller) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30)),
          ),
          child: ListView(
            controller: controller,
            padding: const EdgeInsets.all(24),
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(color: AppConfig.primaryColor.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                    child: const Icon(Icons.business_center, color: AppConfig.primaryColor, size: 30),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(job.title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                        Text(job.company, style: TextStyle(fontSize: 16, color: Colors.grey[600])),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),
              _buildDetailRow('Location', job.location ?? 'Remote', Icons.location_on_outlined),
              _buildDetailRow('Job Type', job.jobType ?? 'Full-time', Icons.access_time),
              _buildDetailRow('Experience', job.experienceLevel ?? 'Entry Level', Icons.bar_chart_rounded),
              _buildDetailRow('Salary', job.salaryMax ?? 'Competitive', Icons.monetization_on_outlined),
              
              const SizedBox(height: 30),
              const Text('Job Description', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Text(job.description, style: TextStyle(fontSize: 15, color: Colors.grey[700], height: 1.6)),
              
              const SizedBox(height: 24),
              const Text('Requirements', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Text(job.requirements ?? 'Not specified', style: TextStyle(fontSize: 15, color: Colors.grey[700], height: 1.6)),
              
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: () {
                    // Normally open application link
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppConfig.primaryColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                  child: const Text('Apply Now', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppConfig.primaryColor),
          const SizedBox(width: 12),
          Text('$label:', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          const SizedBox(width: 8),
          Text(value, style: TextStyle(fontSize: 14, color: Colors.grey[700])),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 60, color: Colors.red),
          const SizedBox(height: 16),
          Text(error!),
          TextButton(onPressed: fetchJobs, child: const Text('Try Again')),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.work_off_outlined, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text('No jobs found for $selectedFilter', style: TextStyle(color: Colors.grey[600], fontSize: 16)),
        ],
      ),
    );
  }
}

