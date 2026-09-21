import 'package:flutter/material.dart';
import '../config/app_config.dart';
import '../models/core_team_model.dart';

class CoreTeamScreen extends StatelessWidget {
  const CoreTeamScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Member list with associated local assets
    final List<CoreTeamModel> teamMembers = [
      CoreTeamModel(
        id: '1', 
        name: 'Ganesh G. Tilve', 
        position: 'Core Team Member',
        image: 'assets/images/ganesh.jpeg',
      ),
      CoreTeamModel(
        id: '2', 
        name: 'Dr. Santoshkumar M', 
        position: 'Core Team Member',
        image: 'assets/images/Dr. Santoshkumar M.jpg',
      ),
      CoreTeamModel(
        id: '3', 
        name: 'Dr. Kiran Kumar H S', 
        position: 'Core Team Member',
        image: 'assets/images/Dr. Kiran Kumar H S.jpg',
      ),
    ];

    return Scaffold(
      backgroundColor: AppConfig.bgLight,
      appBar: AppBar(
        title: const Text('Core Team'),
        elevation: 0,
        centerTitle: true,
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppConfig.primaryColor,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: const Column(
              children: [
                Text(
                  'The Visionaries',
                  style: TextStyle(
                    color: AppConfig.secondaryColor,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Leading the GMU Alumni association to new horizons',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
              itemCount: teamMembers.length,
              itemBuilder: (context, index) {
                final member = teamMembers[index];
                return _buildMemberCard(member);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMemberCard(CoreTeamModel member) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
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
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppConfig.secondaryColor.withOpacity(0.5), width: 2),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(100),
                child: Image.asset(
                  member.image!,
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: 80,
                    height: 80,
                    color: AppConfig.primaryColor.withOpacity(0.1),
                    child: Icon(Icons.person, color: AppConfig.primaryColor, size: 40),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    member.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppConfig.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppConfig.secondaryColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      member.position,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppConfig.primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

