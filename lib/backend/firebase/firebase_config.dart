import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

Future initFirebase() async {
  if (kIsWeb) {
    await Firebase.initializeApp(
      options: FirebaseOptions(
        apiKey: "AIzaSyBEN-ll-AvPzektPzSUbYOcAmqE3INfgyc",
        authDomain: "lotus-lxr3lu.firebaseapp.com",
        projectId: "lotus-lxr3lu",
        storageBucket: "lotus-lxr3lu.firebasestorage.app",
        messagingSenderId: "1002353748756",
        appId: "1:1002353748756:web:ee7a377861c54d6888b001",
      ),
    );
  } else {
    await Firebase.initializeApp();
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: 50 * 1024 * 1024,
    );
  }
}
