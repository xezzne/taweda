import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    return const FirebaseOptions(
      apiKey: 'AIzaSyCif0rBHT-s4OH5paQWPOjchE0X2J_2JjA',
      appId: '1:1025678359832:web:adb4ed06d4bbd13bdcf26d',
      messagingSenderId: '1025678359832',
      projectId: 'taweda-app',
      authDomain: 'taweda-app.firebaseapp.com',
      storageBucket: 'taweda-app.firebasestorage.app',
      measurementId: 'G-TQLGRC5QST',
    );
  }
}
