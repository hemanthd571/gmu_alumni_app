import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../config/app_config.dart';
import '../providers/auth_provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToNext();
  }

  Future<void> _navigateToNext() async {
    await Future.delayed(const Duration(seconds: 2));
    
    if (!mounted) return;
    
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.checkLoginStatus(); // Ensure we have the latest status
    
    if (authProvider.isLoggedIn) {
      print('🔄 Splash: User is logged in. is_director: ${authProvider.user?.is_director}');
      if (authProvider.user?.is_director ?? false) {
        print('🚀 Splash: Redirecting to Director Dashboard');
        context.go('/director-dashboard');
      } else {
        print('🏠 Splash: Redirecting to Home');
        context.go('/home');
      }
    } else {
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConfig.primaryColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.school,
              size: 100,
              color: AppConfig.secondaryColor,
            ),
            const SizedBox(height: 20),
            const Text(
              'Gems of GM',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 40),
            const CircularProgressIndicator(
              color: AppConfig.secondaryColor,
            ),
          ],
        ),
      ),
    );
  }
}
