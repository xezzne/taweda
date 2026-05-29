import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/member_model.dart';
import '../providers/member_provider.dart';
import '../providers/transaction_provider.dart';
import '../utils/app_colors.dart';
import 'member_detail_screen.dart';

class MembersListScreen extends StatefulWidget {
  @override
  _MembersListScreenState createState() => _MembersListScreenState();
}

class _MembersListScreenState extends State<MembersListScreen> {
  String _searchQuery = '';
  String _sortBy = 'name'; // name, paid, remaining

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
              TextField(controller: _totalDueController, decoration: InputDecoration(labelText: 'Cotisation Cible (MAD)'), keyboardType: TextInputType.number),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Annuler')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
            onPressed: () {
              if (_firstNameController.text.isEmpty) return;
              final newMember = MemberModel(
                id: '',
                firstName: _firstNameController.text.trim(),
                lastName: _lastNameController.text.trim(),
                email: _emailController.text.trim(),
                phone: _phoneController.text.trim(),
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

  void _showEditMemberDialog(BuildContext context, MemberModel member) {
    final _firstNameController = TextEditingController(text: member.firstName);
    final _lastNameController = TextEditingController(text: member.lastName);
    final _emailController = TextEditingController(text: member.email);
    final _phoneController = TextEditingController(text: member.phone);
    final _totalDueController = TextEditingController(text: member.totalDue.toString());
    final _amountPaidController = TextEditingController(text: member.amountPaid.toString());

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Modifier Membre'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: _firstNameController, decoration: InputDecoration(labelText: 'Prénom')),
              TextField(controller: _lastNameController, decoration: InputDecoration(labelText: 'Nom')),
              TextField(controller: _emailController, decoration: InputDecoration(labelText: 'Email'), keyboardType: TextInputType.emailAddress),
              TextField(controller: _phoneController, decoration: InputDecoration(labelText: 'Téléphone'), keyboardType: TextInputType.phone),
              TextField(controller: _totalDueController, decoration: InputDecoration(labelText: 'Cotisation Cible (MAD)'), keyboardType: TextInputType.number),
              TextField(controller: _amountPaidController, decoration: InputDecoration(labelText: 'Montant Payé (MAD)'), keyboardType: TextInputType.number),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Annuler')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
            onPressed: () {
              final updatedMember = MemberModel(
                id: member.id,
                firstName: _firstNameController.text,
                lastName: _lastNameController.text,
                email: _emailController.text,
                phone: _phoneController.text,
                joinDate: member.joinDate,
                totalDue: double.tryParse(_totalDueController.text) ?? 0.0,
                amountPaid: double.tryParse(_amountPaidController.text) ?? 0.0,
              );
              Provider.of<MemberProvider>(context, listen: false).updateMember(updatedMember);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Membre modifié avec succès !')));
            },
            child: Text('Enregistrer'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, MemberModel member) {
    final transactionProvider = Provider.of<TransactionProvider>(context, listen: false);
    final txCount = transactionProvider.transactions.where((t) => t.memberId == member.id).length;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Supprimer ce membre ?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Voulez-vous vraiment supprimer ${member.firstName} ${member.lastName} de l'association ?"),
            if (txCount > 0) ...[
              SizedBox(height: 12),
              Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(color: Colors.orange[50], borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.orange[200]!)),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber, color: Colors.orange, size: 20),
                    SizedBox(width: 8),
                    Expanded(child: Text('Attention : ce membre a $txCount transaction(s) dans le registre. Elles resteront présentes mais ne seront plus liées à un membre.', style: TextStyle(fontSize: 12, color: Colors.orange[800]))),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Annuler')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () {
              Provider.of<MemberProvider>(context, listen: false).deleteMember(member.id, '${member.firstName} ${member.lastName}');
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Membre supprimé.')));
            },
            child: Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final memberProvider = Provider.of<MemberProvider>(context);
    final allMembers = memberProvider.members;

    // Filter + sort
    var filtered = allMembers.where((m) {
      final q = _searchQuery.toLowerCase();
      return '${m.firstName} ${m.lastName}'.toLowerCase().contains(q) ||
          m.email.toLowerCase().contains(q) ||
          m.phone.contains(q);
    }).toList();

    filtered.sort((a, b) {
      switch (_sortBy) {
        case 'paid':
          return b.amountPaid.compareTo(a.amountPaid);
        case 'remaining':
          return b.remainingToPay.compareTo(a.remainingToPay);
        default:
          return '${a.firstName} ${a.lastName}'.compareTo('${b.firstName} ${b.lastName}');
      }
    });

    // Stats summary
    int total = allMembers.length;
    int fullyPaid = allMembers.where((m) => m.amountPaid >= m.totalDue && m.totalDue > 0).length;
    int notPaid = allMembers.where((m) => m.amountPaid == 0).length;

    return Scaffold(
      appBar: AppBar(
        title: Text('Membres & Cotisations'),
        backgroundColor: AppColors.secondary,
        actions: [
          PopupMenuButton<String>(
            icon: Icon(Icons.sort),
            onSelected: (val) => setState(() => _sortBy = val),
            itemBuilder: (ctx) => [
              PopupMenuItem(value: 'name', child: Text('Trier par Nom')),
              PopupMenuItem(value: 'paid', child: Text('Trier par Payé')),
              PopupMenuItem(value: 'remaining', child: Text('Trier par Reste')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Stats banner
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: AppColors.secondary.withOpacity(0.08),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _statChip('$total', 'Total', Colors.blue),
                _statChip('$fullyPaid', 'À jour', Colors.green),
                _statChip('$notPaid', 'Non payés', Colors.red),
              ],
            ),
          ),
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Rechercher un membre...',
                prefixIcon: Icon(Icons.search, color: Colors.grey),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                filled: true,
                fillColor: Colors.grey[100],
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 0),
              ),
              onChanged: (val) => setState(() => _searchQuery = val),
            ),
          ),
          Expanded(
            child: filtered.isEmpty
                ? Center(child: Text('Aucun membre trouvé.', style: TextStyle(color: Colors.grey)))
                : ListView.builder(
                    itemCount: filtered.length,
                    padding: EdgeInsets.all(8),
                    itemBuilder: (context, index) {
                      final member = filtered[index];
                      Color badgeColor;
                      if (member.amountPaid >= member.totalDue && member.totalDue > 0) {
                        badgeColor = AppColors.fullyPaid;
                      } else if (member.amountPaid > 0) {
                        badgeColor = AppColors.partialPaid;
                      } else {
                        badgeColor = AppColors.unpaid;
                      }

                      double progress = member.totalDue > 0 ? (member.amountPaid / member.totalDue) : 0.0;
                      if (progress > 1.0) progress = 1.0;

                      return Card(
                        margin: EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                        elevation: 2,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => MemberDetailScreen(member: member)),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: badgeColor.withOpacity(0.2),
                                  child: Text(
                                    '${member.firstName[0]}${member.lastName[0]}'.toUpperCase(),
                                    style: TextStyle(color: badgeColor, fontWeight: FontWeight.bold),
                                  ),
                                ),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text('${member.firstName} ${member.lastName}',
                                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                          if (member.debtCarriedOver > 0) ...[
                                            SizedBox(width: 6),
                                            Container(
                                              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(color: Colors.red[100], borderRadius: BorderRadius.circular(4)),
                                              child: Text('Débiteur', style: TextStyle(color: Colors.red[800], fontSize: 10, fontWeight: FontWeight.bold)),
                                            ),
                                          ],
                                        ],
                                      ),
                                      SizedBox(height: 2),
                                      Text('${member.amountPaid.toStringAsFixed(0)} / ${member.totalDue.toStringAsFixed(0)} MAD',
                                          style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                                      SizedBox(height: 6),
                                      LinearProgressIndicator(
                                        value: progress,
                                        backgroundColor: Colors.grey[200],
                                        color: badgeColor,
                                        minHeight: 5,
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(width: 8),
                                Column(
                                  children: [
                                    IconButton(
                                      icon: Icon(Icons.edit, color: Colors.blue, size: 20),
                                      onPressed: () => _showEditMemberDialog(context, member),
                                      padding: EdgeInsets.zero,
                                      constraints: BoxConstraints(),
                                    ),
                                    SizedBox(height: 8),
                                    IconButton(
                                      icon: Icon(Icons.delete, color: Colors.red, size: 20),
                                      onPressed: () => _confirmDelete(context, member),
                                      padding: EdgeInsets.zero,
                                      constraints: BoxConstraints(),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        child: Icon(Icons.add),
        onPressed: () => _showAddMemberDialog(context),
      ),
    );
  }

  Widget _statChip(String value, String label, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
      ],
    );
  }
}
