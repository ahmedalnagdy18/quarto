import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:quarto/core/colors/app_colors.dart';
import 'package:quarto/core/fonts/app_text.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class OrdersInvoicePage extends StatefulWidget {
  final String orderId;
  final String orderItems;
  final int totalPrice;

  const OrdersInvoicePage({
    super.key,
    required this.orderId,
    required this.orderItems,
    required this.totalPrice,
  });

  @override
  State<OrdersInvoicePage> createState() => _InvoicePageState();
}

class _InvoicePageState extends State<OrdersInvoicePage> {
  final Map<String, double> _menuItems = {
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

  int get _ordersTotal => widget.totalPrice;

  List<Map<String, dynamic>> _parseOrderItems() {
    if (widget.orderItems.isEmpty) return [];

    final List<Map<String, dynamic>> parsedItems = [];

    // تقسيم السطور
    final lines = widget.orderItems.split('\n');

    for (var line in lines) {
      line = line.trim();
      if (line.isEmpty) continue;

      String itemName = '';
      int quantity = 1;

      // التحقق من وجود نمط "اسم xكمية"
      if (line.contains('x')) {
        // دعم عدة أشكال: "Coffee x2", "Coffee x 2", "Coffee x:2"
        final regex = RegExp(r'(.+?)\s*x\s*(\d+)');
        final match = regex.firstMatch(line);

        if (match != null && match.groupCount >= 2) {
          itemName = match.group(1)!.trim();
          final qtyStr = match.group(2)!;
          quantity = int.tryParse(qtyStr) ?? 1;
        } else {
          // إذا لم يتطابق النمط، اعتبر الكل كاسم
          itemName = line.replaceAll('x', '').trim();
        }
      } else {
        itemName = line;
        quantity = 1;
      }

      // البحث عن السعر في الخريطة
      double itemPrice = 0;
      if (_menuItems.containsKey(itemName)) {
        itemPrice = _menuItems[itemName]!;
      } else {
        // البحث في القيم التي تحتوي على المسافات
        bool found = false;
        for (var key in _menuItems.keys) {
          if (itemName.contains(key) || key.contains(itemName)) {
            itemName = key;
            itemPrice = _menuItems[key]!;
            found = true;
            break;
          }
        }
        if (!found) {
          itemName = 'Others';
          itemPrice = _menuItems['Others']!;
        }
      }

      // إضافة العنصر
      parsedItems.add({
        'name': itemName,
        'quantity': quantity,
        'unitPrice': itemPrice,
        'totalPrice': itemPrice * quantity,
      });
    }

    // تجميع العناصر المتشابهة
    return _groupOrderItems(parsedItems);
  }

  List<Map<String, dynamic>> _groupOrderItems(
    List<Map<String, dynamic>> items,
  ) {
    final Map<String, Map<String, dynamic>> grouped = {};

    for (var item in items) {
      final key = item['name'];
      final unitPrice = item['unitPrice'] as double;
      final qty = item['quantity'] as int;
      final total = item['totalPrice'] as double;

      if (grouped.containsKey(key)) {
        final existing = grouped[key]!;
        existing['quantity'] = (existing['quantity'] as int) + qty;
        existing['totalPrice'] = (existing['totalPrice'] as double) + total;
      } else {
        grouped[key] = {
          'name': key,
          'quantity': qty,
          'unitPrice': unitPrice,
          'totalPrice': total,
        };
      }
    }

    return grouped.values.toList();
  }

  Future<pw.Document> _buildPdf() async {
    final pdf = pw.Document();
    final orderDetails = _parseOrderItems();

    final today = DateTime.now();
    final todayStr =
        '${today.day.toString().padLeft(2, '0')}-${today.month.toString().padLeft(2, '0')}-${today.year}';

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Center(
                child: pw.Text(
                  'QUARTO RECEIPT',
                  style: pw.TextStyle(
                    fontSize: 20,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.SizedBox(height: 6),
              pw.Center(child: pw.Text('Order #${widget.orderId}')),
              pw.SizedBox(height: 12),

              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.center,
                children: [
                  pw.Text(
                    'Date: $todayStr',
                    style: pw.TextStyle(
                      fontSize: 12,
                      color: PdfColors.black,
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 20),

              if (orderDetails.isNotEmpty) ...[
                pw.Text(
                  'Order Details',
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 8),

                // جدول تفاصيل الطلب
                pw.Table(
                  border: pw.TableBorder.all(color: PdfColors.grey300),
                  children: [
                    pw.TableRow(
                      decoration: pw.BoxDecoration(color: PdfColors.grey200),
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(
                            'Item',
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(
                            'Qty',
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                            textAlign: pw.TextAlign.center,
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(
                            'Unit Price',
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                            textAlign: pw.TextAlign.right,
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(
                            'Total',
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                            textAlign: pw.TextAlign.right,
                          ),
                        ),
                      ],
                    ),

                    for (final item in orderDetails)
                      pw.TableRow(
                        children: [
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8),
                            child: pw.Text(item['name']),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8),
                            child: pw.Text(
                              item['quantity'].toString(),
                              textAlign: pw.TextAlign.center,
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8),
                            child: pw.Text(
                              '${(item['unitPrice'] as double).toStringAsFixed(2)} L.E',
                              textAlign: pw.TextAlign.right,
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8),
                            child: pw.Text(
                              '${(item['totalPrice'] as double).toStringAsFixed(2)} L.E',
                              textAlign: pw.TextAlign.right,
                              style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),

                pw.SizedBox(height: 20),
                pdfDashedDivider(),
              ],

              // المجموع النهائي
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'TOTAL',
                    style: pw.TextStyle(
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    '${_ordersTotal.toStringAsFixed(2)} L.E',
                    style: pw.TextStyle(
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.black,
                    ),
                  ),
                ],
              ),

              pw.SizedBox(height: 20),
              pw.Center(
                child: pw.Text(
                  'Thank you for your order!',
                  style: const pw.TextStyle(color: PdfColors.grey),
                ),
              ),
            ],
          );
        },
      ),
    );

    return pdf;
  }

  Future<void> _savePdf() async {
    final pdf = await _buildPdf();
    final dir = await getApplicationDocumentsDirectory();
    final file = File(
      '${dir.path}/invoice_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
    await file.writeAsBytes(await pdf.save());

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invoice saved successfully')),
      );
    }
  }

  Future<void> _saveAndPrintPdf() async {
    final pdf = await _buildPdf();
    final bytes = await pdf.save();
    final dir = await getApplicationDocumentsDirectory();
    final file = File(
      '${dir.path}/invoice_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
    await file.writeAsBytes(bytes);
    await Printing.layoutPdf(onLayout: (_) async => bytes);
  }

  pw.Widget pdfDashedDivider() {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 12),
      child: pw.Row(
        children: List.generate(
          40,
          (index) => pw.Expanded(
            child: pw.Container(
              height: 1,
              color: index.isEven ? PdfColors.grey : PdfColors.white,
            ),
          ),
        ),
      ),
    );
  }

