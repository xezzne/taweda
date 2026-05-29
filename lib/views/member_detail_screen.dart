import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/member_model.dart';
import '../providers/member_provider.dart';
import '../providers/transaction_provider.dart';
import '../providers/auth_provider.dart';
import '../utils/app_colors.dart';
import '../models/transaction_model.dart';

class MemberDetailScreen extends StatefulWidget {
  final MemberModel member;
  MemberDetailScreen({required this.member});

  @override
  _MemberDetailScreenState createState() => _MemberDetailScreenState();
}

class _MemberDetailScreenState extends State<MemberDetailScreen> {
  final TextEditingController _amountController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final transactionProvider = Provider.of<TransactionProvider>(context);
    
    // Get this member's transactions
    final memberTransactions = transactionProvider.transactions
        .where((t) => t.memberId == widget.member.id)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    return Scaffold(
      appBar: AppBar(
        title: Text('Fiche Membre'),
        backgroundColor: AppColors.secondary,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Card
            Container(
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.secondary,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(28),
                  bottomRight: Radius.circular(28),
                ),
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: AppColors.primary,
                    child: Text(
                      '${widget.member.firstName[0]}${widget.member.lastName[0]}'.toUpperCase(),
                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                  SizedBox(height: 12),
                  Text(
                    '${widget.member.firstName} ${widget.member.lastName}',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Membre depuis ${DateFormat('MMMM yyyy', 'fr_FR').format(widget.member.joinDate)}',
                    style: TextStyle(fontSize: 13, color: Colors.white70),
                  ),
                  SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (widget.member.email.isNotEmpty)
                        _contactChip(Icons.email, widget.member.email, () async {
                          final uri = Uri.parse('mailto:${widget.member.email}');
                          if (await canLaunchUrl(uri)) launchUrl(uri);
                        }),
                      if (widget.member.phone.isNotEmpty) ...[
                        SizedBox(width: 8),
                        _contactChip(Icons.phone, widget.member.phone, () async {
                          final uri = Uri.parse('tel:${widget.member.phone}');
                          if (await canLaunchUrl(uri)) launchUrl(uri);
                        }),
                      ],
                    ],
                  )
                ],
              ),
            ),

            // Cotisation Summary
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Cotisation', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.secondary)),
                      if (!auth.isObservateur && widget.member.debtCarriedOver > 0)
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.red[50], foregroundColor: Colors.red[700], elevation: 0),
                          icon: Icon(Icons.cleaning_services, size: 16),
                          label: Text('Effacer Dette (${widget.member.debtCarriedOver.toStringAsFixed(0)})', style: TextStyle(fontSize: 12)),
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: Text('Effacer la dette ?'),
                                content: Text('Voulez-vous vraiment effacer la dette reportée de ${widget.member.debtCarriedOver.toStringAsFixed(0)} MAD pour ce membre ?'),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Annuler')),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                                    onPressed: () async {
                                      Navigator.pop(ctx);
                                      await Provider.of<MemberProvider>(context, listen: false).clearMemberDebt(widget.member);
                                      Navigator.pop(context); // Close details screen to refresh properly
                                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Dette effacée avec succès !')));
                                    },
                                    child: Text('Effacer'),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                  SizedBox(height: 12),
                  Row(
                    children: [
                      _infoCard('Cible', '${widget.member.totalDue.toStringAsFixed(0)} MAD', Colors.grey[800]!, onEdit: auth.isObservateur ? null : _editTotalDue),
                      SizedBox(width: 8),
                      _infoCard('Payé', '${widget.member.amountPaid.toStringAsFixed(0)} MAD', Colors.green),
                      SizedBox(width: 8),
                      _infoCard('Reste', '${widget.member.remainingToPay.toStringAsFixed(0)} MAD',
                          widget.member.remainingToPay > 0 ? Colors.red : Colors.green),
                    ],
                  ),
                  SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: widget.member.totalDue > 0
                          ? (widget.member.amountPaid / widget.member.totalDue).clamp(0.0, 1.0)
                          : 0,
                      minHeight: 12,
                      backgroundColor: Colors.grey[300],
                      color: widget.member.remainingToPay > 0 ? AppColors.partialPaid : AppColors.fullyPaid,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '${widget.member.percentageCompleted.toStringAsFixed(0)}% complété — Statut: ${widget.member.paymentStatus}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),

                  // Versement rapide
                  if (!auth.isObservateur && widget.member.remainingToPay > 0) ...[
                    SizedBox(height: 20),
                    Text('Enregistrer un Versement', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.secondary)),
                    SizedBox(height: 8),
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.green[200]!),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _amountController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: 'Montant (MAD)',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                fillColor: Colors.white,
                                filled: true,
                                isDense: true,
                              ),
                            ),
                          ),
                          SizedBox(width: 12),
                          ElevatedButton.icon(
                            onPressed: () async {
                              final amount = double.tryParse(_amountController.text);
                              if (amount == null || amount <= 0) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Entrez un montant valide.'), backgroundColor: Colors.red),
                                );
                                return;
                              }
                              // Create transaction in register
                              final tx = TransactionModel(
                                id: '',
                                date: DateTime.now(),
                                amount: amount,
                                type: 'income',
                                category: 'Cotisation',
                                notes: 'Versement de ${widget.member.firstName} ${widget.member.lastName}',
                                memberId: widget.member.id,
                                memberName: '${widget.member.firstName} ${widget.member.lastName}',
                              );
                              await Provider.of<TransactionProvider>(context, listen: false).addTransaction(tx);
                              await Provider.of<MemberProvider>(context, listen: false).addPayment(widget.member.id, amount);
                              _amountController.clear();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Versement de ${amount} MAD enregistré dans le registre !'), backgroundColor: Colors.green),
                              );
                              Navigator.pop(context);
                            },
                            icon: Icon(Icons.check),
                            label: Text('Valider'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Transactions History
                  SizedBox(height: 24),
                  Text('Historique des Transactions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.secondary)),
                  SizedBox(height: 8),
                  if (memberTransactions.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Text('Aucune transaction pour ce membre.', style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)),
                      ),
                    )
                  else
                    ...memberTransactions.map((t) => Card(
                      elevation: 1,
                      margin: EdgeInsets.only(bottom: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      child: ListTile(
                        leading: Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: t.type == 'income' ? Colors.green[50] : Colors.red[50],
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            t.type == 'income' ? Icons.arrow_downward : Icons.arrow_upward,
                            color: t.type == 'income' ? Colors.green[700] : Colors.red[700],
                            size: 18,
                          ),
                        ),
                        title: Text(
                          '${t.type == 'income' ? '+' : '-'}${t.amount.toStringAsFixed(2)} MAD',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: t.type == 'income' ? Colors.green[700] : Colors.red[700],
                          ),
                        ),
                        subtitle: Text('${t.category} — ${DateFormat('dd/MM/yyyy').format(t.date)}'),
                        trailing: t.notes.isNotEmpty
                            ? Tooltip(message: t.notes, child: Icon(Icons.info_outline, color: Colors.grey, size: 18))
                            : null,
                      ),
                    )).toList(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _contactChip(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white30),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: Colors.white),
            SizedBox(width: 6),
            Text(label, style: TextStyle(color: Colors.white, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  void _editTotalDue() {
    final ctrl = TextEditingController(text: widget.member.totalDue.toStringAsFixed(0));
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Modifier la cotisation cible'),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(labelText: 'Montant cible (MAD)'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Annuler')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
            onPressed: () async {
              final val = double.tryParse(ctrl.text);
              if (val != null && val >= 0) {
                Navigator.pop(ctx);
                final updatedMember = MemberModel(
                  id: widget.member.id,
                  firstName: widget.member.firstName,
                  lastName: widget.member.lastName,
                  email: widget.member.email,
                  phone: widget.member.phone,
                  joinDate: widget.member.joinDate,
                  totalDue: val,
                  amountPaid: widget.member.amountPaid,
                  debtCarriedOver: widget.member.debtCarriedOver,
                );
                await Provider.of<MemberProvider>(context, listen: false).updateMember(updatedMember);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Cotisation cible modifiée avec succès !')));
                Navigator.pop(context); // Close details screen to refresh
              }
            },
            child: Text('Enregistrer'),
          ),
        ],
      ),
    );
  }

  Widget _infoCard(String label, String value, Color color, {VoidCallback? onEdit}) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey[200]!),
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
        ),
        child: Column(
          children: [
            Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
            SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(child: Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color), textAlign: TextAlign.center, overflow: TextOverflow.ellipsis)),
                if (onEdit != null) ...[
                  SizedBox(width: 4),
                  InkWell(
                    onTap: onEdit,
                    child: Icon(Icons.edit, size: 14, color: AppColors.primary),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
