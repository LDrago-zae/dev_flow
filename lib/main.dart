import 'dart:io' show Platform;
import 'package:dev_flow/routes/app_routes.dart';
import 'package:dev_flow/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:dev_flow/core/constants/app_colors.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await dotenv.load(fileName: '.env');

  // Initialize Mapbox
  final mapboxToken = dotenv.env['MAPBOX_MAPS_API_KEY'];
  if (mapboxToken != null && mapboxToken.isNotEmpty) {
    MapboxOptions.setAccessToken(mapboxToken);
  }

  // Initialize Supabase
  await Supabase.initialize(
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
    url: dotenv.env['SUPABASE_URL']!,
  );

  // Initialize AuthService (Google Sign-In)
  final authService = AuthService();

  // Platform-specific client ID configuration:
  // - Android: GOOGLE_ANDROID_CLIENT_ID from .env (Supabase doesn't use google-services.json)
  // - iOS: GOOGLE_IOS_CLIENT_ID from .env
  // - Web: GOOGLE_WEB_CLIENT_ID from .env
  String? clientId;
  if (Platform.isIOS) {
    clientId =
        dotenv.env['GOOGLE_IOS_CLIENT_ID'] ??
        dotenv.env['GOOGLE_WEB_CLIENT_ID'];
  } else if (Platform.isAndroid) {
    // For Supabase, Android needs explicit OAuth client ID (not google-services.json)
    clientId =
        dotenv.env['GOOGLE_ANDROID_CLIENT_ID'] ??
        dotenv.env['GOOGLE_WEB_CLIENT_ID'];
  } else {
    // Web platform
    clientId = dotenv.env['GOOGLE_WEB_CLIENT_ID'];
  }

  await authService.initialize(
    clientId: clientId,
    // Required for Supabase token exchange (use Web client ID)
    serverClientId: dotenv.env['GOOGLE_WEB_CLIENT_ID'],
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Dev Flow',
      routerConfig: AppRoutes.router,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black,
        colorScheme: ColorScheme.dark(
          surface: DarkThemeColors.surface,
          // background: Colors.black,
          primary: DarkThemeColors.primary100,
        ),
      ),
    );
  }
}
