import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/transaction_model.dart';
import 'dart:typed_data';

class PdfService {
  static Future<Uint8List> generateReport(List<TransactionModel> transactions, String title) async {
    final pdf = pw.Document();

    double totalIncome = transactions.where((t) => t.type == 'income').fold(0, (sum, t) => sum + t.amount);
    double totalExpense = transactions.where((t) => t.type == 'expense').fold(0, (sum, t) => sum + t.amount);
    double balance = totalIncome - totalExpense;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            pw.Header(
              level: 0,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text("Association Tawerda", style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
                  pw.Text(title, style: pw.TextStyle(fontSize: 18, color: PdfColors.grey700)),
                ],
              ),
            ),
            pw.SizedBox(height: 20),
            
            // Résumé Financier
            pw.Container(
              padding: pw.EdgeInsets.all(16),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey100,
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                children: [
                  _buildSummaryItem("Total Recettes", totalIncome, PdfColors.green700),
                  _buildSummaryItem("Total Dépenses", totalExpense, PdfColors.red700),
                  _buildSummaryItem("Solde Actuel", balance, balance >= 0 ? PdfColors.blue700 : PdfColors.red700),
                ],
              ),
            ),
            pw.SizedBox(height: 30),

            pw.Text("Détail des Transactions", style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 10),

            pw.TableHelper.fromTextArray(
              context: context,
              headerDecoration: pw.BoxDecoration(color: PdfColors.grey300),
              headerHeight: 30,
              cellHeight: 25,
              cellAlignments: {
                0: pw.Alignment.centerLeft,
                1: pw.Alignment.centerLeft,
                2: pw.Alignment.centerLeft,
                3: pw.Alignment.centerLeft,
                4: pw.Alignment.centerRight,
                5: pw.Alignment.centerLeft,
              },
              data: <List<String>>[
                <String>['Date', 'Type', 'Catégorie', 'Membre / Tiers', 'Montant', 'Notes'],
                ...transactions.map((t) => [
                  "${t.date.day.toString().padLeft(2, '0')}/${t.date.month.toString().padLeft(2, '0')}/${t.date.year}",
                  t.type == 'income' ? 'Recette' : 'Dépense',
                  t.category,
                  t.memberName ?? '-',
                  "${t.amount.toStringAsFixed(2)} MAD",
                  t.notes,
                ])
              ],
            ),
          ];
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildSummaryItem(String label, double amount, PdfColor color) {
    return pw.Column(
      children: [
        pw.Text(label, style: pw.TextStyle(fontSize: 12, color: PdfColors.grey800)),
        pw.SizedBox(height: 4),
        pw.Text("${amount.toStringAsFixed(2)} MAD", style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: color)),
      ],
    );
  }

  static Future<void> printReport(List<TransactionModel> transactions, String title) async {
    final pdfData = await generateReport(transactions, title);
    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdfData);
  }

  static Future<void> printMemberReport(dynamic member, List<TransactionModel> transactions) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            pw.Header(
              level: 0,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text("Association Tawerda", style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
                  pw.Text("Relevé de Cotisation", style: pw.TextStyle(fontSize: 18, color: PdfColors.grey700)),
                ],
              ),
            ),
            pw.SizedBox(height: 20),
            
            pw.Text("Membre : ${member.firstName} ${member.lastName}", style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
            pw.Text("Email : ${member.email}", style: pw.TextStyle(fontSize: 12)),
            pw.Text("Téléphone : ${member.phone}", style: pw.TextStyle(fontSize: 12)),
            pw.SizedBox(height: 20),
            
            // Résumé Financier
            pw.Container(
              padding: pw.EdgeInsets.all(16),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey100,
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                children: [
                  _buildSummaryItem("Cotisation Cible", member.totalDue, PdfColors.grey800),
                  _buildSummaryItem("Montant Payé", member.amountPaid, PdfColors.green700),
                  _buildSummaryItem("Reste à Payer", member.remainingToPay, member.remainingToPay > 0 ? PdfColors.red700 : PdfColors.green700),
                ],
              ),
            ),
            pw.SizedBox(height: 30),

            pw.Text("Historique des Paiements", style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 10),

            if (transactions.isEmpty)
              pw.Text("Aucun paiement enregistré pour ce membre.", style: pw.TextStyle(fontStyle: pw.FontStyle.italic))
            else
              pw.TableHelper.fromTextArray(
                context: context,
                headerDecoration: pw.BoxDecoration(color: PdfColors.grey300),
                headerHeight: 30,
                cellHeight: 25,
                cellAlignments: {
                  0: pw.Alignment.centerLeft,
                  1: pw.Alignment.centerLeft,
                  2: pw.Alignment.centerRight,
                  3: pw.Alignment.centerLeft,
                },
                data: <List<String>>[
                  <String>['Date', 'Catégorie', 'Montant', 'Notes'],
                  ...transactions.map((t) => [
                    "${t.date.day.toString().padLeft(2, '0')}/${t.date.month.toString().padLeft(2, '0')}/${t.date.year}",
                    t.category,
                    "${t.amount.toStringAsFixed(2)} MAD",
                    t.notes,
                  ])
                ],
              ),
          ];
        },
      ),
    );

    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save());
  }
}
