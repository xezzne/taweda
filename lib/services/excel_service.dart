import 'package:excel/excel.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/transaction_model.dart';

class ExcelService {
  static Future<String> generateExcel(List<TransactionModel> transactions, String fileName) async {
    var excel = Excel.createExcel();
    Sheet sheetObject = excel['Transactions'];

    sheetObject.appendRow(['Date', 'Catégorie', 'Type', 'Montant', 'Notes']);

    for (var t in transactions) {
      sheetObject.appendRow([
        "${t.date.day}/${t.date.month}/${t.date.year}",
        t.category,
        t.type,
        t.amount,
        t.notes,
      ]);
    }

    var fileBytes = excel.save();
    var directory = await getApplicationDocumentsDirectory();
    
    File file = File('${directory.path}/$fileName.xlsx')
      ..createSync(recursive: true)
      ..writeAsBytesSync(fileBytes!);

    return file.path;
  }
}
