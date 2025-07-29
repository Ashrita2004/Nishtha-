import 'package:flutter/material.dart';
import 'package:reporting_app/widgets/forgot_password_options.dart';

class ForgetPasswordScreen extends StatefulWidget {
  const ForgetPasswordScreen({super.key});

  @override
  State<ForgetPasswordScreen> createState() => _ForgetPasswordScreenState();
}

class _ForgetPasswordScreenState extends State<ForgetPasswordScreen> {
  @override
  void initState() {
    super.initState();

    // Show the modal bottom sheet after the screen builds
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showResetOptions(context);
    });
  }

  void _showResetOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      isScrollControlled: true,
      builder: (BuildContext context) {
        return const ForgotPasswordOptions(); // ✅ You already created this
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.transparent, // Optional: keeps background dim
    );
  }
}