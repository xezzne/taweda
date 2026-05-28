import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/transaction_model.dart';
import 'dart:typed_data';

class PdfService {
  static Future<Uint8List> generateReport(List<TransactionModel> transactions, String title) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Header(level: 0, child: pw.Text("Taweda - $title")),
              pw.SizedBox(height: 20),
              pw.Table.fromTextArray(
                context: context,
                data: <List<String>>[
                  <String>['Date', 'Catégorie', 'Type', 'Montant', 'Notes'],
                  ...transactions.map((t) => [
                    "${t.date.day}/${t.date.month}/${t.date.year}",
                    t.category,
                    t.type,
                    "${t.amount} MAD",
                    t.notes,
                  ])
                ],
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  static Future<void> printReport(List<TransactionModel> transactions, String title) async {
    final pdfData = await generateReport(transactions, title);
    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdfData);
  }
}
