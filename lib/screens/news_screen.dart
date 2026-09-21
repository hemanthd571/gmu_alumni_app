import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/news_model.dart';
import '../services/api_service.dart';
import '../config/app_config.dart';

class NewsScreen extends StatefulWidget {
  const NewsScreen({super.key});

  @override
  State<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> {
  List<NewsModel> newsList = [];
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    fetchNews();
  }

  Future<void> fetchNews() async {
    try {
      print('🔵 News: Starting to fetch news...');
      print('🔵 API URL: ${AppConfig.apiUrl}/news/list.php');
      
      final response = await ApiService.get('/news/list.php');
      
      print('🔵 Response received: ${response.data}');
      
      if (response.data['success'] == true) {
        final data = response.data['data'] as List;
        print('✅ Success! Found ${data.length} news articles');
        setState(() {
          newsList = data.map((json) => NewsModel.fromJson(json)).toList();
          isLoading = false;
        });
      } else {
        print('❌ API returned success=false');
        setState(() {
          error = 'Failed to load news';
          isLoading = false;
        });
      }
    } catch (e, stackTrace) {
      print('❌ ERROR in fetchNews: $e');
      print('❌ Stack trace: $stackTrace');
      setState(() {
        error = 'Error: ${e.toString()}';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('News Corner')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('News Corner')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 60, color: Colors.red),
              const SizedBox(height: 16),
              Text(error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    isLoading = true;
                    error = null;
                  });
                  fetchNews();
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (newsList.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('News Corner')),
        body: const Center(child: Text('No news available')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('News Corner'),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: newsList.length,
        itemBuilder: (context, index) {
          final news = newsList[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (news.image != null)
                  Image.network(
                    news.image!,
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        news.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(news.content),
                      const SizedBox(height: 8),
                      Text(
                        DateFormat('MMM dd, yyyy').format(news.createdAt),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
