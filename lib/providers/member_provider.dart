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
    // Faux membres générés par défaut pour tester l'interface
    if (_members.isEmpty) {
      _members = [
        MemberModel(id: 'M-001', firstName: 'Ahmed', lastName: 'Benali', email: 'ahmed.benali@email.com', phone: '0612345678', joinDate: DateTime.now().subtract(Duration(days: 30)), amountPaid: 500, totalDue: 1000),
        MemberModel(id: 'M-002', firstName: 'Fatima', lastName: 'Zahra', email: 'fatima.zahra@email.com', phone: '0622334455', joinDate: DateTime.now().subtract(Duration(days: 60)), amountPaid: 1000, totalDue: 1000),
        MemberModel(id: 'M-003', firstName: 'Youssef', lastName: 'Alaoui', email: 'youssef.alaoui@email.com', phone: '0633445566', joinDate: DateTime.now().subtract(Duration(days: 15)), amountPaid: 200, totalDue: 500),
      ];
      notifyListeners();
    }
  }

  Future<void> addMember(MemberModel member) async {
    final newMember = MemberModel(
      id: 'M-00${_members.length + 4}',
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
  }

  Future<void> updateMember(MemberModel member) async {
    final index = _members.indexWhere((m) => m.id == member.id);
    if (index >= 0) {
      _members[index] = member;
      notifyListeners();
    }
  }

  Future<void> addPayment(String memberId, double amountPaid) async {
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
  }
}
