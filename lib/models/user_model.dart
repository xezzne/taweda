class UserModel {
  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String role; // Admin, Trésorier, Observateur, Membre
  final double annualQuota;

  UserModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.role,
    this.annualQuota = 0.0,
  });

  factory UserModel.fromMap(Map<String, dynamic> data, String documentId) {
    return UserModel(
      id: documentId,
      firstName: data['firstName'] ?? '',
      lastName: data['lastName'] ?? '',
      email: data['email'] ?? '',
      role: data['role'] ?? 'Observateur',
      annualQuota: (data['annualQuota'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'role': role,
      'annualQuota': annualQuota,
    };
  }
}
