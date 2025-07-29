import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:reporting_app/screens/dashboard.dart'; // <-- Add this import

class AuthController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // SIGN UP LOGIC
  Future<String?> signUpUser({
    required BuildContext context,
    required String name,
    required String email,
    required String gatePass,
    required String role,
  }) async {
    final docRef = _firestore.collection('users').doc(gatePass);

    try {
      final doc = await docRef.get();
      if (doc.exists) {
        return 'Gate Pass already registered';
      }

      await docRef.set({
        'name': name,
        'email': email,
        'gatePass': gatePass,
        'role': role,
      });

      // Navigate to Dashboard after success
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => DashboardScreen(gatePass: gatePass),
        ),
      );
      return null; // success
    } catch (e) {
      return 'Error: $e';
    }
  }

  // SIGN IN LOGIC
  Future<String?> signInUser({
    required BuildContext context,
    required String gatePass,
  }) async {
    try {
      final doc = await _firestore.collection('users').doc(gatePass).get();

      if (!doc.exists) {
        return 'Gate Pass number not found';
      }

      // Optionally, get user name
      // final userName = doc.data()?['name'] ?? 'User';

      // Navigate to Dashboard after success
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => DashboardScreen(gatePass: gatePass),
        ),
      );

      return null; // success
    } catch (e) {
      return 'Error occurred: ${e.toString()}';
    }
  }

  // FORGOT GATE PASS - using email
  Future<String?> getGatePassByEmail(String email) async {
    try {
      final result = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .get();

      if (result.docs.isNotEmpty) {
        return result.docs.first['gatePass'];
      } else {
        return null; // Not found
      }
    } catch (e) {
      return null;
    }
  }
}
