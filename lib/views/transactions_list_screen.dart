import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/transaction_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/member_provider.dart';
import '../utils/app_colors.dart';
import 'transaction_form_screen.dart';
import '../models/transaction_model.dart';

enum SortOption { dateDesc, dateAsc, amountDesc, amountAsc, typeIncomeFirst, typeExpenseFirst }

class TransactionsListScreen extends StatefulWidget {
  @override
  _TransactionsListScreenState createState() => _TransactionsListScreenState();
}

class _TransactionsListScreenState extends State<TransactionsListScreen> {
  SortOption _currentSort = SortOption.dateDesc;

  void _showSortMenu() {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.calendar_today),
              title: Text('Date : Récents en premier'),
              trailing: _currentSort == SortOption.dateDesc ? Icon(Icons.check, color: AppColors.primary) : null,
              onTap: () { setState(() => _currentSort = SortOption.dateDesc); Navigator.pop(ctx); },
            ),
            ListTile(
              leading: Icon(Icons.calendar_today),
              title: Text('Date : Anciens en premier'),
              trailing: _currentSort == SortOption.dateAsc ? Icon(Icons.check, color: AppColors.primary) : null,
              onTap: () { setState(() => _currentSort = SortOption.dateAsc); Navigator.pop(ctx); },
            ),
            ListTile(
              leading: Icon(Icons.attach_money),
              title: Text('Montant : Décroissant'),
              trailing: _currentSort == SortOption.amountDesc ? Icon(Icons.check, color: AppColors.primary) : null,
              onTap: () { setState(() => _currentSort = SortOption.amountDesc); Navigator.pop(ctx); },
            ),
            ListTile(
              leading: Icon(Icons.attach_money),
              title: Text('Montant : Croissant'),
              trailing: _currentSort == SortOption.amountAsc ? Icon(Icons.check, color: AppColors.primary) : null,
              onTap: () { setState(() => _currentSort = SortOption.amountAsc); Navigator.pop(ctx); },
            ),
            ListTile(
              leading: Icon(Icons.account_balance_wallet),
              title: Text('Type : Recettes en premier'),
              trailing: _currentSort == SortOption.typeIncomeFirst ? Icon(Icons.check, color: AppColors.primary) : null,
              onTap: () { setState(() => _currentSort = SortOption.typeIncomeFirst); Navigator.pop(ctx); },
            ),
            ListTile(
              leading: Icon(Icons.shopping_cart),
              title: Text('Type : Dépenses en premier'),
              trailing: _currentSort == SortOption.typeExpenseFirst ? Icon(Icons.check, color: AppColors.primary) : null,
              onTap: () { setState(() => _currentSort = SortOption.typeExpenseFirst); Navigator.pop(ctx); },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          title: Text('Registre Comptable'),
          backgroundColor: AppColors.secondary,
          elevation: 0,
          actions: [
            IconButton(
              icon: Icon(Icons.sort),
              tooltip: 'Trier',
              onPressed: _showSortMenu,
            ),
          ],
          bottom: TabBar(
            indicatorColor: AppColors.primary,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: [
              Tab(icon: Icon(Icons.list), text: 'Exercice Actif'),
              Tab(icon: Icon(Icons.archive), text: 'Archives'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            Consumer<TransactionProvider>(
              builder: (context, provider, child) => buildTransactionListWidget(context, provider.transactions, provider, true, _currentSort),
            ),
            ArchiveTransactionsTab(sortOption: _currentSort),
          ],
        ),
      ),
    );
  }
}

