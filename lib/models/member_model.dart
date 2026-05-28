class MemberModel {
  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String phone;
  final DateTime joinDate;
  final double totalDue;
  final double amountPaid;

  MemberModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
    required this.joinDate,
    required this.totalDue,
    required this.amountPaid,
  });

  double get percentageCompleted => totalDue > 0 ? (amountPaid / totalDue) * 100 : 0;
  
  double get remainingToPay => totalDue - amountPaid;

  String get paymentStatus {
    if (amountPaid >= totalDue) return 'Payé totalement';
    if (amountPaid > 0) return 'Paiement partiel';
    return 'Non payé';
  }

  factory MemberModel.fromMap(Map<String, dynamic> data, String documentId) {
    return MemberModel(
      id: documentId,
      firstName: data['firstName'] ?? '',
      lastName: data['lastName'] ?? '',
      email: data['email'] ?? '',
      phone: data['phone'] ?? '',
      joinDate: data['joinDate'] != null ? data['joinDate'].toDate() : DateTime.now(),
      totalDue: (data['totalDue'] ?? 0).toDouble(),
      amountPaid: (data['amountPaid'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'phone': phone,
      'joinDate': joinDate,
      'totalDue': totalDue,
      'amountPaid': amountPaid,
    };
  }
}
