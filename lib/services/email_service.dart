import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/transaction_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EmailService {
  static const String serviceId = 'service_uc71t99';
  static const String templateId = 'template_3j0cz2i';
  static final String userId = '2R7LZ0L10P0cOFsZi';

  static Future<void> sendMonthlyReport(List<TransactionModel> transactions, String monthYear, {List<String>? customEmails}) async {
    // Calculer les totaux
    double totalCotisations = 0;
    double totalDepenses = 0;
    Map<String, double> cotisationsParMembre = {};
    Map<String, double> depensesParMembre = {};

    for (var tx in transactions) {
      String mName = tx.memberName != null && tx.memberName!.isNotEmpty
          ? tx.memberName!
          : tx.category; // Utilise la catégorie si pas de membre (ex: Subvention)
      if (tx.type == 'income') {
        totalCotisations += tx.amount;
        cotisationsParMembre[mName] = (cotisationsParMembre[mName] ?? 0) + tx.amount;
      } else if (tx.type == 'expense') {
        totalDepenses += tx.amount;
        depensesParMembre[mName] = (depensesParMembre[mName] ?? 0) + tx.amount;
      }
    }
    
    double solde = totalCotisations - totalDepenses;

    // Construire le corps de l'email
    String reportHtml = '''
      <h2>Bilan Financier Mensuel - $monthYear</h2>
      <p>Voici le bilan financier de l'association pour ce mois.</p>
      
      <h3>Résumé Global</h3>
      <ul>
        <li><strong>Total des Recettes :</strong> ${totalCotisations.toStringAsFixed(2)} MAD</li>
        <li><strong>Total des Dépenses :</strong> ${totalDepenses.toStringAsFixed(2)} MAD</li>
        <li><strong>Solde de la période :</strong> <span style="color:${solde >= 0 ? 'green' : 'red'}">${solde.toStringAsFixed(2)} MAD</span></li>
      </ul>

      <h3>Détails des Recettes (Cotisations) par Membre</h3>
      <ul>
        ${cotisationsParMembre.entries.map((e) => "<li>${e.key} : ${e.value.toStringAsFixed(2)} MAD</li>").join("\n")}
      </ul>

      <h3>Détails des Dépenses par Membre</h3>
      <ul>
        ${depensesParMembre.entries.map((e) => "<li>${e.key} : ${e.value.toStringAsFixed(2)} MAD</li>").join("\n")}
      </ul>
      
      <p>Pour plus de détails, veuillez vous connecter à l'application Tawerda.</p>
    ''';

    // Si une liste d'emails personnalisée est fournie, on l'utilise, sinon on cherche les Admins/Trésoriers
    List<Map<String, String>> recipients = [];
    
    if (customEmails != null && customEmails.isNotEmpty) {
      for (var email in customEmails) {
        if (email.trim().isNotEmpty) {
          recipients.add({'email': email.trim(), 'name': 'Membre Taweda'});
        }
      }
    } else {
      final snapshot = await FirebaseFirestore.instance.collection('users').where('role', whereIn: ['Admin', 'Trésorier']).get();
      for (var doc in snapshot.docs) {
        final data = doc.data();
        if (data['email'] != null) {
          recipients.add({'email': data['email'], 'name': data['firstName'] ?? 'Membre'});
        }
      }
    }
    
    for (var recipient in recipients) {
      final url = Uri.parse('https://api.emailjs.com/api/v1.0/email/send');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'service_id': serviceId,
          'template_id': templateId,
          'user_id': userId,
          'template_params': {
            'to_email': recipient['email'],
            'to_name': recipient['name'],
            'subject': 'Bilan Financier - $monthYear',
            'html_content': reportHtml,
          }
        }),
      );
      if (response.statusCode != 200) {
        throw Exception('EmailJS (${response.statusCode}): ${response.body}');
      }
    }
  }
}
