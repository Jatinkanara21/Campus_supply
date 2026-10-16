import 'package:flutter/material.dart';

import '../widgets/customer_bottom_nav.dart';

class ContactScreen extends StatefulWidget {
  const ContactScreen({super.key});

  @override
  State<ContactScreen> createState() => _ContactScreenState();
}

class _ContactScreenState extends State<ContactScreen> {
  static const cream = Color(0xFFFAF8F3);
  static const ink = Color(0xFF172554);
  static const blue = Color(0xFF2563EB);
  static const muted = Color(0xFF64748B);
  static const border = Color(0xFFE2E8F0);
  static const paleBlue = Color(0xFFEAF2FF);

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
        title: const Text(
          'Contact',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final horizontal = constraints.maxWidth >= 1000
              ? 32.0
              : constraints.maxWidth >= 600
                  ? 24.0
                  : 16.0;

          return ListView(
            padding: EdgeInsets.fromLTRB(horizontal, 20, horizontal, 32),
            children: [
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1080),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _heroHeader(),
                      const SizedBox(height: 28),
                      const Text(
                        'Contact information',
                        style: TextStyle(
                          color: ink,
                          fontSize: 21,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -.4,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Here are the contact details currently listed for Campus Supply.',
                        style: TextStyle(
                          color: muted,
                          fontSize: 13,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _contactCards(),
                      const SizedBox(height: 28),
                      _enquiryForm(context),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: const CustomerBottomNav(),
    );
  }

  Widget _heroHeader() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 560;

        final copy = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
              decoration: BoxDecoration(
                color: const Color(0xFFD9E7FF),
                borderRadius: BorderRadius.circular(30),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.support_agent_rounded, color: blue, size: 15),
                  SizedBox(width: 7),
                  Text(
                    'CAMPUS SUPPLY SUPPORT',
                    style: TextStyle(
                      color: blue,
                      fontSize: 9,
                      letterSpacing: .8,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Need a hand?',
              style: TextStyle(
                color: ink,
                fontSize: constraints.maxWidth < 360 ? 30 : 34,
                height: 1.08,
                letterSpacing: -.9,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Questions about products, orders or student savings? Take a look at our contact details or fill in the enquiry form below.',
              style: TextStyle(
                color: muted,
                fontSize: 14,
                height: 1.6,
              ),
            ),
          ],
        );

        final supportIcon = Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: const Color(0xFFD9E7FF),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: const Color(0xFFC7D9FC)),
          ),
          child: const Icon(
            Icons.headset_mic_rounded,
            color: blue,
            size: 48,
          ),
        );

