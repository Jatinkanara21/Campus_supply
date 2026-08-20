import 'dart:async';
import 'package:flutter/material.dart';
import '../widgets/campus_logo.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  static const deepForest = Color(0xFF0B2E20);
  static const darkEmerald = Color(0xFF124D36);
  static const emerald = Color(0xFF1F7A5A);
  static const mint = Color(0xFFA7D7C5);
  static const warmGold = Color(0xFFD8B76A);
  static const warmTaupe = Color(0xFF8A7B68);

  @override
  void initState() {
    super.initState();
    Timer(const Duration(milliseconds: 1800), () {
      if (mounted) Navigator.pushReplacementNamed(context, '/home');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: deepForest,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [deepForest, darkEmerald, emerald],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CampusLogo(size: 118),
              const SizedBox(height: 28),
              const Text(
                'CampusSupply',
                style: TextStyle(color: mint, fontSize: 34, fontWeight: FontWeight.w800, letterSpacing: -1.2),
              ),
              const SizedBox(height: 8),
              const Text(
                'Everything students need. One smart place.',
                style: TextStyle(color: warmTaupe, fontSize: 14),
              ),
              const SizedBox(height: 34),
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(color: warmGold, strokeWidth: 2),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
