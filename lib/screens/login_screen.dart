import 'package:flutter/material.dart';
import '../widgets/campus_logo.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool hidePassword = true;
  @override
  Widget build(BuildContext context) {
    return Scaffold(body: SafeArea(child: Center(child: SingleChildScrollView(padding: const EdgeInsets.all(24), child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 460), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const CampusLogo(size: 58, showWordmark: true), const SizedBox(height: 48),
      const Text('Welcome back', style: TextStyle(fontSize: 36, fontWeight: FontWeight.w800, letterSpacing: -1.2, color: Color(0xFF17172B))),
      const SizedBox(height: 8), const Text('Sign in to continue your campus journey.', style: TextStyle(color: Color(0xFF77778A), fontSize: 15)), const SizedBox(height: 32),
      _label('Email address'), const SizedBox(height: 8), const TextField(keyboardType: TextInputType.emailAddress, decoration: InputDecoration(hintText: 'you@example.com', prefixIcon: Icon(Icons.mail_outline_rounded))),
      const SizedBox(height: 20), _label('Password'), const SizedBox(height: 8),
      TextField(obscureText: hidePassword, decoration: InputDecoration(hintText: 'Enter your password', prefixIcon: const Icon(Icons.lock_outline_rounded), suffixIcon: IconButton(onPressed: () => setState(() => hidePassword = !hidePassword), icon: Icon(hidePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined)))),
      Align(alignment: Alignment.centerRight, child: TextButton(onPressed: () {}, child: const Text('Forgot password?'))), const SizedBox(height: 12),
      SizedBox(width: double.infinity, height: 56, child: ElevatedButton(onPressed: () => Navigator.pushReplacementNamed(context, '/home'), style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6D4AFF), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18))), child: const Text('Sign in', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)))),
      const SizedBox(height: 24), Center(child: TextButton(onPressed: () => Navigator.pushNamed(context, '/register'), child: const Text("New here? Create an account"))),
    ]))))));
  }
  Widget _label(String text) => Text(text, style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF27273A)));
}