  bool get isMobile =>
      !kIsWeb && (defaultTargetPlatform == TargetPlatform.android);

  @override
  Widget build(BuildContext context) {
    final orderDetails = _parseOrderItems();

    return Scaffold(
      backgroundColor: AppColors.bgCard,
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: AppColors.bgDark,
        title: Text('Order #${widget.orderId}', style: AppTexts.smallHeading),
        centerTitle: true,
        actions: [
          if (!isMobile)
            IconButton(onPressed: _savePdf, icon: const Icon(Icons.save)),
          IconButton(
            onPressed: _saveAndPrintPdf,
            icon: const Icon(Icons.print),
          ),
          const SizedBox(width: 20),
        ],
      ),
      body: Center(
        child: Container(
          width: 500,
          padding: const EdgeInsets.all(20),
          margin: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Text(
                    'QUARTO RECEIPT',
                    style: AppTexts.meduimHeading.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Center(
                  child: Text(
                    'Order #${widget.orderId}',
                    style: AppTexts.smallBody.copyWith(color: Colors.black),
                  ),
                ),
                const SizedBox(height: 12),
                Center(
                  child: Text(
                    'Date: ${DateTime.now().day.toString().padLeft(2, '0')}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().year}',
                    style: AppTexts.smallBody.copyWith(color: Colors.black),
                  ),
                ),
                const SizedBox(height: 20),
                _divider(),

                if (orderDetails.isNotEmpty) ...[
                  Text(
                    'Order Details',
                    style: AppTexts.meduimHeading.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 12),

                  Table(
                    border: TableBorder.all(color: Colors.grey[300]!),
                    children: [
                      TableRow(
                        decoration: BoxDecoration(color: Colors.grey[100]),
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: Text(
                              'Item',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: Text(
                              'Qty',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: Text(
                              'Unit Price',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                              textAlign: TextAlign.right,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: Text(
                              'Total',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                              textAlign: TextAlign.right,
                            ),
                          ),
                        ],
                      ),

                      for (final item in orderDetails)
                        TableRow(
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(12),
                              child: Text(
                                item['name'],
                                style: TextStyle(color: Colors.black),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(12),
                              child: Text(
                                item['quantity'].toString(),
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.black),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(12),
                              child: Text(
                                '${(item['unitPrice'] as double).toStringAsFixed(2)} L.E',
                                textAlign: TextAlign.right,
                                style: TextStyle(color: Colors.black),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(12),
                              child: Text(
                                '${(item['totalPrice'] as double).toStringAsFixed(2)} L.E',
                                textAlign: TextAlign.right,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),

                  const SizedBox(height: 20),
                  _divider(),
                ],

                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'TOTAL',
                        style: AppTexts.meduimHeading.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      Text(
                        '${_ordersTotal.toStringAsFixed(2)} L.E',
                        style: AppTexts.meduimHeading.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                          fontSize: 22,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),
                Center(
                  child: Text(
                    'Thank you for your order!',
                    style: AppTexts.smallBody.copyWith(color: Colors.grey),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _divider() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: List.generate(
          40,
          (index) => Expanded(
            child: Container(
              height: 1,
              color: index.isEven ? Colors.grey[400]! : Colors.transparent,
            ),
          ),
        ),
      ),
    );
  }
}
