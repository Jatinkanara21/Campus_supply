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

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await seedInitialData();
  runApp(const CampusSupplyApp());
}

class CampusSupplyApp extends StatelessWidget {
  const CampusSupplyApp({super.key});
  static const deepForest = Color(0xFF0B2E20), darkEmerald = Color(0xFF124D36), emerald = Color(0xFF1F7A5A), sage = Color(0xFF5F8F7A), mint = Color(0xFFA7D7C5), warmGold = Color(0xFFD8B76A), warmTaupe = Color(0xFF8A7B68), espresso = Color(0xFF2A211B);

  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'Campus Supply',
    theme: ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: deepForest,
      colorScheme: const ColorScheme.dark(primary: emerald, onPrimary: mint, secondary: warmGold, onSecondary: deepForest, surface: darkEmerald, onSurface: mint, error: Color(0xFFE7A18A), onError: deepForest),
      appBarTheme: const AppBarTheme(backgroundColor: deepForest, foregroundColor: mint, elevation: 0),
      cardTheme: const CardThemeData(color: darkEmerald, elevation: 0, margin: EdgeInsets.zero, shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(22)))),
      inputDecorationTheme: const InputDecorationTheme(filled: true, fillColor: darkEmerald, labelStyle: TextStyle(color: sage), hintStyle: TextStyle(color: sage), prefixIconColor: sage, suffixIconColor: sage, border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(18)), borderSide: BorderSide(color: Color(0xFF2D624B))), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(18)), borderSide: BorderSide(color: Color(0xFF2D624B))), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(18)), borderSide: BorderSide(color: warmGold, width: 1.5))),
      elevatedButtonTheme: ElevatedButtonThemeData(style: ElevatedButton.styleFrom(backgroundColor: emerald, foregroundColor: mint, minimumSize: const Size(0, 54), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)))),
      textButtonTheme: TextButtonThemeData(style: TextButton.styleFrom(foregroundColor: warmGold)),
      snackBarTheme: const SnackBarThemeData(backgroundColor: espresso, contentTextStyle: TextStyle(color: mint), actionTextColor: warmGold),
    ),
    initialRoute: '/',
    routes: {'/': (_) => const SplashScreen(), '/home': (_) => const HomeScreen(), '/login': (_) => const LoginScreen(), '/register': (_) => const RegisterScreen(), '/product': (_) => const ProductDetailScreen(), '/wishlist': (_) => const WishlistScreen(), '/profile': (_) => const ProfileScreen(), '/admin': (_) => const AdminScreen()},
  );
}
