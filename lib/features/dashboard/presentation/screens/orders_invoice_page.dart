import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:quarto/core/colors/app_colors.dart';
import 'package:quarto/core/fonts/app_text.dart';
import 'package:quarto/features/dashboard/data/model/external_orders_model.dart';

class OrdersInvoicePage extends StatefulWidget {
  final String orderId;
  final List<ExternalOrderItem> orderItems;

  const OrdersInvoicePage({
    super.key,
    required this.orderId,
    required this.orderItems,
  });

  @override
  State<OrdersInvoicePage> createState() => _OrdersInvoicePageState();
}

class _OrdersInvoicePageState extends State<OrdersInvoicePage> {
  /// تجميع العناصر المتشابهة
  List<Map<String, dynamic>> _groupOrderItems() {
    final Map<String, Map<String, dynamic>> grouped = {};

    for (final item in widget.orderItems) {
      if (grouped.containsKey(item.name)) {
        grouped[item.name]!['quantity'] += 1;
        grouped[item.name]!['totalPrice'] += item.price;
      } else {
        grouped[item.name] = {
          'name': item.name,
          'quantity': 1,
          'unitPrice': item.price,
          'totalPrice': item.price,
        };
      }
    }

    return grouped.values.toList();
  }

  /// حساب الإجمالي
  double get _ordersTotal {
    return widget.orderItems.fold(
      0,
      (sum, item) => sum + item.price,
    );
  }

  /// بناء PDF
  Future<pw.Document> _buildPdf() async {
    final pdf = pw.Document();
    final orderDetails = _groupOrderItems();

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

              pw.Center(child: pw.Text('Date: $todayStr')),
              pw.SizedBox(height: 20),

              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300),
                children: [
                  pw.TableRow(
                    decoration: pw.BoxDecoration(color: PdfColors.grey200),
                    children: [
                      _pdfHeader("Item"),
                      _pdfHeader("Qty"),
                      _pdfHeader("Unit Price"),
                      _pdfHeader("Total"),
                    ],
                  ),

                  for (final item in orderDetails)
                    pw.TableRow(
                      children: [
                        _pdfCell(item['name']),
                        _pdfCell(item['quantity'].toString(), center: true),
                        _pdfCell(
                          '${(item['unitPrice'] as double).toStringAsFixed(2)} L.E',
                          right: true,
                        ),
                        _pdfCell(
                          '${(item['totalPrice'] as double).toStringAsFixed(2)} L.E',
                          right: true,
                          bold: true,
                        ),
                      ],
                    ),
                ],
              ),

              pw.SizedBox(height: 20),

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

  pw.Widget _pdfHeader(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
      ),
    );
  }

  pw.Widget _pdfCell(
    String text, {
    bool right = false,
    bool center = false,
    bool bold = false,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        textAlign: center
            ? pw.TextAlign.center
            : right
            ? pw.TextAlign.right
            : pw.TextAlign.left,
        style: pw.TextStyle(
          fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
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

  bool get isMobile =>
      !kIsWeb && (defaultTargetPlatform == TargetPlatform.android);

  @override
  Widget build(BuildContext context) {
    final orderDetails = _groupOrderItems();

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
          ),
          child: SingleChildScrollView(
            child: Column(
              children: [
                Text(
                  'QUARTO RECEIPT',
                  style: AppTexts.meduimHeading.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 20),

                Table(
                  border: TableBorder.all(color: Colors.grey[300]!),
                  children: [
                    const TableRow(
                      children: [
                        Padding(
                          padding: EdgeInsets.all(10),
                          child: Text("Item"),
                        ),
                        Padding(
                          padding: EdgeInsets.all(10),
                          child: Text("Qty", textAlign: TextAlign.center),
                        ),
                        Padding(
                          padding: EdgeInsets.all(10),
                          child: Text("Unit", textAlign: TextAlign.right),
                        ),
                        Padding(
                          padding: EdgeInsets.all(10),
                          child: Text("Total", textAlign: TextAlign.right),
                        ),
                      ],
                    ),
                    for (final item in orderDetails)
                      TableRow(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(10),
                            child: Text(item['name']),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(10),
                            child: Text(
                              item['quantity'].toString(),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(10),
                            child: Text(
                              '${item['unitPrice']}',
                              textAlign: TextAlign.right,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(10),
                            child: Text(
                              '${item['totalPrice']}',
                              textAlign: TextAlign.right,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),

                const SizedBox(height: 20),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "TOTAL",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                    Text(
                      "${_ordersTotal.toStringAsFixed(2)} L.E",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                const Text(
                  "Thank you for your order!",
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