        return Container(
          padding: EdgeInsets.all(wide ? 28 : 22),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFF0F5FF), Color(0xFFE7F0FF)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: const Color(0xFFD7E4FA)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(child: copy),
              if (wide) ...[
                const SizedBox(width: 24),
                supportIcon,
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _contactCards() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 880
            ? 3
            : constraints.maxWidth >= 560
                ? 2
                : 1;
        const spacing = 14.0;
        final cardWidth = (constraints.maxWidth - spacing * (columns - 1)) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            SizedBox(
              width: cardWidth,
              child: _infoCard(
                Icons.mail_outline_rounded,
                'Email',
                'hello@campussupply.example',
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: _infoCard(
                Icons.support_agent_rounded,
                'Support hours',
                'Mon–Sat • 10:00 AM–7:00 PM',
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: _infoCard(
                Icons.location_on_outlined,
                'Campus desk',
                'Ahmedabad, Gujarat',
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _infoCard(IconData icon, String title, String value) {
    return Container(
      padding: const EdgeInsets.all(18),
      constraints: const BoxConstraints(minHeight: 132),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x07172554),
            blurRadius: 14,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: paleBlue,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(icon, color: blue, size: 21),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: ink,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            value,
            softWrap: true,
            style: const TextStyle(
              color: muted,
              fontSize: 13,
              height: 1.45,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _enquiryForm(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(MediaQuery.sizeOf(context).width < 420 ? 18 : 26),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08172554),
            blurRadius: 20,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: paleBlue,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.edit_note_rounded, color: blue, size: 25),
                ),
                const SizedBox(width: 13),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Send an enquiry',
                        style: TextStyle(
                          color: ink,
                          fontSize: 21,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -.35,
                        ),
                      ),
                      SizedBox(height: 5),
                      Text(
                        'Share your question or feedback using the form below.',
                        style: TextStyle(color: muted, fontSize: 13, height: 1.5),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF7E6),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFF3E1B5)),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline_rounded, color: Color(0xFF946200), size: 19),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Online message delivery is not configured yet. This form can check your details, but it cannot send your enquiry.',
                      style: TextStyle(
                        color: Color(0xFF765A19),
                        fontSize: 12,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth >= 620;
                final nameField = _nameField();
                final emailField = _emailField();

                if (wide) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: nameField),
                      const SizedBox(width: 16),
                      Expanded(child: emailField),
                    ],
                  );
                }

                return Column(
                  children: [
                    nameField,
                    const SizedBox(height: 16),
                    emailField,
                  ],
                );
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _message,
              keyboardType: TextInputType.multiline,
              textCapitalization: TextCapitalization.sentences,
              minLines: 5,
              maxLines: 7,
              decoration: _inputDecoration(
                label: 'Message',
                hint: 'How can we help you?',
                icon: Icons.chat_bubble_outline_rounded,
                alignLabelWithHint: true,
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter your message.';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: FilledButton.icon(
                onPressed: _handleSubmit,
                icon: const Icon(Icons.send_rounded, size: 19),
                label: const Text(
                  'Send message',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: blue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _nameField() {
    return TextFormField(
      controller: _name,
      keyboardType: TextInputType.name,
      textCapitalization: TextCapitalization.words,
      textInputAction: TextInputAction.next,
      autofillHints: const [AutofillHints.name],
      decoration: _inputDecoration(
        label: 'Name',
        hint: 'Enter your name',
        icon: Icons.person_outline_rounded,
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Please enter your name.';
        }
        return null;
      },
    );
  }

  Widget _emailField() {
    return TextFormField(
      controller: _email,
      keyboardType: TextInputType.emailAddress,
      textInputAction: TextInputAction.next,
      autofillHints: const [AutofillHints.email],
      decoration: _inputDecoration(
        label: 'Email',
        hint: 'you@example.com',
        icon: Icons.mail_outline_rounded,
      ),
      validator: (value) {
        final email = value?.trim() ?? '';
        if (email.isEmpty) {
          return 'Please enter your email.';
        }
        if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email)) {
          return 'Enter a valid email address.';
        }
        return null;
      },
    );
  }

  void _handleSubmit() {
    FocusManager.instance.primaryFocus?.unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: ink,
          duration: const Duration(seconds: 5),
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          content: const Row(
            children: [
              Icon(Icons.info_outline_rounded, color: Colors.white, size: 21),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Message submission is not configured yet. Your enquiry has not been sent.',
                  style: TextStyle(height: 1.4),
                ),
              ),
            ],
          ),
        ),
      );
  }

  InputDecoration _inputDecoration({
    required String label,
    required String hint,
    required IconData icon,
    bool alignLabelWithHint = false,
  }) {
    final outline = OutlineInputBorder(
      borderRadius: BorderRadius.circular(15),
      borderSide: const BorderSide(color: border),
    );

    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon, size: 20, color: muted),
      alignLabelWithHint: alignLabelWithHint,
      filled: true,
      fillColor: const Color(0xFFFCFBF8),
      contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 17),
      border: outline,
      enabledBorder: outline,
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: blue, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: Color(0xFFD92D20)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: Color(0xFFD92D20), width: 1.5),
      ),
    );
  }
}
