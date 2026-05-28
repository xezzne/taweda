import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/transaction_provider.dart';
import '../providers/report_provider.dart';
import '../models/transaction_model.dart';
import '../utils/app_colors.dart';

class ReportsScreen extends StatefulWidget {
  @override
  _ReportsScreenState createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  DateTimeRange? _dateRange;

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

    Map<String, double> expensesByCategory = {};
    for (var t in filteredTransactions.where((t) => t.type == 'expense')) {
      expensesByCategory[t.category] = (expensesByCategory[t.category] ?? 0) + t.amount;
    }

    final colors = [Colors.red, Colors.blue, Colors.orange, Colors.purple, Colors.cyan];
    int colorIndex = 0;

    // Calcul pour le LineChart : Evolution dans le temps
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
    
    // Pour ne pas avoir des tableaux vides si tout s'est passé le jour 0
    if (incomeSpots.isEmpty) incomeSpots.add(FlSpot(0, 0));
    if (expenseSpots.isEmpty) expenseSpots.add(FlSpot(0, 0));

    return Scaffold(
      appBar: AppBar(title: Text('Tableau de Bord'), backgroundColor: AppColors.secondary),
      body: SingleChildScrollView(
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
            SizedBox(height: 24),

            // Bar Chart: Recettes vs Dépenses
            Text('Bilan: Recettes vs Dépenses', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
            SizedBox(height: 16),
            Container(
              height: 250,
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
              ),
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: (totalIncome > totalExpense ? totalIncome : totalExpense) * 1.2,
                  barTouchData: BarTouchData(enabled: true),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          return Text(value == 0 ? 'Recettes' : 'Dépenses', style: TextStyle(fontWeight: FontWeight.bold));
                        },
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

            // Line Chart: Evolution dans le temps
            if (sortedTransactions.isNotEmpty) ...[
              Text('Tendance Financière (Évolution)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
              SizedBox(height: 16),
              Container(
                height: 250,
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
                ),
                child: LineChart(
                  LineChartData(
                    lineBarsData: [
                      LineChartBarData(
                        spots: incomeSpots,
                        isCurved: true,
                        color: Colors.green,
                        barWidth: 3,
                        belowBarData: BarAreaData(show: true, color: Colors.green.withOpacity(0.1)),
                      ),
                      LineChartBarData(
                        spots: expenseSpots,
                        isCurved: true,
                        color: Colors.red,
                        barWidth: 3,
                        belowBarData: BarAreaData(show: true, color: Colors.red.withOpacity(0.1)),
                      ),
                    ],
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            if (value % 2 != 0) return SizedBox();
                            return Text('Jour ${value.toInt()}');
                          },
                        ),
                      ),
                    ),
                    gridData: FlGridData(show: true, drawVerticalLine: false),
                    borderData: FlBorderData(show: false),
                  ),
                ),
              ),
              SizedBox(height: 24),
            ],

            // Pie Chart: Dépenses par catégorie
            if (expensesByCategory.isNotEmpty) ...[
              Text('Répartition des Dépenses', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
              SizedBox(height: 16),
              Container(
                height: 250,
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: PieChart(
                        PieChartData(
                          sectionsSpace: 2,
                          centerSpaceRadius: 40,
                          sections: expensesByCategory.entries.map((e) {
                            final color = colors[colorIndex++ % colors.length];
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
                        final color = colors[(colorIndex - expensesByCategory.length + expensesByCategory.entries.toList().indexOf(e)) % colors.length];
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          child: Row(
                            children: [
                              Container(width: 12, height: 12, color: color),
                              SizedBox(width: 8),
                              Text(e.key, style: TextStyle(fontSize: 12)),
                            ],
                          ),
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
            Text('Exports', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => rProvider.exportToPdf(filteredTransactions, 'Bilan Financier'),
                    icon: Icon(Icons.picture_as_pdf),
                    label: Text('PDF'),
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, padding: EdgeInsets.symmetric(vertical: 16)),
                  ),
                ),
                SizedBox(width: 16),
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
              ],
            ),
          ],
        ),
      ),
    );
  }
}
