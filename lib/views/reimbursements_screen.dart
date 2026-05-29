import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/transaction_provider.dart';
import '../models/transaction_model.dart';
import '../utils/app_colors.dart';

class ReimbursementsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Notes de Frais'),
          backgroundColor: AppColors.secondary,
          bottom: TabBar(
            indicatorColor: AppColors.primary,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: [
              Tab(icon: Icon(Icons.pending_actions), text: 'À Rembourser'),
              Tab(icon: Icon(Icons.check_circle), text: 'Historique (Payé)'),
            ],
          ),
        ),
        body: Consumer<TransactionProvider>(
          builder: (context, provider, child) {
            final expenses = provider.transactions.where((t) => t.type == 'expense' && t.memberId != null && t.memberId!.isNotEmpty).toList();
            final pending = expenses.where((t) => !t.isReimbursed).toList();
            final paid = expenses.where((t) => t.isReimbursed).toList();
            final pendingTotal = pending.fold(0.0, (sum, t) => sum + t.amount);

            return Column(
              children: [
                if (pending.isNotEmpty)
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    color: Colors.orange[50],
                    child: Text(
                      '${pending.length} dépense(s) en attente — Total : ${pendingTotal.toStringAsFixed(2)} MAD',
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange[800], fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                  ),
                Expanded(
                  child: TabBarView(
                    children: [
                      _buildList(context, pending, provider, isPending: true),
                      _buildList(context, paid, provider, isPending: false),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildList(BuildContext context, List<TransactionModel> transactions, TransactionProvider provider, {required bool isPending}) {
    if (transactions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(isPending ? Icons.check_circle_outline : Icons.history, size: 64, color: Colors.grey[400]),
            SizedBox(height: 16),
            Text(isPending ? 'Aucune dépense en attente.' : 'Aucun historique de remboursement.', style: TextStyle(color: Colors.grey[600], fontSize: 16)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: transactions.length,
      itemBuilder: (context, index) {
        final t = transactions[index];
        return Card(
          elevation: 2,
          margin: EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        '${t.memberName ?? "Membre Inconnu"}',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      '${t.amount.toStringAsFixed(2)} MAD',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.red),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                    SizedBox(width: 4),
                    Text(DateFormat('dd/MM/yyyy HH:mm').format(t.date), style: TextStyle(color: Colors.grey, fontSize: 12)),
                    SizedBox(width: 16),
                    Icon(Icons.category, size: 14, color: Colors.grey),
                    SizedBox(width: 4),
                    Text(t.category, style: TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
                if (t.notes.isNotEmpty) ...[
                  SizedBox(height: 8),
                  Text('Notes: ${t.notes}', style: TextStyle(fontSize: 13, fontStyle: FontStyle.italic)),
                ],
                SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerRight,
                  child: isPending
                      ? ElevatedButton.icon(
                          onPressed: () {
                            _confirmReimbursement(context, provider, t);
                          },
                          icon: Icon(Icons.check),
                          label: Text('Marquer comme Payé'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                        )
                      : OutlinedButton.icon(
                          onPressed: () {
                            provider.toggleReimbursement(t.id, false);
                          },
                          icon: Icon(Icons.undo),
                          label: Text('Annuler le paiement'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.orange,
                          ),
                        ),
                )
              ],
            ),
          ),
        );
      },
    );
  }

  void _confirmReimbursement(BuildContext context, TransactionProvider provider, TransactionModel t) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Confirmer le remboursement'),
        content: Text('Voulez-vous vraiment marquer cette dépense de ${t.amount} MAD comme remboursée à ${t.memberName} ? L\'argent est-il bien sorti de la caisse ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Annuler')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
            onPressed: () {
              provider.toggleReimbursement(t.id, true);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Note de frais marquée comme payée.'), backgroundColor: Colors.green));
            },
            child: Text('Oui, c\'est payé'),
          ),
        ],
      ),
    );
  }
}
