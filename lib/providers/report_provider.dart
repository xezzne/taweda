import 'package:flutter/material.dart';
import '../models/transaction_model.dart';
import '../services/pdf_service.dart';
import '../services/excel_service.dart';
import '../services/csv_export_service.dart';

class ReportProvider with ChangeNotifier {
  Future<void> exportToPdf(List<TransactionModel> data, String title) async {
    await PdfService.printReport(data, title);
  }

  Future<String> exportToExcel(List<TransactionModel> data, String fileName) async {
    return await ExcelService.generateExcel(data, fileName);
  }

  Future<void> exportMemberStatementToPdf(dynamic member, List<TransactionModel> transactions) async {
    await PdfService.printMemberReport(member, transactions);
  }

  void exportToCsv(List<TransactionModel> data, String fileName) {
    CsvExportService.exportToCsv(data, fileName);
  }
}
