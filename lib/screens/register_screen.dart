import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../widgets/campus_logo.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  static const deepForest = Color(0xFF0B2E20);
  static const darkEmerald = Color(0xFF124D36);
  static const sage = Color(0xFF5F8F7A);
  static const mint = Color(0xFFA7D7C5);
  static const warmGold = Color(0xFFD8B76A);
  static const warmTaupe = Color(0xFF8A7B68);
  static const espresso = Color(0xFF2A211B);

  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final formKey = GlobalKey<FormState>();
  bool hidePassword = true;
  bool loading = false;

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

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
      backgroundColor: deepForest,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: darkEmerald,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: const Color(0xFF2D624B)),
                  boxShadow: const [BoxShadow(color: Color(0x552A211B), blurRadius: 24, offset: Offset(0, 12))],
                ),
                child: Form(
                  key: formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const CampusLogo(size: 58, showWordmark: true),
                      const SizedBox(height: 38),
                      const Text('Join CampusSupply', style: TextStyle(fontSize: 34, fontWeight: FontWeight.w800, letterSpacing: -1.1, color: mint)),
                      const SizedBox(height: 8),
                      const Text('Create one account for your books, bags and campus essentials.', style: TextStyle(color: warmTaupe, fontSize: 15)),
                      const SizedBox(height: 30),
                      _fieldLabel('Full name'),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: nameController,
                        decoration: const InputDecoration(hintText: 'Your name', prefixIcon: Icon(Icons.person_outline_rounded, color: sage)),
                        validator: (v) => v == null || v.trim().length < 2 ? 'Enter your name' : null,
                      ),
                      const SizedBox(height: 16),
                      _fieldLabel('Email address'),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(hintText: 'you@example.com', prefixIcon: Icon(Icons.mail_outline_rounded, color: sage)),
                        validator: (v) => v == null || !v.contains('@') ? 'Enter a valid email address' : null,
                      ),
                      const SizedBox(height: 16),
                      _fieldLabel('Password'),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: passwordController,
                        obscureText: hidePassword,
                        decoration: InputDecoration(
                          hintText: 'Create a password',
                          prefixIcon: const Icon(Icons.lock_outline_rounded, color: sage),
                          suffixIcon: IconButton(
                            onPressed: () => setState(() => hidePassword = !hidePassword),
                            icon: Icon(hidePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: sage),
                          ),
                        ),
                        validator: (v) => v == null || v.length < 6 ? 'Password must be at least 6 characters' : null,
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: loading ? null : _register,
                          child: loading
                              ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: mint))
                              : const Text('Create account', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                        ),
                      ),
                      const SizedBox(height: 22),
                      Center(child: TextButton(onPressed: () => Navigator.pushReplacementNamed(context, '/login'), child: const Text('Already have an account? Sign in'))),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _fieldLabel(String text) => Text(text, style: const TextStyle(fontWeight: FontWeight.w700, color: mint));
}
