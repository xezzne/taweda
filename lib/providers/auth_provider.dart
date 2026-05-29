import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../services/firebase_service.dart';

class AuthProvider with ChangeNotifier {
  final FirebaseService _service = FirebaseService();
  UserModel? _currentUserData;
  User? get firebaseUser => _service.auth.currentUser;
  UserModel? get currentUserData => _currentUserData;

  AuthProvider() {
    _service.auth.authStateChanges().listen((User? user) {
      if (user != null) {
        _fetchUserData(user.uid);
      } else {
        _currentUserData = null;
        notifyListeners();
      }
    });
  }

  Future<void> _fetchUserData(String uid) async {
    final doc = await _service.firestore.collection('users').doc(uid).get();
    if (doc.exists) {
      _currentUserData = UserModel.fromMap(doc.data()!, doc.id);
      notifyListeners();
    }
  }

  Future<void> signIn(String email, String password) async {
    final cleanEmail = email.trim();
    try {
      await _service.auth.signInWithEmailAndPassword(email: cleanEmail, password: password);
      
      // Sécurité : au cas où le compte Auth a été créé mais la base de données a échoué (cas de l'Exception: Error)
      if (email == 'ahmad.amine.edaaif@gmail.com') {
        User? user = _service.auth.currentUser;
        if (user != null) {
          final doc = await _service.firestore.collection('users').doc(user.uid).get();
          if (!doc.exists) {
            await _service.firestore.collection('users').doc(user.uid).set({
              'email': email,
              'firstName': 'Ahmad Amine',
              'lastName': 'Edaaif',
              'role': 'Admin',
              'createdAt': FieldValue.serverTimestamp(),
            });
          }
        }
      }
      
      // On s'assure que les données sont chargées avant de passer à l'écran suivant
      if (_service.auth.currentUser != null) {
        await _fetchUserData(_service.auth.currentUser!.uid);
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found' || e.code == 'invalid-credential' || e.code == 'invalid-login-credentials') {
        // 1. Auto-création pour l'admin la première fois
        if (cleanEmail == 'ahmad.amine.edaaif@gmail.com') {
          try {
            final userCredential = await _service.auth.createUserWithEmailAndPassword(email: cleanEmail, password: password);
            await _service.firestore.collection('users').doc(userCredential.user!.uid).set({
              'email': cleanEmail,
              'firstName': 'Ahmad Amine',
              'lastName': 'Edaaif',
              'role': 'Admin',
              'createdAt': FieldValue.serverTimestamp(),
            });
            await _fetchUserData(userCredential.user!.uid);
            return;
          } catch (createError) {
            if (createError is FirebaseAuthException) {
              throw Exception('Erreur création auth: ${createError.code} - ${createError.message}');
            } else {
              throw Exception('Erreur création Firestore: $createError');
            }
          }
        }
        
        // 2. Auto-création pour les utilisateurs invités
        String safeEmail = cleanEmail.toLowerCase().replaceAll('.', '_');
        final inviteDoc = await _service.firestore.collection('users').doc(safeEmail).get();
        if (inviteDoc.exists) {
          final data = inviteDoc.data()!;
          if (data['isInvited'] == true && data['tempPassword'] == password) {
            try {
              final userCredential = await _service.auth.createUserWithEmailAndPassword(email: cleanEmail, password: password);
              await _service.firestore.collection('users').doc(userCredential.user!.uid).set({
                'email': data['email'],
                'firstName': data['firstName'],
                'lastName': data['lastName'],
                'role': data['role'],
                'createdAt': data['createdAt'] ?? FieldValue.serverTimestamp(),
              });
              // Optionnel: supprimer l'invitation temporaire
              await _service.firestore.collection('users').doc(safeEmail).delete();
              
              await _fetchUserData(userCredential.user!.uid);
              return;
            } catch (createError) {
              throw Exception('Erreur lors de la validation de l\'invitation: $createError');
            }
          } else if (data['isInvited'] == true) {
             throw Exception('Mot de passe temporaire incorrect.');
          }
        }
      }
      throw Exception('Erreur Firebase: ${e.code} - ${e.message}');
    } catch (e) {
      throw Exception('Erreur inconnue: $e');
    }
  }

  Future<void> signOut() async {
    _currentUserData = null;
    notifyListeners();
  }

  bool get isAdmin => _currentUserData?.role == 'Admin';
  bool get isTresorier => _currentUserData?.role == 'Trésorier';
  bool get isObservateur => _currentUserData?.role == 'Observateur';
}
