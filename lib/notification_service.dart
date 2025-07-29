import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> setupFCMToken(String gatePass) async {
  FirebaseMessaging messaging = FirebaseMessaging.instance;
  await messaging.requestPermission(alert: true, badge: true, sound: true);
  String? token = await messaging.getToken();
  if (token != null) {
    await FirebaseFirestore.instance.collection('users').doc(gatePass).update({
      'fcmToken': token,
    });
  }
  FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
    await FirebaseFirestore.instance.collection('users').doc(gatePass).update({
      'fcmToken': newToken,
    });
  });
}
