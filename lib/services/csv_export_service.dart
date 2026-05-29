import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/transaction_model.dart';
import 'package:intl/intl.dart';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

class CsvExportService {
  static void exportToCsv(List<TransactionModel> transactions, String fileName) {
    final rows = <List<String>>[];

    // Header
    rows.add(['Date', 'Type', 'Catégorie', 'Membre / Tiers', 'Débit (MAD)', 'Crédit (MAD)', 'Notes']);

    // Data rows
    for (var t in transactions) {
      final date = DateFormat('dd/MM/yyyy').format(t.date);
      final type = t.type == 'income' ? 'Recette' : 'Dépense';
      final category = t.category;
      final member = t.memberName ?? '';
      final debit = t.type == 'expense' ? t.amount.toStringAsFixed(2) : '';
      final credit = t.type == 'income' ? t.amount.toStringAsFixed(2) : '';
      final notes = t.notes.replaceAll('"', '""'); // Escape quotes
      rows.add([date, type, category, member, debit, credit, '"$notes"']);
    }

    // Build CSV string
    final csvContent = rows.map((row) => row.join(';')).join('\n');
    final bom = '\uFEFF'; // UTF-8 BOM for Excel compatibility
    final csvBytes = utf8.encode(bom + csvContent);

    if (kIsWeb) {
      final blob = html.Blob([csvBytes], 'text/csv;charset=utf-8');
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement(href: url)
        ..setAttribute('download', '$fileName.csv')
        ..click();
      html.Url.revokeObjectUrl(url);
    }
  }
}
