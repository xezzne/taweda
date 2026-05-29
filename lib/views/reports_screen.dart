import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/transaction_provider.dart';
import '../providers/report_provider.dart';
import '../providers/member_provider.dart';
import '../models/transaction_model.dart';
import '../models/member_model.dart';
import '../utils/app_colors.dart';
import '../services/email_service.dart';

class ReportsScreen extends StatefulWidget {
  @override
  _ReportsScreenState createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  DateTimeRange? _dateRange;
  String? _selectedMemberId;
  int _compareYear1 = DateTime.now().year;
  int _compareYear2 = DateTime.now().year - 1;

  Future<void> _pickDateRange() async {
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            primaryColor: AppColors.primary,
            colorScheme: ColorScheme.light(primary: AppColors.primary),
            buttonTheme: ButtonThemeData(textTheme: ButtonTextTheme.primary),
          ),
          child: child!,
        );
      },
    );
    if (range != null) {
      setState(() => _dateRange = range);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Rapports & Exports'),
          backgroundColor: AppColors.secondary,
          bottom: TabBar(
            indicatorColor: AppColors.primary,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: [
              Tab(icon: Icon(Icons.account_balance), text: 'Bilan Général'),
              Tab(icon: Icon(Icons.person), text: 'Par Membre'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildGlobalReportTab(),
            _buildMemberReportTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildGlobalReportTab() {
    final tProvider = Provider.of<TransactionProvider>(context);
    final rProvider = Provider.of<ReportProvider>(context, listen: false);

    var filteredTransactions = tProvider.transactions;
    if (_dateRange != null) {
      filteredTransactions = filteredTransactions.where((t) {
        return t.date.isAfter(_dateRange!.start) && t.date.isBefore(_dateRange!.end.add(Duration(days: 1)));
      }).toList();
    }

    double totalIncome = filteredTransactions.where((t) => t.type == 'income').fold(0.0, (sum, t) => sum + t.amount);
    double totalExpense = filteredTransactions.where((t) => t.type == 'expense').fold(0.0, (sum, t) => sum + t.amount);
    double currentBalance = totalIncome - totalExpense;

    Map<String, double> expensesByCategory = {};
    for (var t in filteredTransactions.where((t) => t.type == 'expense')) {
      expensesByCategory[t.category] = (expensesByCategory[t.category] ?? 0) + t.amount;
    }

    final colors = [Colors.red, Colors.blue, Colors.orange, Colors.purple, Colors.cyan];
    // Pre-compute colors per category to avoid index drift between chart and legend
    final Map<String, Color> categoryColors = {};
    int colorIdx = 0;
    for (var cat in expensesByCategory.keys) {
      categoryColors[cat] = colors[colorIdx++ % colors.length];
    }

    var sortedTransactions = List<TransactionModel>.from(filteredTransactions)..sort((a, b) => a.date.compareTo(b.date));
    List<FlSpot> incomeSpots = [];
    List<FlSpot> expenseSpots = [];
    double cumulativeIncome = 0;
    double cumulativeExpense = 0;
    int dayIndex = 0;

    if (sortedTransactions.isNotEmpty) {
      DateTime currentDate = sortedTransactions.first.date;
      for (var t in sortedTransactions) {
        if (t.date.difference(currentDate).inDays > 0) {
          dayIndex++;
          currentDate = t.date;
        }
        if (t.type == 'income') {
          cumulativeIncome += t.amount;
        } else {
          cumulativeExpense += t.amount;
        }
        incomeSpots.add(FlSpot(dayIndex.toDouble(), cumulativeIncome));
        expenseSpots.add(FlSpot(dayIndex.toDouble(), cumulativeExpense));
      }
    }
    
    if (incomeSpots.isEmpty) incomeSpots.add(FlSpot(0, 0));
    if (expenseSpots.isEmpty) expenseSpots.add(FlSpot(0, 0));

    // Data for Inter-Year Comparison
    final allTxs = tProvider.transactions;
    List<double> incomeY1 = List.filled(12, 0.0);
    List<double> expenseY1 = List.filled(12, 0.0);
    List<double> incomeY2 = List.filled(12, 0.0);
    List<double> expenseY2 = List.filled(12, 0.0);

    for (var t in allTxs) {
      if (t.date.year == _compareYear1) {
        if (t.type == 'income') incomeY1[t.date.month - 1] += t.amount;
        else expenseY1[t.date.month - 1] += t.amount;
      } else if (t.date.year == _compareYear2) {
        if (t.type == 'income') incomeY2[t.date.month - 1] += t.amount;
        else expenseY2[t.date.month - 1] += t.amount;
      }
    }

    double maxY = 0;
    for (int i = 0; i < 12; i++) {
      if (incomeY1[i] > maxY) maxY = incomeY1[i];
      if (expenseY1[i] > maxY) maxY = expenseY1[i];
      if (incomeY2[i] > maxY) maxY = incomeY2[i];
      if (expenseY2[i] > maxY) maxY = expenseY2[i];
    }
    maxY = maxY * 1.2;
    if (maxY == 0) maxY = 100;

    List<BarChartGroupData> comparisonGroups = [];
    for (int i = 0; i < 12; i++) {
      comparisonGroups.add(BarChartGroupData(
        x: i,
        barRods: [
          BarChartRodData(toY: incomeY1[i], color: Colors.green[700], width: 6, borderRadius: BorderRadius.circular(2)),
          BarChartRodData(toY: expenseY1[i], color: Colors.red[700], width: 6, borderRadius: BorderRadius.circular(2)),
          BarChartRodData(toY: incomeY2[i], color: Colors.green[300], width: 6, borderRadius: BorderRadius.circular(2)),
          BarChartRodData(toY: expenseY2[i], color: Colors.red[300], width: 6, borderRadius: BorderRadius.circular(2)),
        ],
      ));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ElevatedButton.icon(
            onPressed: _pickDateRange,
            icon: Icon(Icons.date_range),
            label: Text(_dateRange == null
                ? 'Filtre Global (Tous les temps)'
                : '${DateFormat('dd/MM/yyyy').format(_dateRange!.start)} - ${DateFormat('dd/MM/yyyy').format(_dateRange!.end)}'),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.secondary, foregroundColor: Colors.white),
          ),
          SizedBox(height: 16),

          // Cartes de synthèse
          Row(
            children: [
              _buildSummaryCard('Recettes', totalIncome, Colors.green),
              SizedBox(width: 8),
              _buildSummaryCard('Dépenses', totalExpense, Colors.red),
            ],
          ),
          SizedBox(height: 8),
          _buildSummaryCard('Solde Actuel', currentBalance, currentBalance >= 0 ? Colors.blue : Colors.red, isFullWidth: true),
          SizedBox(height: 24),

          Text('Bilan: Recettes vs Dépenses', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
          SizedBox(height: 16),
          Container(
            height: 250,
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)]),
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: (totalIncome > totalExpense ? totalIncome : totalExpense) * 1.2,
                barTouchData: BarTouchData(enabled: true),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) => Text(value == 0 ? 'Recettes' : 'Dépenses', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                  leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(show: false),
                borderData: FlBorderData(show: false),
                barGroups: [
                  BarChartGroupData(x: 0, barRods: [BarChartRodData(toY: totalIncome, color: Colors.green, width: 40, borderRadius: BorderRadius.circular(4))]),
                  BarChartGroupData(x: 1, barRods: [BarChartRodData(toY: totalExpense, color: Colors.red, width: 40, borderRadius: BorderRadius.circular(4))]),
                ],
              ),
            ),
          ),
          SizedBox(height: 24),

          if (sortedTransactions.isNotEmpty) ...[
            Text('Tendance Financière (Évolution)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
            SizedBox(height: 16),
            Container(
              height: 250,
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)]),
              child: LineChart(
                LineChartData(
                  lineBarsData: [
                    LineChartBarData(spots: incomeSpots, isCurved: true, color: Colors.green, barWidth: 3, belowBarData: BarAreaData(show: true, color: Colors.green.withOpacity(0.1))),
                    LineChartBarData(spots: expenseSpots, isCurved: true, color: Colors.red, barWidth: 3, belowBarData: BarAreaData(show: true, color: Colors.red.withOpacity(0.1))),
                  ],
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (value, meta) => value % 2 != 0 ? SizedBox() : Text('Jour ${value.toInt()}'))),
                  ),
                  gridData: FlGridData(show: true, drawVerticalLine: false),
                  borderData: FlBorderData(show: false),
                ),
              ),
            ),
            SizedBox(height: 24),
          ],

          if (expensesByCategory.isNotEmpty) ...[
            Text('Répartition des Dépenses', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
            SizedBox(height: 16),
            Container(
              height: 250,
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)]),
              child: Row(
                children: [
                  Expanded(
                    child: PieChart(
                      PieChartData(
                        sectionsSpace: 2,
                        centerSpaceRadius: 40,
                        sections: expensesByCategory.entries.map((e) {
                          final color = categoryColors[e.key]!;
                          return PieChartSectionData(
                            color: color,
                            value: e.value,
                            title: '${(e.value / totalExpense * 100).toStringAsFixed(1)}%',
                            radius: 50,
                            titleStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: expensesByCategory.entries.map((e) {
                      final color = categoryColors[e.key]!;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Row(children: [
                          Container(width: 12, height: 12, color: color),
                          SizedBox(width: 8),
                          Text(e.key, style: TextStyle(fontSize: 12)),
                        ]),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            SizedBox(height: 32),
          ],

          Divider(),
          SizedBox(height: 16),
          Text('Comparaison Inter-Années', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
          SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildYearSelector(
                value: _compareYear1,
                label: 'Année 1',
                color: AppColors.primary,
                onChanged: (val) => setState(() => _compareYear1 = val!),
              ),
              _buildYearSelector(
                value: _compareYear2,
                label: 'Année 2',
                color: Colors.blue[300]!,
                onChanged: (val) => setState(() => _compareYear2 = val!),
              ),
            ],
          ),
          SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(width: 10, height: 10, color: Colors.green[700]), SizedBox(width: 4), Text('Recettes A1', style: TextStyle(fontSize: 10)), SizedBox(width: 8),
              Container(width: 10, height: 10, color: Colors.red[700]), SizedBox(width: 4), Text('Dépenses A1', style: TextStyle(fontSize: 10)), SizedBox(width: 8),
              Container(width: 10, height: 10, color: Colors.green[300]), SizedBox(width: 4), Text('Recettes A2', style: TextStyle(fontSize: 10)), SizedBox(width: 8),
              Container(width: 10, height: 10, color: Colors.red[300]), SizedBox(width: 4), Text('Dépenses A2', style: TextStyle(fontSize: 10)),
            ],
          ),
          SizedBox(height: 16),
          Container(
            height: 250,
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)]),
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxY,
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        const months = ['J', 'F', 'M', 'A', 'M', 'J', 'J', 'A', 'S', 'O', 'N', 'D'];
                        return Text(months[value.toInt() % 12], style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold));
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(show: true, drawVerticalLine: false),
                borderData: FlBorderData(show: false),
                barGroups: comparisonGroups,
              ),
            ),
          ),
          SizedBox(height: 32),

          Divider(),
          SizedBox(height: 16),
          Text('Exports', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => rProvider.exportToPdf(filteredTransactions, 'Bilan Financier Global'),
                  icon: Icon(Icons.picture_as_pdf),
                  label: Text('PDF'),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, padding: EdgeInsets.symmetric(vertical: 16)),
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final path = await rProvider.exportToExcel(filteredTransactions, 'Bilan_Financier');
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Excel généré: $path')));
                  },
                  icon: Icon(Icons.table_chart),
                  label: Text('Excel'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green[700], foregroundColor: Colors.white, padding: EdgeInsets.symmetric(vertical: 16)),
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    rProvider.exportToCsv(filteredTransactions, 'Export_Comptable');
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('CSV téléchargé.')));
                  },
                  icon: Icon(Icons.description),
                  label: Text('CSV'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[700], foregroundColor: Colors.white, padding: EdgeInsets.symmetric(vertical: 16)),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => _showEmailDialog(filteredTransactions),
            icon: Icon(Icons.email),
            label: Text('Envoyer Bilan par Email (Personnalisé)'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange[700], foregroundColor: Colors.white, padding: EdgeInsets.symmetric(vertical: 16)),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String title, double amount, Color color, {bool isFullWidth = false}) {
    Widget card = Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(title, style: TextStyle(fontSize: 14, color: Colors.grey[700])),
            SizedBox(height: 8),
            Text('${amount.toStringAsFixed(2)} MAD', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
    return isFullWidth ? Container(width: double.infinity, child: card) : Expanded(child: card);
  }

  Widget _buildYearSelector({required int value, required String label, required Color color, required ValueChanged<int?> onChanged}) {
    List<int> years = List.generate(10, (index) => DateTime.now().year - index);
    return Row(
      children: [
        Text('$label:', style: TextStyle(fontWeight: FontWeight.bold, color: color)),
        SizedBox(width: 8),
        DropdownButton<int>(
          value: value,
          items: years.map((y) => DropdownMenuItem(value: y, child: Text(y.toString()))).toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildMemberReportTab() {
    final memberProvider = Provider.of<MemberProvider>(context);
    final transactionProvider = Provider.of<TransactionProvider>(context);
    final rProvider = Provider.of<ReportProvider>(context, listen: false);

    MemberModel? selectedMember;
    if (_selectedMemberId != null) {
      try {
        selectedMember = memberProvider.members.firstWhere((m) => m.id == _selectedMemberId);
      } catch (e) {
        _selectedMemberId = null;
      }
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DropdownButtonFormField<String>(
            value: _selectedMemberId,
            items: memberProvider.members
                .map((m) => DropdownMenuItem(value: m.id, child: Text('${m.firstName} ${m.lastName}')))
                .toList(),
            onChanged: (val) {
              setState(() => _selectedMemberId = val);
            },
            decoration: InputDecoration(
              labelText: 'Sélectionnez un Membre',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: Colors.white,
            ),
          ),
          SizedBox(height: 24),

          if (selectedMember != null) ...[
            // Cartes d'infos membre
            Row(
              children: [
                _buildSummaryCard('Cotisation Cible', selectedMember.totalDue, Colors.grey[800]!),
                SizedBox(width: 8),
                _buildSummaryCard('Montant Payé', selectedMember.amountPaid, Colors.green),
              ],
            ),
            SizedBox(height: 8),
            _buildSummaryCard('Reste à Payer', selectedMember.remainingToPay, selectedMember.remainingToPay > 0 ? Colors.red : Colors.green, isFullWidth: true),
            
            SizedBox(height: 24),
            Text('Avancement de la Cotisation', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
            SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: selectedMember.totalDue > 0 ? (selectedMember.amountPaid / selectedMember.totalDue).clamp(0.0, 1.0) : 0,
                minHeight: 12,
                backgroundColor: Colors.grey[300],
                color: selectedMember.remainingToPay > 0 ? AppColors.partialPaid : AppColors.fullyPaid,
              ),
            ),
            SizedBox(height: 32),

            Text('Historique de Paiements (Registre)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            ..._buildMemberTransactionsList(selectedMember, transactionProvider.transactions),
            
            SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                final memberTxs = transactionProvider.transactions.where((t) => t.memberId == selectedMember!.id).toList();
                rProvider.exportMemberStatementToPdf(selectedMember, memberTxs);
              },
              icon: Icon(Icons.picture_as_pdf),
              label: Text('Générer Relevé Individuel (PDF)'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary, 
                foregroundColor: Colors.white, 
                padding: EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ] else ...[
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Column(
                  children: [
                    Icon(Icons.person_search, size: 64, color: Colors.grey[400]),
                    SizedBox(height: 16),
                    Text('Sélectionnez un membre pour voir son rapport détaillé', style: TextStyle(color: Colors.grey[600])),
                  ],
                ),
              ),
            ),
          ]
        ],
      ),
    );
  }

  List<Widget> _buildMemberTransactionsList(MemberModel member, List<TransactionModel> allTransactions) {
    final memberTransactions = allTransactions.where((t) => t.memberId == member.id).toList();

    if (memberTransactions.isEmpty) {
      return [
        Card(
          color: Colors.grey[50],
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text('Aucune transaction trouvée pour ce membre.', textAlign: TextAlign.center, style: TextStyle(fontStyle: FontStyle.italic)),
          ),
        )
      ];
    }

    return memberTransactions.map((t) => Card(
      elevation: 1,
      margin: EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(Icons.check_circle, color: Colors.green),
        title: Text('${t.amount.toStringAsFixed(2)} MAD', style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('${DateFormat('dd/MM/yyyy').format(t.date)} - ${t.category}'),
        trailing: t.notes.isNotEmpty ? Tooltip(message: t.notes, child: Icon(Icons.info_outline, color: Colors.grey)) : null,
      ),
    )).toList();
  }

  void _showEmailDialog(List<TransactionModel> transactions) {
    DateTime now = DateTime.now();
    List<String> periodOptions = [];
    
    if (_dateRange != null) {
      periodOptions.add('${DateFormat('dd/MM/yyyy').format(_dateRange!.start)} - ${DateFormat('dd/MM/yyyy').format(_dateRange!.end)}');
    }
    
    periodOptions.add('Bilan Global (Tous les temps)');
    periodOptions.add('Bilan Annuel ${now.year}');
    periodOptions.add('Bilan Annuel ${now.year - 1}');
    
    for (int i = 0; i < 12; i++) {
      DateTime monthDate = DateTime(now.year, now.month - i, 1);
      String formattedMonth = DateFormat('MMMM yyyy', 'fr_FR').format(monthDate);
      formattedMonth = formattedMonth[0].toUpperCase() + formattedMonth.substring(1);
      if (!periodOptions.contains(formattedMonth)) {
        periodOptions.add(formattedMonth);
      }
    }

    String selectedPeriod = periodOptions.first;
    final emailsController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text('Envoyer le Bilan'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Titre / Période :', style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: selectedPeriod,
                  isExpanded: true,
                  items: periodOptions.map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (newValue) {
                    setState(() {
                      selectedPeriod = newValue!;
                    });
                  },
                  decoration: InputDecoration(border: OutlineInputBorder()),
                ),
                SizedBox(height: 16),
                Text('Emails destinataires :', style: TextStyle(fontWeight: FontWeight.bold)),
                Text('Laissez vide pour envoyer aux Admins et Trésoriers. Séparez par des virgules pour plusieurs emails.', style: TextStyle(fontSize: 12, color: Colors.grey)),
                SizedBox(height: 8),
                TextField(
                  controller: emailsController,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'ex: membre1@gmail.com, membre2@gmail.com',
                  ),
                  maxLines: 2,
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Annuler')),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
                icon: Icon(Icons.send),
                label: Text('Envoyer'),
                onPressed: () async {
                  Navigator.pop(ctx);
                  
                  List<String> emails = [];
                  if (emailsController.text.trim().isNotEmpty) {
                    emails = emailsController.text.split(',').map((e) => e.trim()).toList();
                  }
                  
                  try {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Envoi en cours...')));
                    await EmailService.sendMonthlyReport(transactions, selectedPeriod, customEmails: emails);
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Bilan envoyé avec succès !'), backgroundColor: Colors.green));
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur lors de l\'envoi : $e'), backgroundColor: Colors.red));
                  }
                },
              ),
            ],
          );
        }
      ),
    );
  }
}
