import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/audit_service.dart';

class CategoryProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<String> _incomeCategories = ['Cotisation', 'Subvention', 'Donation', 'Autre'];
  List<String> _expenseCategories = ['Équipement', 'Logistique', 'Événementiel', 'Déplacement', 'Autre'];

  List<String> get incomeCategories => _incomeCategories;
  List<String> get expenseCategories => _expenseCategories;

  CategoryProvider() {
    fetchCategories();
  }

  Future<void> fetchCategories() async {
    try {
      final incomeDoc = await _firestore.collection('categories').doc('income').get();
      final expenseDoc = await _firestore.collection('categories').doc('expense').get();

      if (incomeDoc.exists && incomeDoc.data()?['list'] != null) {
        _incomeCategories = List<String>.from(incomeDoc.data()!['list']);
      } else {
        // Initialize defaults in Firestore
        await _firestore.collection('categories').doc('income').set({'list': _incomeCategories});
      }

      if (expenseDoc.exists && expenseDoc.data()?['list'] != null) {
        _expenseCategories = List<String>.from(expenseDoc.data()!['list']);
      } else {
        await _firestore.collection('categories').doc('expense').set({'list': _expenseCategories});
      }

      notifyListeners();
    } catch (e) {
      print('Erreur fetchCategories: $e');
    }
  }

  Future<void> addCategory(String type, String name) async {
    if (name.trim().isEmpty) return;
    final list = type == 'income' ? _incomeCategories : _expenseCategories;
    if (list.contains(name.trim())) return;
    list.add(name.trim());
    await _firestore.collection('categories').doc(type).set({'list': list});
    notifyListeners();
    await AuditService.logAction('Catégorie', 'Ajout de la catégorie "$name" (${type == 'income' ? 'Recette' : 'Dépense'}).');
  }

  Future<void> removeCategory(String type, String name) async {
    final list = type == 'income' ? _incomeCategories : _expenseCategories;
    list.remove(name);
    await _firestore.collection('categories').doc(type).set({'list': list});
    notifyListeners();
    await AuditService.logAction('Catégorie', 'Suppression de la catégorie "$name" (${type == 'income' ? 'Recette' : 'Dépense'}).');
  }
}
