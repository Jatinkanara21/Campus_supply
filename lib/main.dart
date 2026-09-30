import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'database/seed_data.dart';
import 'screens/splash_screen.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/product_detail_screen.dart';
import 'screens/wishlist_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/admin_screen.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const CampusSupplyApp());
  if (!kIsWeb) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(seedInitialData());
    });
  }
}

class CampusSupplyApp extends StatelessWidget {
  const CampusSupplyApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Campus Supply',
        theme: AppTheme.light(),
        initialRoute: '/',
        routes: {
          '/': (_) => const SplashScreen(),
          '/home': (_) => const HomeScreen(),
          '/login': (_) => const LoginScreen(),
          '/register': (_) => const RegisterScreen(),
          '/product': (_) => const ProductDetailScreen(),
          '/wishlist': (_) => const WishlistScreen(),
          '/profile': (_) => const ProfileScreen(),
          '/admin': (_) => const AdminScreen(),
        },
      );
}
