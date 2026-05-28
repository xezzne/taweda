import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
    // Fake login for UI testing since Firebase is not properly configured
    _currentUserData = UserModel(
      id: 'test-user-id',
      firstName: 'Admin',
      lastName: 'Local',
      email: email,
      role: 'Admin',
    );
    notifyListeners();
  }

  Future<void> signOut() async {
    _currentUserData = null;
    notifyListeners();
  }

  bool get isAdmin => _currentUserData?.role == 'Admin';
  bool get isTresorier => _currentUserData?.role == 'Trésorier';
  bool get isObservateur => _currentUserData?.role == 'Observateur';
}
