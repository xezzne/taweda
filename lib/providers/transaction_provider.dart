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
    try {
      final snapshot = await _service.firestore.collection('transactions').orderBy('date', descending: true).get();
      _transactions = snapshot.docs.map((doc) {
        final data = doc.data();
        return TransactionModel(
          id: doc.id,
          date: (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
          amount: (data['amount'] ?? 0).toDouble(),
          type: data['type'] ?? 'income',
          category: data['category'] ?? '',
          notes: data['notes'] ?? '',
          attachmentUrl: data['attachmentUrl'],
          memberId: data['memberId'],
          memberName: data['memberName'],
        );
      }).toList();
      notifyListeners();
    } catch (e) {
      print('Erreur fetchTransactions: $e');
    }
  }

  Future<void> addTransaction(TransactionModel transaction, {File? imageFile}) async {
    try {
      String? imageUrl;
      if (imageFile != null) {
        imageUrl = await _service.uploadImage(imageFile, 'transactions/${DateTime.now().millisecondsSinceEpoch}.jpg');
      }

      final docRef = await _service.firestore.collection('transactions').add({
        'date': Timestamp.fromDate(transaction.date),
        'amount': transaction.amount,
        'type': transaction.type,
        'category': transaction.category,
        'notes': transaction.notes,
        'attachmentUrl': imageUrl ?? transaction.attachmentUrl,
        'memberId': transaction.memberId,
        'memberName': transaction.memberName,
      });

      final newTransaction = TransactionModel(
        id: docRef.id,
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
    } catch (e) {
      print('Erreur addTransaction: $e');
    }
  }
}
