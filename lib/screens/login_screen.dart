import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../widgets/campus_logo.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  static const deepForest = Color(0xFF0B2E20);
  static const darkEmerald = Color(0xFF124D36);
  static const emerald = Color(0xFF1F7A5A);
  static const sage = Color(0xFF5F8F7A);
  static const mint = Color(0xFFA7D7C5);
  static const warmGold = Color(0xFFD8B76A);
  static const warmTaupe = Color(0xFF8A7B68);

  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final formKey = GlobalKey<FormState>();
  bool hidePassword = true;
  bool loading = false;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

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
                  boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 24, offset: Offset(0, 12))],
                ),
                child: Form(
                  key: formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const CampusLogo(size: 58, showWordmark: true),
                      const SizedBox(height: 42),
                      const Text('Welcome back', style: TextStyle(fontSize: 36, fontWeight: FontWeight.w800, letterSpacing: -1.2, color: mint)),
                      const SizedBox(height: 8),
                      const Text('Sign in to continue your campus journey.', style: TextStyle(color: warmTaupe, fontSize: 15)),
                      const SizedBox(height: 32),
                      _label('Email address'),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(hintText: 'you@example.com', prefixIcon: Icon(Icons.mail_outline_rounded)),
                        validator: (v) => v == null || !v.contains('@') ? 'Enter a valid email address' : null,
                      ),
                      const SizedBox(height: 20),
                      _label('Password'),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: passwordController,
                        obscureText: hidePassword,
                        decoration: InputDecoration(
                          hintText: 'Enter your password',
                          prefixIcon: const Icon(Icons.lock_outline_rounded),
                          suffixIcon: IconButton(
                            onPressed: () => setState(() => hidePassword = !hidePassword),
                            icon: Icon(hidePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                          ),
                        ),
                        validator: (v) => v == null || v.length < 6 ? 'Password must be at least 6 characters' : null,
                      ),
                      Align(alignment: Alignment.centerRight, child: TextButton(onPressed: () {}, child: const Text('Forgot password?'))),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: loading ? null : _login,
                          child: loading
                              ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: mint))
                              : const Text('Sign in', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Center(child: TextButton(onPressed: () => Navigator.pushReplacementNamed(context, '/register'), child: const Text('New here? Create an account'))),
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

  Widget _label(String text) => const SizedBox.shrink().buildLabel(text);
}

extension on SizedBox {
  Widget buildLabel(String text) => Text(text, style: const TextStyle(fontWeight: FontWeight.w700, color: LoginScreenText.label));
}

class LoginScreenText {
  static const label = Color(0xFFA7D7C5);
}
