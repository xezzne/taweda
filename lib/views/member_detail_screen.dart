import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/member_model.dart';
import '../providers/member_provider.dart';
import '../providers/auth_provider.dart';
import '../utils/app_colors.dart';

class MemberDetailScreen extends StatelessWidget {
  final MemberModel member;
  final TextEditingController _amountController = TextEditingController();

  MemberDetailScreen({required this.member});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: Text('Détails du Membre'),
        backgroundColor: AppColors.secondary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Nom: ${member.firstName} ${member.lastName}', style: TextStyle(fontSize: 20)),
            SizedBox(height: 10),
            Text('Cotisation Totale: ${member.totalDue} MAD', style: TextStyle(fontSize: 16)),
            Text('Montant Payé: ${member.amountPaid} MAD', style: TextStyle(fontSize: 16)),
            Text('Reste à Payer: ${member.remainingToPay} MAD', style: TextStyle(fontSize: 16)),
            SizedBox(height: 10),
            LinearProgressIndicator(
              value: member.percentageCompleted / 100,
              backgroundColor: Colors.grey[300],
              color: AppColors.primary,
              minHeight: 10,
            ),
            SizedBox(height: 20),
            if (!auth.isObservateur && member.remainingToPay > 0)
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _amountController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Nouveau versement (MAD)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: () async {
                      if (_amountController.text.isNotEmpty) {
                        double amount = double.parse(_amountController.text);
                        await Provider.of<MemberProvider>(context, listen: false)
                            .addPayment(member.id, amount);
                        Navigator.pop(context);
                      }
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
                    child: Text('Ajouter'),
                  )
                ],
              )
          ],
        ),
      ),
    );
  }
}
