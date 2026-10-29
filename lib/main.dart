import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

import 'firebase_options.dart';
import 'screens/about_screen.dart';
import 'screens/admin_screen.dart';
import 'screens/bundles_screen.dart';
import 'screens/cart_screen.dart';
import 'screens/checkout_screen.dart';
import 'screens/contact_screen.dart';
import 'screens/faq_screen.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/orders_screen.dart';
import 'screens/product_detail_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/register_screen.dart';
import 'screens/shop_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/wishlist_screen.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Local testing only. Normal builds (GitHub Actions) never set this flag, so
  // the live app always talks to the real Firebase project.
  // flutter build web --dart-define=USE_FIREBASE_EMULATOR=true
  const useEmulator = bool.fromEnvironment('USE_FIREBASE_EMULATOR');
  if (useEmulator) {
    FirebaseFirestore.instance.useFirestoreEmulator('127.0.0.1', 8085);
    await FirebaseAuth.instance.useAuthEmulator('127.0.0.1', 9099);
    SemanticsBinding.instance.ensureSemantics();
  }

  runApp(const CampusSupplyApp());
}

class CampusSupplyApp extends StatelessWidget {
  const CampusSupplyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Campus Supply',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      initialRoute: '/splash',
      routes: {
        '/splash': (_) => const SplashScreen(),
        '/home': (_) => const HomeScreen(),
        '/shop': (_) => const ShopScreen(),
        '/product': (_) => const ProductDetailScreen(),
        '/product-detail': (_) => const ProductDetailScreen(),
        '/bundles': (_) => const BundlesScreen(),
        '/wishlist': (_) => const WishlistScreen(),
        '/cart': (_) => const CartScreen(),
        '/checkout': (_) => const CheckoutScreen(),
        '/orders': (_) => const OrdersScreen(),
        '/profile': (_) => const ProfileScreen(),
        '/about': (_) => const AboutScreen(),
        '/contact': (_) => const ContactScreen(),
        '/faq': (_) => const FaqScreen(),
        '/login': (_) => const LoginScreen(),
        '/register': (_) => const RegisterScreen(),
        '/admin': (_) => const AdminScreen(),
      },
    );
  }
}
