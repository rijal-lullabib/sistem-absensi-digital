import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
// ignore: unused_import
import 'services/auth_service.dart';
import 'config/supabase_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase
  await SupabaseConfig.initialize();

  // Request permissions at startup
  await Permission.camera.request();
  await Permission.location.request();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sistem Absensi - PT Jasakula Purwa Luhur',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/': (context) => const LoginScreen(),
        '/home': (context) => const HomeScreen(),
      },
    );
  }
}
