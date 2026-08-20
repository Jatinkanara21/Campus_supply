import 'dart:async';
import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;
  late final Animation<double> _fade;

  static const forest = Color(0xFF0B2E20);
  static const emerald = Color(0xFF1F7A5A);
  static const darkEmerald = Color(0xFF124D36);
  static const mint = Color(0xFFA7D7C5);
  static const gold = Color(0xFFD8B76A);
  static const taupe = Color(0xFF8A7B68);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100));
    _scale = CurvedAnimation(parent: _controller, curve: Curves.easeOutBack);
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _controller.forward();
    Timer(const Duration(milliseconds: 2200), () {
      if (mounted) Navigator.pushReplacementNamed(context, '/home');
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: forest,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [forest, darkEmerald, emerald],
          ),
        ),
        child: Stack(
          children: [
            Positioned(top: -90, right: -70, child: _glow(240, mint.withValues(alpha: .07))),
            Positioned(bottom: -100, left: -80, child: _glow(280, gold.withValues(alpha: .06))),
            Center(
              child: FadeTransition(
                opacity: _fade,
                child: ScaleTransition(
                  scale: _scale,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 126,
                        height: 126,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [emerald, darkEmerald]),
                          borderRadius: BorderRadius.circular(38),
                          border: Border.all(color: gold, width: 1.4),
                          boxShadow: const [BoxShadow(color: Color(0x553E8C6A), blurRadius: 35, spreadRadius: 3)],
                        ),
                        child: const Stack(
                          alignment: Alignment.center,
                          children: [
                            Positioned(top: 15, child: Icon(Icons.school_rounded, color: gold, size: 52)),
                            Positioned(bottom: 17, child: Icon(Icons.shopping_bag_rounded, color: mint, size: 43)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),
                      const Text('CAMPUS', style: TextStyle(color: mint, fontSize: 36, fontWeight: FontWeight.w900, letterSpacing: 2.2)),
                      const Text('SUPPLY', style: TextStyle(color: gold, fontSize: 20, fontWeight: FontWeight.w700, letterSpacing: 6)),
                      const SizedBox(height: 12),
                      const Text('Everything You Need. One Campus Store.', style: TextStyle(color: taupe, fontSize: 12.5)),
                      const SizedBox(height: 34),
                      SizedBox(
                        width: 25,
                        height: 25,
                        child: CircularProgressIndicator(color: mint, backgroundColor: taupe.withValues(alpha: .25), strokeWidth: 2.2),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const Positioned(bottom: 28, left: 0, right: 0, child: Text('SMART SUPPLIES • BETTER CAMPUS LIFE', textAlign: TextAlign.center, style: TextStyle(color: taupe, fontSize: 9, letterSpacing: 2))),
          ],
        ),
      ),
    );
  }

  Widget _glow(double size, Color color) => Container(width: size, height: size, decoration: BoxDecoration(color: color, shape: BoxShape.circle));
}
