import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../utils/app_colors.dart';
import 'members_list_screen.dart';
import 'transactions_list_screen.dart';
import 'reports_screen.dart';
import 'admin_users_screen.dart';
import 'login_screen.dart';

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Tableau de Bord'),
        backgroundColor: AppColors.secondary,
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () async {
              await auth.signOut();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => LoginScreen()),
              );
            },
          )
        ],
      ),
      body: GridView.count(
        crossAxisCount: 2,
        padding: EdgeInsets.all(16),
        children: [
          _buildCard(context, 'Membres & Cotisations', Icons.people, MembersListScreen()),
          _buildCard(context, 'Registre Comptable', Icons.account_balance_wallet, TransactionsListScreen()),
          _buildCard(context, 'Rapports & Exports', Icons.pie_chart, ReportsScreen()),
          if (auth.isAdmin)
            _buildCard(context, 'Administration', Icons.admin_panel_settings, AdminUsersScreen()),
        ],
      ),
    );
  }

  Widget _buildCard(BuildContext context, String title, IconData icon, Widget destination) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => destination)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: AppColors.primary),
            SizedBox(height: 16),
            Text(title, textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.secondary)),
          ],
        ),
      ),
    );
  }
}
