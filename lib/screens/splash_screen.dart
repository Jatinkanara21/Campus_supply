import 'dart:async';
import 'package:flutter/material.dart';
import '../widgets/campus_logo.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
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
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF17142E), Color(0xFF6D4AFF)]),
        ),
        child: Center(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            const CampusLogo(size: 118),
            const SizedBox(height: 28),
            const Text('CampusSupply', style: TextStyle(color: Colors.white, fontSize: 34, fontWeight: FontWeight.w800, letterSpacing: -1.2)),
            const SizedBox(height: 8),
            const Text('Everything students need. One smart place.', style: TextStyle(color: Colors.white70, fontSize: 14)),
            const SizedBox(height: 34),
            const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
          ]),
        ),
      ),
    );
  }
}
