import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import '../models/transaction_model.dart';
import '../services/firebase_service.dart';

class TransactionProvider with ChangeNotifier {
  final FirebaseService _service = FirebaseService();
  List<TransactionModel> _transactions = [];
  List<TransactionModel> get transactions => _transactions;

  TransactionProvider() {
    fetchTransactions();
  }

  Future<void> fetchTransactions() async {
    if (_transactions.isEmpty) {
      _transactions = [
        TransactionModel(id: 'T-001', date: DateTime.now().subtract(Duration(days: 2)), amount: 500, type: 'income', category: 'Cotisation', notes: 'Cotisation annuelle', memberId: 'M-001', memberName: 'Ahmed Benali'),
        TransactionModel(id: 'T-002', date: DateTime.now().subtract(Duration(days: 1)), amount: 200, type: 'expense', category: 'Fournitures', notes: 'Achat de stylos et papier'),
      ];
      notifyListeners();
    }
  }

  Future<void> addTransaction(TransactionModel transaction, {File? imageFile}) async {
    String? imageUrl;
    if (imageFile != null) {
      imageUrl = await _service.uploadImage(imageFile, 'transactions/${DateTime.now().millisecondsSinceEpoch}.jpg');
    }

    final newTransaction = TransactionModel(
      id: 'T-00${_transactions.length + 3}',
      date: transaction.date,
      amount: transaction.amount,
      type: transaction.type,
      category: transaction.category,
      notes: transaction.notes,
      attachmentUrl: imageUrl ?? transaction.attachmentUrl,
      memberId: transaction.memberId,
      memberName: transaction.memberName,
    );

    _transactions.insert(0, newTransaction); // Ajouter en haut de la liste
    notifyListeners();
  }
}
