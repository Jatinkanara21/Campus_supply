import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../widgets/campus_logo.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  static const forest = Color(0xFF0B2E20);
  static const darkEmerald = Color(0xFF124D36);
  static const emerald = Color(0xFF1F7A5A);
  static const sage = Color(0xFF5F8F7A);
  static const mint = Color(0xFFA7D7C5);
  static const gold = Color(0xFFD8B76A);
  static const taupe = Color(0xFF8A7B68);
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
    await AuthService.register(name: nameController.text.trim(), email: emailController.text.trim(), password: passwordController.text);
    if (!mounted) return;
    setState(() => loading = false);
    Navigator.pushNamedAndRemoveUntil(context, '/home', (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: forest,
      body: Stack(
        children: [
          Positioned(top: -120, left: -90, child: _glow(280, emerald.withValues(alpha: .15))),
          Positioned(bottom: -130, right: -90, child: _glow(300, gold.withValues(alpha: .07))),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 28),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 470),
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(25, 28, 25, 22),
                    decoration: BoxDecoration(
                      color: darkEmerald,
                      borderRadius: BorderRadius.circular(32),
                      border: Border.all(color: sage.withValues(alpha: .55)),
                      boxShadow: const [BoxShadow(color: Color(0x442A211B), blurRadius: 28, offset: Offset(0, 14))],
                    ),
                    child: Form(
                      key: formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Center(child: CampusLogo(size: 64, showWordmark: true)),
                          const SizedBox(height: 32),
                          const Text('Create your account', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: -1, color: mint)),
                          const SizedBox(height: 7),
                          const Text('Join Campus Supply and keep all your essentials in one place.', style: TextStyle(color: taupe, fontSize: 14, height: 1.4)),
                          const SizedBox(height: 26),
                          _label('Full name'),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: nameController,
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(hintText: 'Your name', prefixIcon: Icon(Icons.person_outline_rounded)),
                            validator: (v) => v == null || v.trim().length < 2 ? 'Enter your name' : null,
                          ),
                          const SizedBox(height: 16),
                          _label('Email address'),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: emailController,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(hintText: 'you@example.com', prefixIcon: Icon(Icons.mail_outline_rounded)),
                            validator: (v) => v == null || !v.contains('@') ? 'Enter a valid email address' : null,
                          ),
                          const SizedBox(height: 16),
                          _label('Password'),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: passwordController,
                            obscureText: hidePassword,
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) => loading ? null : _register(),
                            decoration: InputDecoration(
                              hintText: 'Create a password',
                              prefixIcon: const Icon(Icons.lock_outline_rounded),
                              suffixIcon: IconButton(
                                onPressed: () => setState(() => hidePassword = !hidePassword),
                                icon: Icon(hidePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                              ),
                            ),
                            validator: (v) => v == null || v.length < 6 ? 'Password must be at least 6 characters' : null,
                          ),
                          const SizedBox(height: 10),
                          const Row(children: [Icon(Icons.verified_rounded, color: gold, size: 16), SizedBox(width: 7), Expanded(child: Text('Your account is protected with secure local authentication.', style: TextStyle(color: taupe, fontSize: 10.5)))]),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              onPressed: loading ? null : _register,
                              child: loading
                                  ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: mint))
                                  : const Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.person_add_alt_1_rounded, size: 19), SizedBox(width: 9), Text('Create account', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800))]),
                            ),
                          ),
                          const SizedBox(height: 18),
                          Center(child: TextButton(onPressed: () => Navigator.pushReplacementNamed(context, '/login'), child: const Text('Already have an account? Sign in'))),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _label(String text) => Text(text, style: const TextStyle(fontWeight: FontWeight.w800, color: mint, fontSize: 13));
  Widget _glow(double size, Color color) => Container(width: size, height: size, decoration: BoxDecoration(color: color, shape: BoxShape.circle));
}
