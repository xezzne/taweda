import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    return const FirebaseOptions(
      apiKey: 'AIzaSyFakeKeyForTestingPurposesOnly123',
      appId: '1:1234567890:web:abcdef1234567890',
      messagingSenderId: '1234567890',
      projectId: 'taweda-test-app',
      authDomain: 'taweda-test-app.firebaseapp.com',
      storageBucket: 'taweda-test-app.appspot.com',
    );
  }
}
