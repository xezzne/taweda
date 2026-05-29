import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/member_model.dart';
import '../services/firebase_service.dart';
import '../services/audit_service.dart';

class MemberProvider with ChangeNotifier {
  final FirebaseService _service = FirebaseService();
  List<MemberModel> _members = [];
  List<MemberModel> get members => _members;

  MemberProvider() {
    fetchMembers();
  }

  Future<void> fetchMembers() async {
    try {
      final snapshot = await _service.firestore.collection('members').get();
      _members = snapshot.docs.map((doc) {
        final data = doc.data();
        return MemberModel(
          id: doc.id,
          firstName: data['firstName'] ?? '',
          lastName: data['lastName'] ?? '',
          email: data['email'] ?? '',
          phone: data['phone'] ?? '',
          joinDate: (data['joinDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
          amountPaid: (data['amountPaid'] ?? 0).toDouble(),
          totalDue: (data['totalDue'] ?? 0).toDouble(),
          debtCarriedOver: (data['debtCarriedOver'] ?? 0).toDouble(),
        );
      }).toList();
      notifyListeners();
    } catch (e) {
      print('Erreur fetchMembers: $e');
    }
  }

  Future<void> addMember(MemberModel member) async {
    try {
      final docRef = await _service.firestore.collection('members').add({
        'firstName': member.firstName,
        'lastName': member.lastName,
        'email': member.email,
        'phone': member.phone,
        'joinDate': Timestamp.fromDate(member.joinDate),
        'amountPaid': member.amountPaid,
        'totalDue': member.totalDue,
        'debtCarriedOver': member.debtCarriedOver,
      });
      final newMember = MemberModel(
        id: docRef.id,
        firstName: member.firstName,
        lastName: member.lastName,
        email: member.email,
        phone: member.phone,
        joinDate: member.joinDate,
        amountPaid: member.amountPaid,
        totalDue: member.totalDue,
      );
      _members.add(newMember);
      notifyListeners();
      await AuditService.logAction('Ajout Membre Association', 'Le membre ${member.firstName} ${member.lastName} a été ajouté avec une cotisation cible de ${member.totalDue} MAD.');
    } catch (e) {
      print('Erreur addMember: $e');
    }
  }

  Future<void> updateMember(MemberModel member) async {
    try {
      await _service.firestore.collection('members').doc(member.id).update({
        'firstName': member.firstName,
        'lastName': member.lastName,
        'email': member.email,
        'phone': member.phone,
        'joinDate': Timestamp.fromDate(member.joinDate),
        'amountPaid': member.amountPaid,
        'totalDue': member.totalDue,
        'debtCarriedOver': member.debtCarriedOver,
      });
      final index = _members.indexWhere((m) => m.id == member.id);
      if (index >= 0) {
        _members[index] = member;
        notifyListeners();
        await AuditService.logAction('Modification Membre Association', 'Les informations du membre ${member.firstName} ${member.lastName} ont été mises à jour.');
      }
    } catch (e) {
      print('Erreur updateMember: $e');
    }
  }

  Future<void> addPayment(String memberId, double amountPaid) async {
    try {
      final docRef = _service.firestore.collection('members').doc(memberId);
      await _service.firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(docRef);
        if (!snapshot.exists) return;
        final currentPaid = (snapshot.data()?['amountPaid'] ?? 0).toDouble();
        transaction.update(docRef, {'amountPaid': currentPaid + amountPaid});
      });
      final index = _members.indexWhere((m) => m.id == memberId);
      if (index >= 0) {
        final currentMember = _members[index];
        _members[index] = MemberModel(
          id: currentMember.id,
          firstName: currentMember.firstName,
          lastName: currentMember.lastName,
          email: currentMember.email,
          phone: currentMember.phone,
          joinDate: currentMember.joinDate,
          amountPaid: currentMember.amountPaid + amountPaid,
          totalDue: currentMember.totalDue,
          debtCarriedOver: currentMember.debtCarriedOver,
        );
        notifyListeners();
      }
    } catch (e) {
      print('Erreur addPayment: $e');
    }
  }

  Future<void> deleteMember(String memberId, String fullName) async {
    try {
      await _service.firestore.collection('members').doc(memberId).delete();
      _members.removeWhere((m) => m.id == memberId);
      notifyListeners();
      await AuditService.logAction('Suppression Membre Association', 'Le membre $fullName a été supprimé.');
    } catch (e) {
      print('Erreur deleteMember: $e');
    }
  }

  /// Réinitialise les cotisations pour une nouvelle année.
  /// Les dettes restantes sont reportées sur le nouvel exercice.
  Future<void> newYearReset(double newYearAmount) async {
    try {
      for (var member in _members) {
        final debt = member.remainingToPay > 0 ? member.remainingToPay : 0.0;
        final newTotalDue = debt + newYearAmount;
        await _service.firestore.collection('members').doc(member.id).update({
          'amountPaid': 0.0,
          'totalDue': newTotalDue,
          'debtCarriedOver': debt,
        });
      }
      await fetchMembers();
      await AuditService.logAction(
        'Nouvelle Année',
        'Réinitialisation annuelle effectuée. Cotisation cible : ${newYearAmount.toStringAsFixed(0)} MAD. Les dettes ont été reportées.',
      );
    } catch (e) {
      print('Erreur newYearReset: $e');
    }
  }

  /// Efface la dette reportée d'un membre (remet totalDue = nouvelle cotisation annuelle uniquement).
  Future<void> clearMemberDebt(MemberModel member) async {
    try {
      final newTotalDue = member.totalDue - member.debtCarriedOver;
      await _service.firestore.collection('members').doc(member.id).update({
        'totalDue': newTotalDue,
        'debtCarriedOver': 0.0,
      });
      final index = _members.indexWhere((m) => m.id == member.id);
      if (index >= 0) {
        _members[index] = MemberModel(
          id: member.id,
          firstName: member.firstName,
          lastName: member.lastName,
          email: member.email,
          phone: member.phone,
          joinDate: member.joinDate,
          totalDue: newTotalDue,
          amountPaid: member.amountPaid,
          debtCarriedOver: 0.0,
        );
        notifyListeners();
      }
      await AuditService.logAction(
        'Effacement de Dette',
        'La dette de ${member.firstName} ${member.lastName} (${member.debtCarriedOver.toStringAsFixed(0)} MAD) a été effacée.',
      );
    } catch (e) {
      print('Erreur clearMemberDebt: $e');
    }
  }
}
