class TransactionModel {
  final String id;
  final DateTime date;
  final double amount;
  final String type; // 'income' (Recettes) or 'expense' (Dépenses)
  final String category;
  final String notes;
  final String? attachmentUrl;
  final String? memberId;
  final String? memberName;
  final bool isReimbursed;
  final bool archived;
  final int? exerciceYear;

  TransactionModel({
    required this.id,
    required this.date,
    required this.amount,
    required this.type,
    required this.category,
    required this.notes,
    this.attachmentUrl,
    this.memberId,
    this.memberName,
    this.isReimbursed = false,
    this.archived = false,
    this.exerciceYear,
  });

  factory TransactionModel.fromMap(Map<String, dynamic> data, String documentId) {
    return TransactionModel(
      id: documentId,
      // Handle the fact that 'date' might be a Firebase Timestamp OR a DateTime in local mock
      date: data['date'] is DateTime 
          ? data['date'] 
          : (data['date'] != null ? data['date'].toDate() : DateTime.now()),
      amount: (data['amount'] ?? 0).toDouble(),
      type: data['type'] ?? 'expense',
      category: data['category'] ?? '',
      notes: data['notes'] ?? '',
      attachmentUrl: data['attachmentUrl'],
      memberId: data['memberId'],
      memberName: data['memberName'],
      isReimbursed: data['isReimbursed'] ?? false,
      archived: data['archived'] ?? false,
      exerciceYear: data['exerciceYear'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'date': date,
      'amount': amount,
      'type': type,
      'category': category,
      'notes': notes,
      'attachmentUrl': attachmentUrl,
      'memberId': memberId,
      'memberName': memberName,
      'isReimbursed': isReimbursed,
      'archived': archived,
      'exerciceYear': exerciceYear,
    };
  }
}
