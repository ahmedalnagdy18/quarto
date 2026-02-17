import 'dart:io';

import 'package:excel/excel.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class ExportOutcomesHelper {
  static Future<void> exportSimple(
    BuildContext context,
    List<dynamic> outcomes,
  ) async {
    try {
      final excel = Excel.createExcel();
      final sheet = excel['Outcomes'];

      // رأس بسيط
      sheet.appendRow(['Outcomes Report']);
      sheet.appendRow([
        'Date:',
        DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now()),
      ]);
      sheet.appendRow([]);

      // جدول البيانات
      sheet.appendRow(['#', 'Amount (L.E)', 'Reason']);

      num total = 0;
      for (int i = 0; i < outcomes.length; i++) {
        final outcome = outcomes[i];
        sheet.appendRow([
          '${i + 1}',
          '${outcome.price}',
          outcome.note ?? 'No note',
        ]);
        total += outcome.price;
      }

      sheet.appendRow([]);
      sheet.appendRow(['TOTAL', '$total L.E', '']);

      // حفظ الملف
      final dir = await getApplicationDocumentsDirectory();
      final fileName =
          'outcomes_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.xlsx';
      final file = File('${dir.path}/$fileName');

      final fileBytes = excel.save();
      if (fileBytes != null) {
        await file.writeAsBytes(fileBytes);
        await Share.shareXFiles([XFile(file.path)], text: 'Outcomes Export');

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Exported successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}
