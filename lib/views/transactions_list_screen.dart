import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/transaction_provider.dart';
import '../providers/auth_provider.dart';
import '../utils/app_colors.dart';
import 'transaction_form_screen.dart';

class TransactionsListScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final transactionProvider = Provider.of<TransactionProvider>(context);
    final auth = Provider.of<AuthProvider>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: Text('Registre Comptable'),
        backgroundColor: AppColors.secondary,
      ),
      body: ListView.builder(
        itemCount: transactionProvider.transactions.length,
        itemBuilder: (context, index) {
          final t = transactionProvider.transactions[index];
          bool isIncome = t.type == 'income';
          return Card(
            margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              leading: Icon(
                isIncome ? Icons.arrow_downward : Icons.arrow_upward,
                color: isIncome ? AppColors.fullyPaid : AppColors.unpaid,
              ),
              title: Text(t.category, style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text("${t.date.day}/${t.date.month}/${t.date.year}"),
              trailing: Text(
                '${isIncome ? '+' : '-'}${t.amount} MAD',
                style: TextStyle(
                  color: isIncome ? AppColors.fullyPaid : AppColors.unpaid,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          );
        },
      ),
      floatingActionButton: auth.isObservateur
          ? null
          : FloatingActionButton(
              backgroundColor: AppColors.primary,
              child: Icon(Icons.add),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => TransactionFormScreen()),
              ),
            ),
    );
  }
}
