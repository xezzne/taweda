import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/member_model.dart';
import '../services/firebase_service.dart';

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
      });
      final index = _members.indexWhere((m) => m.id == member.id);
      if (index >= 0) {
        _members[index] = member;
        notifyListeners();
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
        );
        notifyListeners();
      }
    } catch (e) {
      print('Erreur addPayment: $e');
    }
  }
}
