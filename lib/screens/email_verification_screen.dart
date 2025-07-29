import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EmailVerificationScreen extends StatefulWidget {
  const EmailVerificationScreen({super.key});

  @override
  State<EmailVerificationScreen> createState() => _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  final TextEditingController _emailController = TextEditingController();
  String? _gatePassResult;
  bool _loading = false;

  Future<void> _searchGatePassByEmail() async {
    setState(() {
      _loading = true;
      _gatePassResult = null;
    });

    try {
      final query = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: _emailController.text.trim())
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        final doc = query.docs.first;
        setState(() {
          _gatePassResult = doc.id;
        });
      } else {
        setState(() {
          _gatePassResult = 'No user found with this email.';
        });
      }
    } catch (e) {
      setState(() {
        _gatePassResult = 'Something went wrong. Try again.';
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Email Verification")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text(
              'Enter your registered email to find your Gate Pass No.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _loading ? null : _searchGatePassByEmail,
              child: _loading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Find Gate Pass'),
            ),
            const SizedBox(height: 20),
            if (_gatePassResult != null)
              Text(
                'Result: $_gatePassResult',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
          ],
        ),
      ),
    );
  }
}
