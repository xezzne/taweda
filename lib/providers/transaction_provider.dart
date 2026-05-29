import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import '../models/transaction_model.dart';
import '../services/firebase_service.dart';
import '../services/audit_service.dart';

class TransactionProvider with ChangeNotifier {
  final FirebaseService _service = FirebaseService();
  List<TransactionModel> _transactions = [];
  List<TransactionModel> _archivedTransactions = [];
  List<TransactionModel> get transactions => _transactions;
  List<TransactionModel> get archivedTransactions => _archivedTransactions;

  TransactionProvider() {
    fetchTransactions();
  }

  Future<void> fetchTransactions() async {
    try {
      final snapshot = await _service.firestore.collection('transactions').where('archived', isEqualTo: false).get();
      final allTx = snapshot.docs.map((doc) {
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
          isReimbursed: data['isReimbursed'] ?? false,
          archived: data['archived'] ?? false,
          exerciceYear: data['exerciceYear'],
        );
      }).toList();
      // Separate active and archived
      _transactions = allTx;
      _transactions.sort((a, b) => b.date.compareTo(a.date));
      notifyListeners();
    } catch (e) {
      print('Erreur fetchTransactions: $e');
    }
  }

  Future<void> fetchArchivedTransactions() async {
    try {
      final snapshot = await _service.firestore.collection('transactions').where('archived', isEqualTo: true).get();
      final allTx = snapshot.docs.map((doc) {
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
          isReimbursed: data['isReimbursed'] ?? false,
          archived: data['archived'] ?? false,
          exerciceYear: data['exerciceYear'],
        );
      }).toList();
      _archivedTransactions = allTx;
      _archivedTransactions.sort((a, b) => b.date.compareTo(a.date));
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
        'isReimbursed': transaction.isReimbursed,
        'archived': false,
        'exerciceYear': null,
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
        isReimbursed: transaction.isReimbursed,
      );

      _transactions.insert(0, newTransaction); // Ajouter en haut de la liste
      notifyListeners();

      String typeLabel = transaction.type == 'income' ? 'Revenu' : 'Dépense';
      await AuditService.logAction(
        'Nouvelle Transaction',
        'Un $typeLabel de ${transaction.amount} MAD a été ajouté (${transaction.category}).'
      );
    } catch (e) {
      print('Erreur addTransaction: $e');
    }
  }

  Future<void> updateTransaction(TransactionModel transaction) async {
    try {
      await _service.firestore.collection('transactions').doc(transaction.id).update({
        'date': Timestamp.fromDate(transaction.date),
        'amount': transaction.amount,
        'type': transaction.type,
        'category': transaction.category,
        'notes': transaction.notes,
        'attachmentUrl': transaction.attachmentUrl,
        'memberId': transaction.memberId,
        'memberName': transaction.memberName,
        'isReimbursed': transaction.isReimbursed,
      });

      final index = _transactions.indexWhere((t) => t.id == transaction.id);
      if (index >= 0) {
        _transactions[index] = transaction;
        notifyListeners();

        String typeLabel = transaction.type == 'income' ? 'Revenu' : 'Dépense';
        await AuditService.logAction(
          'Modification Transaction',
          'La transaction (un $typeLabel de ${transaction.amount} MAD) a été modifiée.'
        );
      }
    } catch (e) {
      print('Erreur updateTransaction: $e');
    }
  }

  Future<void> toggleReimbursement(String transactionId, bool isReimbursed) async {
    try {
      await _service.firestore.collection('transactions').doc(transactionId).update({
        'isReimbursed': isReimbursed,
      });

      final index = _transactions.indexWhere((t) => t.id == transactionId);
      if (index >= 0) {
        final t = _transactions[index];
        _transactions[index] = TransactionModel(
          id: t.id,
          date: t.date,
          amount: t.amount,
          type: t.type,
          category: t.category,
          notes: t.notes,
          attachmentUrl: t.attachmentUrl,
          memberId: t.memberId,
          memberName: t.memberName,
          isReimbursed: isReimbursed,
        );
        notifyListeners();

        await AuditService.logAction(
          'Note de Frais',
          'La dépense de ${t.amount} MAD a été marquée comme ${isReimbursed ? 'remboursée' : 'non remboursée'}.'
        );
      }
    } catch (e) {
      print('Erreur toggleReimbursement: $e');
    }
  }

  Future<void> deleteTransaction(TransactionModel transaction) async {
    try {
      await _service.firestore.collection('transactions').doc(transaction.id).delete();
      _transactions.removeWhere((t) => t.id == transaction.id);
      notifyListeners();

      String typeLabel = transaction.type == 'income' ? 'Revenu' : 'Dépense';
      await AuditService.logAction(
        'Suppression Transaction',
        'Une transaction (un $typeLabel de ${transaction.amount} MAD) a été supprimée.'
      );
    } catch (e) {
      print('Erreur deleteTransaction: $e');
    }
  }

  /// Archive toutes les transactions de l'année spécifiée
  Future<void> archiveExercice(int year) async {
    try {
      final toArchive = _transactions.where((t) => t.date.year == year).toList();
      final batch = _service.firestore.batch();
      for (var t in toArchive) {
        batch.update(_service.firestore.collection('transactions').doc(t.id), {
          'archived': true,
          'exerciceYear': year,
        });
      }
      await batch.commit();
      await fetchTransactions();
      await AuditService.logAction(
        'Clôture Exercice',
        'L\'exercice $year a été clôturé. ${toArchive.length} transaction(s) archivée(s).',
      );
    } catch (e) {
      print('Erreur archiveExercice: $e');
    }
  }
}