Widget buildTransactionListWidget(BuildContext context, List<TransactionModel> rawTransactions, TransactionProvider provider, bool isActive, SortOption sortOption) {
  final auth = Provider.of<AuthProvider>(context, listen: false);

  List<TransactionModel> transactions = List.from(rawTransactions);
  switch (sortOption) {
    case SortOption.dateDesc: transactions.sort((a, b) => b.date.compareTo(a.date)); break;
    case SortOption.dateAsc: transactions.sort((a, b) => a.date.compareTo(b.date)); break;
    case SortOption.amountDesc: transactions.sort((a, b) => b.amount.compareTo(a.amount)); break;
    case SortOption.amountAsc: transactions.sort((a, b) => a.amount.compareTo(b.amount)); break;
    case SortOption.typeIncomeFirst:
      transactions.sort((a, b) {
        if (a.type == b.type) return b.date.compareTo(a.date);
        return a.type == 'income' ? -1 : 1;
      }); break;
    case SortOption.typeExpenseFirst:
      transactions.sort((a, b) {
        if (a.type == b.type) return b.date.compareTo(a.date);
        return a.type == 'expense' ? -1 : 1;
      }); break;
  }

    double totalIncome = transactions.where((t) => t.type == 'income').fold(0.0, (sum, t) => sum + t.amount);
    double totalExpense = transactions.where((t) => t.type == 'expense').fold(0.0, (sum, t) => sum + t.amount);
    double balance = totalIncome - totalExpense;

    return Column(
      children: [
        // En-tête de Synthèse
        Container(
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isActive ? AppColors.secondary : Colors.grey[800],
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(24),
              bottomRight: Radius.circular(24),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 10,
                offset: Offset(0, 4),
              )
            ],
          ),
          child: Column(
            children: [
              Text(
                isActive ? 'Solde de la Caisse (Actif)' : 'Solde Archivé',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              SizedBox(height: 8),
              Text(
                '${balance.toStringAsFixed(2)} MAD',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildSummaryMiniCard(
                    title: 'Entrées',
                    amount: totalIncome,
                    icon: Icons.arrow_downward,
                    color: Colors.greenAccent,
                  ),
                  Container(width: 1, height: 40, color: Colors.white24),
                  _buildSummaryMiniCard(
                    title: 'Sorties',
                    amount: totalExpense,
                    icon: Icons.arrow_upward,
                    color: Colors.redAccent,
                  ),
                ],
              ),
            ],
          ),
        ),
        
        // Liste des Transactions
        Expanded(
          child: transactions.isEmpty
              ? Center(
                  child: Text(
                    isActive ? 'Aucune transaction enregistrée.' : 'Aucune archive.',
                    style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
                  ),
                )
              : ListView.builder(
                  padding: EdgeInsets.all(16),
                  itemCount: transactions.length,
                  itemBuilder: (context, index) {
                    final t = transactions[index];
                    bool isIncome = t.type == 'income';
                    
                    return Card(
                      elevation: 2,
                      margin: EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.grey[200]!, width: 1),
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => _showTransactionDetails(context, t),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Row(
                            children: [
                              // Icône Indicateur
                              Container(
                                padding: EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: isIncome ? Colors.green[50] : Colors.red[50],
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  isIncome ? Icons.account_balance_wallet : Icons.shopping_cart,
                                  color: isIncome ? Colors.green[700] : Colors.red[700],
                                  size: 24,
                                ),
                              ),
                              SizedBox(width: 16),
                              
                              // Détails centraux
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          t.category,
                                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                        ),
                                        if (!isActive && t.exerciceYear != null) ...[
                                          SizedBox(width: 8),
                                          Container(
                                            padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(color: Colors.orange[100], borderRadius: BorderRadius.circular(4)),
                                            child: Text('${t.exerciceYear}', style: TextStyle(color: Colors.orange[800], fontSize: 10, fontWeight: FontWeight.bold)),
                                          ),
                                        ],
                                      ],
                                    ),
                                    SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Icon(Icons.calendar_today, size: 12, color: Colors.grey[600]),
                                        SizedBox(width: 4),
                                        Text(
                                          DateFormat('dd/MM/yyyy').format(t.date),
                                          style: TextStyle(color: Colors.grey[600], fontSize: 12),
                                        ),
                                      ],
                                    ),
                                    if (t.memberName != null && t.memberName!.isNotEmpty)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 4),
                                        child: Text(
                                          'Membre: ${t.memberName}',
                                          style: TextStyle(color: AppColors.primary, fontSize: 12, fontStyle: FontStyle.italic),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              
                              // Montant & Actions
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '${isIncome ? '+' : '-'}${t.amount.toStringAsFixed(2)} MAD',
                                    style: TextStyle(
                                      color: isIncome ? Colors.green[700] : Colors.red[700],
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  if (isActive && !auth.isObservateur)
                                    IconButton(
                                      padding: EdgeInsets.zero,
                                      constraints: BoxConstraints(),
                                      icon: Icon(Icons.delete_outline, color: Colors.red[300], size: 20),
                                      onPressed: () {
                                        _confirmDelete(context, provider, t);
                                      },
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
        if (isActive && !auth.isObservateur)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                FloatingActionButton.extended(
                  backgroundColor: AppColors.primary,
                  icon: Icon(Icons.add),
                  label: Text("Nouvelle Opération"),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => TransactionFormScreen()),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

Widget _buildSummaryMiniCard({required String title, required double amount, required IconData icon, required Color color}) {
    return Column(
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 16),
            SizedBox(width: 4),
            Text(title, style: TextStyle(color: Colors.white70, fontSize: 12)),
          ],
        ),
        SizedBox(height: 4),
        Text(
          '${amount.toStringAsFixed(2)}',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ],
    );
  }

void _showTransactionDetails(BuildContext context, dynamic t) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Détails de la transaction'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Catégorie: ${t.category}', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('Montant: ${t.amount} MAD'),
            SizedBox(height: 8),
            Text('Date: ${DateFormat('dd/MM/yyyy').format(t.date)}'),
            if (t.archived) ...[
              SizedBox(height: 8),
              Text('Archive de l\'année : ${t.exerciceYear}', style: TextStyle(color: Colors.orange[800], fontWeight: FontWeight.bold)),
            ],
            SizedBox(height: 8),
            if (t.memberName != null && t.memberName!.isNotEmpty) ...[
              Text('Lié au membre: ${t.memberName}'),
              SizedBox(height: 8),
            ],
            Text('Notes: ${t.notes.isNotEmpty ? t.notes : "Aucune note"}'),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Fermer')),
        ],
      ),
    );
  }

void _confirmDelete(BuildContext context, TransactionProvider transactionProvider, dynamic t) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Supprimer la transaction ?'),
        content: Text("Voulez-vous vraiment supprimer cette transaction de ${t.amount} MAD ?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Annuler')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(ctx);
              await transactionProvider.deleteTransaction(t);
              if (t.memberId != null && t.memberId!.isNotEmpty && t.type == 'income') {
                Provider.of<MemberProvider>(context, listen: false).addPayment(t.memberId!, -t.amount);
              }
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Transaction supprimée.')));
            },
            child: Text('Supprimer'),
          ),
        ],
      ),
    );
  }
class ArchiveTransactionsTab extends StatefulWidget {
  final SortOption sortOption;
  ArchiveTransactionsTab({required this.sortOption});
  @override
  _ArchiveTransactionsTabState createState() => _ArchiveTransactionsTabState();
}

class _ArchiveTransactionsTabState extends State<ArchiveTransactionsTab> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadArchives();
  }

  Future<void> _loadArchives() async {
    await Provider.of<TransactionProvider>(context, listen: false).fetchArchivedTransactions();
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    return Consumer<TransactionProvider>(
      builder: (context, provider, child) {
        return buildTransactionListWidget(context, provider.archivedTransactions, provider, false, widget.sortOption);
      },
    );
  }
}
