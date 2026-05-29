import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuditService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static Future<void> logAction(String action, String details) async {
    try {
      final user = _auth.currentUser;
      String userEmail = user?.email ?? 'Système';
      String userName = 'Inconnu';

      if (user != null) {
        final doc = await _firestore.collection('users').doc(user.uid).get();
        if (doc.exists) {
          final data = doc.data() as Map<String, dynamic>;
          userName = '${data['firstName']} ${data['lastName']}';
        }
      }

      await _firestore.collection('audit_logs').add({
        'action': action,
        'details': details,
        'userEmail': userEmail,
        'userName': userName,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print("Erreur lors de l'enregistrement de l'audit: $e");
    }
  }
}
