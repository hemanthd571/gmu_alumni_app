import 'package:flutter/material.dart';
import '../config/app_config.dart';

class GalleriesScreen extends StatelessWidget {
  const GalleriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<String> galleryImages = [
      'assets/images/gallery/WhatsApp Image 2025-11-14 at 10.32.35_2823103e.jpg',
      'assets/images/gallery/WhatsApp Image 2025-11-14 at 10.32.35_a42ec249.jpg',
      'assets/images/gallery/WhatsApp Image 2025-11-14 at 10.32.35_ddb62fc5.jpg',
      'assets/images/gallery/WhatsApp Image 2025-11-14 at 10.32.35_fb4b803b.jpg',
      'assets/images/gallery/WhatsApp Image 2025-11-14 at 10.32.38_3518519e.jpg',
      'assets/images/gallery/WhatsApp Image 2025-11-14 at 10.52.29_f5a1a117.jpg',
      'assets/images/gallery/WhatsApp Image 2025-11-14 at 10.52.31_202b6878.jpg',
      'assets/images/gallery/WhatsApp Image 2025-11-14 at 10.52.31_a39ff795.jpg',
      'assets/images/gallery/WhatsApp Image 2025-11-14 at 10.52.33_7eef6681.jpg',
      'assets/images/gallery/WhatsApp Image 2025-11-14 at 10.52.33_ad6aee1d.jpg',
      'assets/images/gallery/WhatsApp Image 2025-11-14 at 10.52.34_511d56db.jpg',
      'assets/images/gallery/WhatsApp Image 2025-11-14 at 10.52.35_05b5c1b9.jpg',
      'assets/images/gallery/WhatsApp Image 2025-11-14 at 10.54.27_6f312f8b.jpg',
      'assets/images/gallery/WhatsApp Image 2025-11-14 at 10.54.28_0cafb2b9.jpg',
      'assets/images/gallery/WhatsApp Image 2025-11-14 at 10.54.32_c176509a.jpg',
      'assets/images/gallery/WhatsApp Image 2025-11-14 at 11.05.42_be5f31f0.jpg',
      'assets/images/gallery/WhatsApp Image 2025-11-14 at 11.05.43_1ea2e5e4.jpg',
      'assets/images/gallery/WhatsApp Image 2025-11-14 at 11.43.01_20cf6ba2.jpg',
      'assets/images/gallery/WhatsApp Image 2025-11-14 at 11.43.08_9ac973db.jpg',
      'assets/images/gallery/WhatsApp Image 2025-11-14 at 11.43.23_73cdb2cc.jpg',
      'assets/images/gallery/WhatsApp Image 2025-11-14 at 11.56.08_880bd81c.jpg',
      'assets/images/gallery/WhatsApp Image 2025-11-14 at 11.56.13_fb51adf8.jpg',
      'assets/images/gallery/WhatsApp Image 2025-11-14 at 11.59.54_e7bc0411.jpg',
      'assets/images/gallery/WhatsApp Image 2025-11-14 at 12.31.42_cd6596db.jpg',
    ];

    return Scaffold(
      backgroundColor: AppConfig.bgLight,
      appBar: AppBar(
        title: const Text('Event Gallery'),
        centerTitle: true,
        elevation: 0,
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
              decoration: const BoxDecoration(
                color: AppConfig.primaryColor,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: const Column(
                children: [
                  Text(
                    'Moments & Memories',
                    style: TextStyle(
                      color: AppConfig.secondaryColor,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'A journey through our institutional events',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  return _buildGalleryItem(galleryImages[index]);
                },
                childCount: galleryImages.length,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGalleryItem(String imagePath) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Image.asset(
              imagePath,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                height: 200,
                color: Colors.grey[200],
                child: const Icon(Icons.broken_image_rounded, size: 50, color: Colors.grey),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

