import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'config/app_config.dart';
import 'providers/auth_provider.dart';
import 'routes/app_router.dart';
import 'services/api_service.dart';

void main() async {
  print('═══════════════════════════════════════════════════════');
  print('🚀 APP STARTED - Debug mode is ACTIVE');
  print('🌐 API URL: ${AppConfig.apiUrl}');
  print('═══════════════════════════════════════════════════════');
  
  HttpOverrides.global = MyHttpOverrides();
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize API service with SSL configuration
  ApiService.initialize();
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()..checkLoginStatus()),
      ],
      child: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          return MaterialApp.router(
            title: 'GMU Alumni Connect',
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              primaryColor: AppConfig.primaryColor,
              colorScheme: ColorScheme.fromSeed(
                seedColor: AppConfig.primaryColor,
                secondary: AppConfig.secondaryColor,
              ),
              textTheme: GoogleFonts.poppinsTextTheme(),
              useMaterial3: true,
              appBarTheme: const AppBarTheme(
                backgroundColor: AppConfig.primaryColor,
                foregroundColor: Colors.white,
                elevation: 0,
              ),
            ),
            routerConfig: AppRouter.router,
          );
        },
      ),
    );
  }
}
class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (X509Certificate cert, String host, int port) => true;
  }
}
