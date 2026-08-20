import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/product_detail_screen.dart';
import 'screens/wishlist_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/admin_screen.dart';

void main() => runApp(const CampusSupplyApp());

class CampusSupplyApp extends StatelessWidget {
  const CampusSupplyApp({super.key});

  static const deepForest = Color(0xFF0B2E20);
  static const darkEmerald = Color(0xFF124D36);
  static const emerald = Color(0xFF1F7A5A);
  static const sage = Color(0xFF5F8F7A);
  static const mint = Color(0xFFA7D7C5);
  static const warmGold = Color(0xFFD8B76A);
  static const warmTaupe = Color(0xFF8A7B68);
  static const espresso = Color(0xFF2A211B);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Campus Supply',
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: deepForest,
        colorScheme: const ColorScheme.dark(primary: emerald, onPrimary: mint, secondary: warmGold, onSecondary: deepForest, surface: darkEmerald, onSurface: mint, error: Color(0xFFE7A18A), onError: deepForest),
        appBarTheme: const AppBarTheme(backgroundColor: deepForest, foregroundColor: mint, elevation: 0, centerTitle: false),
        cardTheme: const CardThemeData(color: darkEmerald, elevation: 0, margin: EdgeInsets.zero, shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(22)))),
        inputDecorationTheme: const InputDecorationTheme(
          filled: true, fillColor: darkEmerald, labelStyle: TextStyle(color: sage), hintStyle: TextStyle(color: sage), prefixIconColor: sage, suffixIconColor: sage,
          border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(18)), borderSide: BorderSide(color: Color(0xFF2D624B))),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(18)), borderSide: BorderSide(color: Color(0xFF2D624B))),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(18)), borderSide: BorderSide(color: warmGold, width: 1.5)),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(style: ElevatedButton.styleFrom(backgroundColor: emerald, foregroundColor: mint, minimumSize: const Size(0, 54), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)))),
        textButtonTheme: TextButtonThemeData(style: TextButton.styleFrom(foregroundColor: warmGold)),
        snackBarTheme: const SnackBarThemeData(backgroundColor: espresso, contentTextStyle: TextStyle(color: mint), actionTextColor: warmGold),
      ),
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
}
