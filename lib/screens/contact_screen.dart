import 'package:flutter/material.dart';

class ContactScreen extends StatefulWidget {
  const ContactScreen({super.key});

  @override
  State<ContactScreen> createState() => _ContactScreenState();
}

class _ContactScreenState extends State<ContactScreen> {
  static const cream = Color(0xFFFAF8F3);
  static const ink = Color(0xFF172033);
  static const blue = Color(0xFF2563EB);
  static const muted = Color(0xFF64748B);
  static const border = Color(0xFFE2E8F0);

  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _message = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _message.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cream,
      appBar: AppBar(
        title: const Text('Contact', style: TextStyle(fontWeight: FontWeight.w900)),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) => ListView(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 32),
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 760),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Need a hand?', style: TextStyle(color: ink, fontSize: 30, fontWeight: FontWeight.w900, letterSpacing: -.8)),
                    const SizedBox(height: 8),
                    const Text('Questions about products, orders or student savings? Send us a message.', style: TextStyle(color: muted, height: 1.5)),
                    const SizedBox(height: 22),
                    _tile(Icons.mail_outline_rounded, 'Email', 'hello@campussupply.example'),
                    _tile(Icons.support_agent_rounded, 'Support', 'Mon–Sat • 10:00 AM–7:00 PM'),
                    _tile(Icons.location_on_outlined, 'Campus desk', 'Ahmedabad, Gujarat'),
                    const SizedBox(height: 10),
                    Container(
                      padding: EdgeInsets.all(constraints.maxWidth < 420 ? 16 : 22),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: border)),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Send an enquiry', style: TextStyle(color: ink, fontSize: 20, fontWeight: FontWeight.w900)),
                            const SizedBox(height: 5),
                            const Text('Fill in the details below. Message delivery is not connected yet.', style: TextStyle(color: muted, height: 1.4)),
                            const SizedBox(height: 18),
                            TextFormField(
                              controller: _name,
                              textInputAction: TextInputAction.next,
                              decoration: _inputDecoration('Name', Icons.person_outline_rounded),
                              validator: (value) => value == null || value.trim().isEmpty ? 'Please enter your name.' : null,
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _email,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              decoration: _inputDecoration('Email', Icons.mail_outline_rounded),
                              validator: (value) {
                                final email = value?.trim() ?? '';
                                return RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email) ? null : 'Enter a valid email address.';
                              },
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _message,
                              minLines: 4,
                              maxLines: 6,
                              decoration: _inputDecoration('Message', Icons.chat_bubble_outline_rounded, alignLabelWithHint: true),
                              validator: (value) => value == null || value.trim().isEmpty ? 'Please enter a message.' : null,
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: FilledButton.icon(
                                onPressed: () {
                                  if (!(_formKey.currentState?.validate() ?? false)) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Message submission is not configured yet. Your message has not been sent.'),
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.send_rounded),
                                label: const Text('Send message'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static InputDecoration _inputDecoration(String label, IconData icon, {bool alignLabelWithHint = false}) => InputDecoration(
        labelText: label,
        prefixIcon: alignLabelWithHint ? null : Icon(icon, size: 20),
        alignLabelWithHint: alignLabelWithHint,
        filled: true,
        fillColor: const Color(0xFFFAFAF8),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: border)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: border)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: blue, width: 1.5)),
      );

  static Widget _tile(IconData icon, String title, String text) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: border)),
        child: Row(children: [
          Container(width: 46, height: 46, decoration: BoxDecoration(color: const Color(0xFFEAF2FF), borderRadius: BorderRadius.circular(15)), child: Icon(icon, color: blue)),
          const SizedBox(width: 13),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(color: ink, fontWeight: FontWeight.w900)),
            const SizedBox(height: 4),
            Text(text, style: const TextStyle(color: muted, fontSize: 13, height: 1.35)),
          ])),
        ]),
      );
}
