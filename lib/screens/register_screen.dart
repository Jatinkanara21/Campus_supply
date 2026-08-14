import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../widgets/campus_logo.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final formKey = GlobalKey<FormState>();
  bool hidePassword = true;
  bool loading = false;

  @override
  void dispose() { nameController.dispose(); emailController.dispose(); passwordController.dispose(); super.dispose(); }

  Future<void> _register() async {
    if (!formKey.currentState!.validate()) return;
    setState(() => loading = true);
    await AuthService.register(name: nameController.text, email: emailController.text, password: passwordController.text);
    if (!mounted) return;
    setState(() => loading = false);
    Navigator.pushNamedAndRemoveUntil(context, '/home', (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8FC),
      body: SafeArea(child: Center(child: SingleChildScrollView(padding: const EdgeInsets.all(24), child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: Form(key: formKey, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const CampusLogo(size: 58, showWordmark: true), const SizedBox(height: 42),
          const Text('Join CampusSupply', style: TextStyle(fontSize: 34, fontWeight: FontWeight.w800, letterSpacing: -1.1, color: Color(0xFF17172B))),
          const SizedBox(height: 8), const Text('Create one account for your books, bags and campus essentials.', style: TextStyle(color: Color(0xFF77778A), fontSize: 15)), const SizedBox(height: 30),
          TextFormField(controller: nameController, decoration: const InputDecoration(labelText: 'Full name', hintText: 'Your name', prefixIcon: Icon(Icons.person_outline_rounded)), validator: (v) => v == null || v.trim().length < 2 ? 'Enter your name' : null),
          const SizedBox(height: 16),
          TextFormField(controller: emailController, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'Email address', hintText: 'you@example.com', prefixIcon: Icon(Icons.mail_outline_rounded)), validator: (v) => v == null || !v.contains('@') ? 'Enter a valid email address' : null),
          const SizedBox(height: 16),
          TextFormField(controller: passwordController, obscureText: hidePassword, decoration: InputDecoration(labelText: 'Password', hintText: 'Create a password', prefixIcon: const Icon(Icons.lock_outline_rounded), suffixIcon: IconButton(onPressed: () => setState(() => hidePassword = !hidePassword), icon: Icon(hidePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined))), validator: (v) => v == null || v.length < 6 ? 'Password must be at least 6 characters' : null),
          const SizedBox(height: 24),
          SizedBox(width: double.infinity, height: 56, child: ElevatedButton(onPressed: loading ? null : _register, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6D4AFF), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18))), child: loading ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Create account', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)))),
          const SizedBox(height: 22), Center(child: TextButton(onPressed: () => Navigator.pushReplacementNamed(context, '/login'), child: const Text('Already have an account? Sign in'))),
        ])),
      )))),
    );
  }
}
