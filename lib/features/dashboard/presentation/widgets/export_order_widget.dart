import 'dart:io';

import 'package:excel/excel.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class ExportOrdersHelper {
  // خريطة الأسعار
  static const Map<String, double> _menuItems = {
    'Water': 5,
    'Coffee': 15,
    'Tea': 10,
    'Cola': 8,
    'RedPull': 12,
    'Espresso': 20,
    'Cappuccino': 25,
    'Latte': 22,
    'Hot Chocolate': 18,
    'Others': 0,
  };

  // دالة لتحليل الـ String واستخراج العناصر
  static List<Map<String, dynamic>> _parseOrderItems(String orderString) {
    if (orderString.isEmpty) return [];

    final List<Map<String, dynamic>> parsedItems = [];
    final lines = orderString.split('\n');

    for (var line in lines) {
      line = line.trim();
      if (line.isEmpty) continue;

      String itemName = '';
      int quantity = 1;

      // استخراج الكمية من النص (مثل "Coffee x2")
      if (line.contains('x')) {
        final regex = RegExp(r'(.+?)\s*x\s*(\d+)');
        final match = regex.firstMatch(line);

        if (match != null && match.groupCount >= 2) {
          itemName = match.group(1)!.trim();
          final qtyStr = match.group(2)!;
          quantity = int.tryParse(qtyStr) ?? 1;
        } else {
          itemName = line.replaceAll('x', '').trim();
        }
      } else {
        itemName = line;
      }

      // البحث عن السعر
      double itemPrice = 0;
      if (_menuItems.containsKey(itemName)) {
        itemPrice = _menuItems[itemName]!;
      } else {
        // البحث التقريبي
        for (var key in _menuItems.keys) {
          if (itemName.toLowerCase().contains(key.toLowerCase())) {
            itemName = key;
            itemPrice = _menuItems[key]!;
            break;
          }
        }
        if (itemPrice == 0) {
          itemName = 'Others';
          itemPrice = _menuItems['Others']!;
        }
      }

      parsedItems.add({
        'name': itemName,
        'quantity': quantity,
        'unitPrice': itemPrice,
        'totalPrice': itemPrice * quantity,
      });
    }

    return parsedItems;
  }

  // الدالة الرئيسية للتصدير
  static Future<void> exportToExcel(
    BuildContext context,
    List<dynamic> orders,
  ) async {
    try {
      // إنشاء ملف Excel
      final excel = Excel.createExcel();
      final sheet = excel['Orders'];

      // إضافة عنوان
      final titleCell = sheet.cell(
        CellIndex.indexByColumnRow(rowIndex: 0, columnIndex: 0),
      );
      titleCell.cellStyle = CellStyle(
        backgroundColorHex: '#4CAF50',
        bold: true,
        fontSize: 18,
        horizontalAlign: HorizontalAlign.Center,
      );

      // دمج الخلايا للعنوان
      sheet.merge(
        CellIndex.indexByColumnRow(rowIndex: 0, columnIndex: 0),
        CellIndex.indexByColumnRow(rowIndex: 0, columnIndex: 5),
      );

      sheet.appendRow([]); // سطر فارغ

      // إضافة تاريخ التصدير
      sheet.appendRow([
        'Export Date:',
        DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now()),
        '',
        '',
        '',
        '',
      ]);
      sheet.appendRow([]); // سطر فارغ

      // إضافة رأس الجدول الرئيسي
      sheet.appendRow([
        'Order #',
        'Item',
        'Qty',
        'Unit Price',
        'Item Total',
        'Order Total',
      ]);

      // تنسيق رأس الجدول
      for (int col = 0; col < 6; col++) {
        final cell = sheet.cell(
          CellIndex.indexByColumnRow(
            rowIndex: 3, // بعد العنوان والسطر الفارغ وتاريخ التصدير
            columnIndex: col,
          ),
        );
        cell.cellStyle = CellStyle(
          backgroundColorHex: '#2196F3',
          bold: true,
          horizontalAlign: HorizontalAlign.Center,
        );
      }

      num grandTotal = 0;

      // إضافة البيانات
      for (int i = 0; i < orders.length; i++) {
        final order = orders[i];
        final parsedItems = _parseOrderItems(order.order);
        final orderTotal = order.price.toDouble();

        if (parsedItems.isEmpty) {
          // إذا لم نتمكن من تحليل العناصر، نعرض الطلب كاملاً
          sheet.appendRow([
            'Order ${i + 1}',
            order.order,
            '1',
            '${order.price}',
            '${order.price}',
            '${order.price}',
          ]);
          grandTotal += orderTotal;
        } else {
          // عرض كل عنصر على حدة
          for (int j = 0; j < parsedItems.length; j++) {
            final item = parsedItems[j];
            final isFirst = j == 0;

            sheet.appendRow([
              if (isFirst) 'Order ${i + 1}' else '',
              item['name'],
              '${item['quantity']}',
              '${item['unitPrice']} L.E',
              '${item['totalPrice']} L.E',
              if (isFirst) '$orderTotal L.E' else '',
            ]);
          }
        }

        // إضافة سطر فارغ بين الأوردرات
        sheet.appendRow(['', '', '', '', '', '']);
        grandTotal += orderTotal;
      }

      // إضافة المجموع الكلي
      sheet.appendRow(['', '', '', '', '', '']);
      sheet.appendRow([
        'TOTAL',
        '',
        '',
        '',
        '',
        '$grandTotal L.E',
      ]);

      // تنسيق سطر المجموع
      for (int col = 0; col < 6; col++) {
        final cell = sheet.cell(
          CellIndex.indexByColumnRow(
            rowIndex: sheet.maxRows - 1,
            columnIndex: col,
          ),
        );
        cell.cellStyle = CellStyle(
          backgroundColorHex: '#FF9800',
          bold: true,
          fontSize: 14,
        );
      }

      // إضافة إحصائيات
      sheet.appendRow([]);
      sheet.appendRow([
        'Total Orders:',
        orders.length.toString(),
        '',
        '',
        '',
        '',
      ]);

      // تنسيق قسم الإحصائيات
      for (int row = sheet.maxRows - 3; row < sheet.maxRows; row++) {
        for (int col = 0; col < 2; col++) {
          final cell = sheet.cell(
            CellIndex.indexByColumnRow(
              rowIndex: row,
              columnIndex: col,
            ),
          );
          cell.cellStyle = CellStyle(
            bold: col == 0 ? true : false,
          );
        }
      }

      // حفظ الملف
      final dir = await getApplicationDocumentsDirectory();
      final fileName =
          'orders_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.xlsx';
      final file = File('${dir.path}/$fileName');

      final fileBytes = excel.save();
      if (fileBytes != null) {
        await file.writeAsBytes(fileBytes);

        // مشاركة الملف
        await Share.shareXFiles(
          [XFile(file.path)],
          text: 'Orders Export',
        );

        // رسالة نجاح
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Export completed successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
