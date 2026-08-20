import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';

void main() => runApp(const CampusSupplyApp());

class CampusSupplyApp extends StatelessWidget {
  const CampusSupplyApp({super.key});

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF1F7A5A);
    const background = Color(0xFF0B2E20);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Campus Supply',
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: background,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primary,
          brightness: Brightness.dark,
          surface: const Color(0xFF124D36),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF124D36),
          hintStyle: const TextStyle(color: Color(0xFF8A7B68)),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: Color(0xFF5F8F7A), width: 0.6),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: Color(0xFF5F8F7A), width: 0.6),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: Color(0xFFD8B76A), width: 1.4),
          ),
        ),
      ),
      initialRoute: '/',
      routes: {
        '/': (_) => const SplashScreen(),
        '/home': (_) => const HomeScreen(),
        '/login': (_) => const LoginScreen(),
        '/register': (_) => const RegisterScreen(),
      },
    );
  }
}
