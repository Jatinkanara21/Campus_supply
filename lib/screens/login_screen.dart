import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../widgets/campus_logo.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final formKey = GlobalKey<FormState>();
  bool hidePassword = true;
  bool loading = false;

  @override
  void dispose() { emailController.dispose(); passwordController.dispose(); super.dispose(); }

  Future<void> _login() async {
    if (!formKey.currentState!.validate()) return;
    setState(() => loading = true);
    final success = await AuthService.login(email: emailController.text, password: passwordController.text);
    if (!mounted) return;
    setState(() => loading = false);
    if (success) {
      Navigator.pushNamedAndRemoveUntil(context, '/home', (_) => false);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Incorrect email or password. Please register first.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8FC),
      body: SafeArea(child: Center(child: SingleChildScrollView(padding: const EdgeInsets.all(24), child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: Form(key: formKey, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const CampusLogo(size: 58, showWordmark: true), const SizedBox(height: 48),
          const Text('Welcome back', style: TextStyle(fontSize: 36, fontWeight: FontWeight.w800, letterSpacing: -1.2, color: Color(0xFF17172B))),
          const SizedBox(height: 8), const Text('Sign in to continue your campus journey.', style: TextStyle(color: Color(0xFF77778A), fontSize: 15)), const SizedBox(height: 32),
          _label('Email address'), const SizedBox(height: 8),
          TextFormField(controller: emailController, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(hintText: 'you@example.com', prefixIcon: Icon(Icons.mail_outline_rounded)), validator: (v) => v == null || !v.contains('@') ? 'Enter a valid email address' : null),
          const SizedBox(height: 20), _label('Password'), const SizedBox(height: 8),
          TextFormField(controller: passwordController, obscureText: hidePassword, decoration: InputDecoration(hintText: 'Enter your password', prefixIcon: const Icon(Icons.lock_outline_rounded), suffixIcon: IconButton(onPressed: () => setState(() => hidePassword = !hidePassword), icon: Icon(hidePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined))), validator: (v) => v == null || v.length < 6 ? 'Password must be at least 6 characters' : null),
          Align(alignment: Alignment.centerRight, child: TextButton(onPressed: () {}, child: const Text('Forgot password?'))), const SizedBox(height: 12),
          SizedBox(width: double.infinity, height: 56, child: ElevatedButton(onPressed: loading ? null : _login, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6D4AFF), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18))), child: loading ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Sign in', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)))),
          const SizedBox(height: 24), Center(child: TextButton(onPressed: () => Navigator.pushReplacementNamed(context, '/register'), child: const Text('New here? Create an account'))),
        ])),
      )))),
    );
  }
  Widget _label(String text) => Text(text, style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF27273A)));
}
