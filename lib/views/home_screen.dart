import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/auth_provider.dart';
import '../providers/member_provider.dart';
import '../providers/transaction_provider.dart';
import '../utils/app_colors.dart';
import 'members_list_screen.dart';
import 'transactions_list_screen.dart';
import 'reports_screen.dart';
import 'admin_users_screen.dart';
import 'history_screen.dart';
import 'reimbursements_screen.dart';
import 'login_screen.dart';

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final memberProvider = Provider.of<MemberProvider>(context);
    final transactionProvider = Provider.of<TransactionProvider>(context);

    final allTx = transactionProvider.transactions;
    final totalIncome = allTx.where((t) => t.type == 'income').fold(0.0, (s, t) => s + t.amount);
    final totalExpense = allTx.where((t) => t.type == 'expense').fold(0.0, (s, t) => s + t.amount);
    final balance = totalIncome - totalExpense;

    final members = memberProvider.members;
    final lateMembers = members.where((m) => m.amountPaid < m.totalDue && m.totalDue > 0).length;
    final fullyPaidMembers = members.where((m) => m.totalDue > 0 && m.amountPaid >= m.totalDue).length;

    final pendingReimbursements = allTx.where((t) => t.type == 'expense' && t.memberId != null && t.memberId!.isNotEmpty && !t.isReimbursed);
    final pendingReimbursementsTotal = pendingReimbursements.fold(0.0, (s, t) => s + t.amount);

    final lastTx = allTx.isEmpty ? null : allTx.reduce((a, b) => a.date.isAfter(b.date) ? a : b);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text('Association Tawerda', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.secondary,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            tooltip: 'Se déconnecter',
            onPressed: () async {
              await auth.signOut();
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => LoginScreen()));
            },
          )
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // KPIs Header
            Container(
              padding: EdgeInsets.fromLTRB(20, 20, 20, 32),
              decoration: BoxDecoration(
                color: AppColors.secondary,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Solde de la Caisse', style: TextStyle(color: Colors.white60, fontSize: 13)),
                  SizedBox(height: 4),
                  Text(
                    '${balance.toStringAsFixed(2)} MAD',
                    style: TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 16),
                  Row(
                    children: [
                      _kpiChip('Entrées', '+${totalIncome.toStringAsFixed(0)} MAD', Colors.greenAccent[400]!),
                      SizedBox(width: 10),
                      _kpiChip('Sorties', '-${totalExpense.toStringAsFixed(0)} MAD', Colors.redAccent[200]!),
                    ],
                  ),
                  if (lastTx != null) ...[
                    SizedBox(height: 12),
                    Text(
                      'Dernière opération : ${DateFormat('dd/MM/yyyy').format(lastTx.date)}',
                      style: TextStyle(color: Colors.white60, fontSize: 12),
                    ),
                  ],
                ],
              ),
            ),

            SizedBox(height: 16),

            // Member Stats Row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  _summaryTile('${members.length}', 'Membres', Icons.people, Colors.blue[700]!),
                  SizedBox(width: 10),
                  _summaryTile('$fullyPaidMembers', 'À jour', Icons.check_circle, Colors.green[600]!),
                  SizedBox(width: 10),
                  _summaryTile('$lateMembers', 'En retard', Icons.warning_amber, Colors.orange[700]!),
                ],
              ),
            ),

            // Pending reimbursements banner
            if (pendingReimbursementsTotal > 0) ...[
              SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ReimbursementsScreen())),
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.orange[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.orange[300]!),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.pending_actions, color: Colors.orange[700]),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            '${pendingReimbursements.length} note(s) de frais à rembourser — ${pendingReimbursementsTotal.toStringAsFixed(0)} MAD en attente',
                            style: TextStyle(color: Colors.orange[800], fontWeight: FontWeight.w600, fontSize: 13),
                          ),
                        ),
                        Icon(Icons.chevron_right, color: Colors.orange[700]),
                      ],
                    ),
                  ),
                ),
              ),
            ],

            SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text('Navigation', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.grey[700])),
            ),
            SizedBox(height: 10),

            // Nav cards grid
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 1.4,
                children: [
                  _buildCard(context, 'Membres\n& Cotisations', Icons.people, Colors.blue[700]!, MembersListScreen()),
                  _buildCard(context, 'Registre\nComptable', Icons.account_balance_wallet, AppColors.secondary, TransactionsListScreen()),
                  _buildCard(context, 'Notes\nde Frais', Icons.receipt_long, Colors.orange[700]!, ReimbursementsScreen()),
                  _buildCard(context, 'Rapports\n& Exports', Icons.pie_chart, Colors.green[700]!, ReportsScreen()),
                  _buildCard(context, 'Historique', Icons.history, Colors.purple[700]!, HistoryScreen()),
                  if (auth.isAdmin)
                    _buildCard(context, 'Administration', Icons.admin_panel_settings, Colors.red[700]!, AdminUsersScreen()),
                ],
              ),
            ),
            SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _kpiChip(String label, String value, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: TextStyle(color: Colors.white60, fontSize: 12)),
          SizedBox(width: 6),
          Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _summaryTile(String value, String label, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6)],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            SizedBox(height: 4),
            Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
            Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(BuildContext context, String title, IconData icon, Color color, Widget destination) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      elevation: 2,
      shadowColor: Colors.black26,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => destination)),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 26, color: color),
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.secondary, fontSize: 13),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
