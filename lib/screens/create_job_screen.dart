import 'package:flutter/material.dart';
import '../config/app_config.dart';
import '../services/api_service.dart';

class CreateJobScreen extends StatefulWidget {
  const CreateJobScreen({super.key});

  @override
  State<CreateJobScreen> createState() => _CreateJobScreenState();
}

class _CreateJobScreenState extends State<CreateJobScreen> {
  final _formKey = GlobalKey<FormState>();
  
  final _titleController = TextEditingController();
  final _companyController = TextEditingController();
  final _locationController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _requirementsController = TextEditingController();
  final _salaryMaxController = TextEditingController();
  final _applicationLinkController = TextEditingController();
  
  String _jobType = 'Full-time';
  String _experienceLevel = 'Entry Level';
  bool _isLoading = false;

  final List<String> _jobTypes = ['Full-time', 'Part-time', 'Internship', 'Contract', 'Freelance'];
  final List<String> _experienceLevels = ['Internship', 'Entry Level', 'Mid Level', 'Senior Level', 'Lead/Executive'];

  Future<void> _submitJob() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final response = await ApiService.post('/jobs/create.php', data: {
        'title': _titleController.text,
        'company': _companyController.text,
        'location': _locationController.text,
        'description': _descriptionController.text,
        'requirements': _requirementsController.text,
        'job_type': _jobType,
        'experience_level': _experienceLevel,
        'salary_max': _salaryMaxController.text,
        'application_link': _applicationLinkController.text,
      });

      if (response.data['success'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Job posted successfully!')),
          );
          Navigator.pop(context, true);
        }
      } else {
        throw Exception(response.data['message'] ?? 'Failed to post job');
      }
    } catch (e) {
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
        title: const Text('Post a Job'),
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
                  _buildSectionTitle('Job Identity'),
                  const SizedBox(height: 16),
                  _buildTextField(_titleController, 'Job Title', Icons.work_outline, 'e.g. Senior Flutter Developer'),
                  const SizedBox(height: 16),
                  _buildTextField(_companyController, 'Company Name', Icons.business_outlined, 'e.g. Microsoft'),
                  const SizedBox(height: 16),
                  _buildTextField(_locationController, 'Location', Icons.location_on_outlined, 'e.g. Remote, Bangalore, etc.'),
                  
                  const SizedBox(height: 32),
                  _buildSectionTitle('Job Categorization'),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildDropdown('Job Type', _jobType, _jobTypes, (val) => setState(() => _jobType = val!)),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildDropdown('Experience', _experienceLevel, _experienceLevels, (val) => setState(() => _experienceLevel = val!)),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),
                  _buildSectionTitle('Job Details'),
                  const SizedBox(height: 16),
                  _buildTextField(_descriptionController, 'Job Description', Icons.description_outlined, 'Describe the role and responsibilities...', maxLines: 5),
                  const SizedBox(height: 16),
                  _buildTextField(_requirementsController, 'Requirements', Icons.list_alt_rounded, 'List keys skills, experience needed...', maxLines: 5),
                  const SizedBox(height: 16),
                  _buildTextField(_salaryMaxController, 'Salary Max (Optional)', Icons.monetization_on_outlined, 'e.g. 15 LPA, \$120k, etc.'),
                  const SizedBox(height: 16),
                  _buildTextField(_applicationLinkController, 'Application Link/Email', Icons.link_rounded, 'Where should candidates apply?'),

                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: _submitJob,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppConfig.primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        elevation: 0,
                      ),
                      child: const Text('Post Opportunity', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: AppConfig.primaryColor,
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, String hint, {int maxLines = 1}) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
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

  Widget _buildDropdown(String label, String value, List<String> items, Function(String?) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              items: items.map((String item) {
                return DropdownMenuItem<String>(
                  value: item,
                  child: Text(item, style: const TextStyle(fontSize: 14)),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}
