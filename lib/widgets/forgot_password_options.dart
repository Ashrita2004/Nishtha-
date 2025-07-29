import 'package:flutter/material.dart';
import 'package:reporting_app/screens/email_verification_screen.dart';

class ForgotPasswordOptions extends StatelessWidget {
  const ForgotPasswordOptions({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            "Enter your email for verification",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.black54),
          ),
          const SizedBox(height: 30),

          // Email Option
          _OptionTile(
            icon: Icons.email_outlined,
            title: "Email",
            subtitle: "Reset via email Verification",
            onTap: () {
              Navigator.pop(context);
              // Navigate to email reset page
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const EmailVerificationScreen(),
                ),
              );

            },
          ),
          const SizedBox(height: 15),

          // Phone Option
        ],
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _OptionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.grey[200],
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(icon, size: 32, color: Colors.black87),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.black54,
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
