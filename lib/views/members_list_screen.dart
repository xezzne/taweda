import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/member_model.dart';
import '../providers/member_provider.dart';
import '../utils/app_colors.dart';
import 'member_detail_screen.dart';

class MembersListScreen extends StatefulWidget {
  @override
  _MembersListScreenState createState() => _MembersListScreenState();
}

class _MembersListScreenState extends State<MembersListScreen> {
  void _showAddMemberDialog(BuildContext context) {
    final _firstNameController = TextEditingController();
    final _lastNameController = TextEditingController();
    final _emailController = TextEditingController();
    final _phoneController = TextEditingController();
    final _totalDueController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Ajouter un Membre'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: _firstNameController, decoration: InputDecoration(labelText: 'Prénom')),
              TextField(controller: _lastNameController, decoration: InputDecoration(labelText: 'Nom')),
              TextField(controller: _emailController, decoration: InputDecoration(labelText: 'Email'), keyboardType: TextInputType.emailAddress),
              TextField(controller: _phoneController, decoration: InputDecoration(labelText: 'Téléphone'), keyboardType: TextInputType.phone),
              TextField(controller: _totalDueController, decoration: InputDecoration(labelText: 'Cotisation Initiale (MAD)'), keyboardType: TextInputType.number),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Annuler'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
            onPressed: () {
              final newMember = MemberModel(
                id: '', // Will be assigned in provider
                firstName: _firstNameController.text,
                lastName: _lastNameController.text,
                email: _emailController.text,
                phone: _phoneController.text,
                joinDate: DateTime.now(),
                totalDue: double.tryParse(_totalDueController.text) ?? 0.0,
                amountPaid: 0,
              );
              Provider.of<MemberProvider>(context, listen: false).addMember(newMember);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Membre ajouté avec succès !')));
            },
            child: Text('Ajouter'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final memberProvider = Provider.of<MemberProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Membres & Cotisations'),
        backgroundColor: AppColors.secondary,
      ),
      body: ListView.builder(
        itemCount: memberProvider.members.length,
        itemBuilder: (context, index) {
          final member = memberProvider.members[index];
          Color badgeColor;
          if (member.amountPaid >= member.totalDue) {
            badgeColor = AppColors.fullyPaid;
          } else if (member.amountPaid > 0) {
            badgeColor = AppColors.partialPaid;
          } else {
            badgeColor = AppColors.unpaid;
          }

          return Card(
            margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              title: Text('${member.firstName} ${member.lastName}', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('Reste à payer: ${member.remainingToPay} MAD'),
              trailing: Chip(
                label: Text(member.paymentStatus, style: TextStyle(color: Colors.white)),
                backgroundColor: badgeColor,
              ),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => MemberDetailScreen(member: member)),
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        child: Icon(Icons.add),
        onPressed: () => _showAddMemberDialog(context),
      ),
    );
  }
}
