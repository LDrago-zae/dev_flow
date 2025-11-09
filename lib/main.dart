import 'package:dev_flow/routes/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:dev_flow/core/constants/app_colors.dart';

void main() async {
  await dotenv.load(fileName: '.env');
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    Supabase.initialize(
      anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
      url: dotenv.env['SUPABASE_URL']!,
    );
  }

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
