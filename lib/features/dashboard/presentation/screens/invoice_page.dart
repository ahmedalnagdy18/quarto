import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:quarto/core/colors/app_colors.dart';
import 'package:quarto/core/fonts/app_text.dart';
import 'package:quarto/features/dashboard/data/model/room_model.dart';
import 'package:quarto/features/dashboard/data/model/session_history_model.dart';
import 'package:quarto/features/dashboard/presentation/screens/history_details_page.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class InvoicePage extends StatefulWidget {
  const InvoicePage({
    super.key,
    required this.sessionHistory,
    required this.room,
    required this.orderItem,
  });

  final SessionHistory sessionHistory;
  final Room room;
  final List<OrderItem> orderItem;

  @override
  State<InvoicePage> createState() => _HistoryDetailsPageState();
}

class _HistoryDetailsPageState extends State<InvoicePage> {
  Future<pw.Document> _buildPdf() async {
    final pdf = pw.Document();

    final double ordersTotal = widget.orderItem.fold(
      0,
      (sum, item) => sum + item.price,
    );

    final double grandTotal = widget.sessionHistory.totalCost + ordersTotal;

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
              pw.Center(child: pw.Text(widget.room.name)),
              pw.SizedBox(height: 20),

              _pdfRow('Start Time', widget.sessionHistory.startTimeShort),
              _pdfRow('End Time', widget.sessionHistory.endTimeShort),
              _pdfRow('Duration', widget.sessionHistory.formattedDuration),

              if (widget.sessionHistory.sessionTypeInfo.isNotEmpty)
                _pdfRow('Type', widget.sessionHistory.sessionTypeInfo),

              pdfDashedDivider(),

              if (widget.orderItem.isNotEmpty) ...[
                pw.Text(
                  'Drinks',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
                pw.SizedBox(height: 8),
                ...widget.orderItem.map(
                  (order) => _pdfRow(
                    order.name,
                    '${order.price.toStringAsFixed(0)} \$',
                  ),
                ),
                pdfDashedDivider(),
              ],

              _pdfRow(
                'Session Cost',
                widget.sessionHistory.formattedCost,
              ),
              _pdfRow(
                'Drinks Total',
                '${ordersTotal.toStringAsFixed(0)} \$',
              ),

              pdfDashedDivider(),

              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'TOTAL',
                    style: pw.TextStyle(
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    '${grandTotal.toStringAsFixed(0)} \$',
                    style: pw.TextStyle(
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ],
              ),

              pw.SizedBox(height: 20),
              pw.Center(
                child: pw.Text(
                  'Thank you for playing',
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

    await Printing.layoutPdf(
      onLayout: (_) async => bytes,
    );
  }

  double get _ordersTotal {
    return widget.orderItem.fold(0, (sum, item) => sum + item.price);
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

  @override
  Widget build(BuildContext context) {
    final double grandTotal = widget.sessionHistory.totalCost + _ordersTotal;

    return Scaffold(
      backgroundColor: AppColors.bgCard,
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: AppColors.bgDark,
        title: Text(widget.room.name, style: AppTexts.smallHeading),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: _savePdf,
            icon: const Icon(Icons.save),
          ),
          IconButton(
            onPressed: _saveAndPrintPdf,
            icon: const Icon(Icons.print),
          ),
          const SizedBox(width: 20),
        ],
      ),
      body: Center(
        child: Container(
          width: 420,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // -------- HEADER --------
                Text(
                  'QUARTO RECEIPT',
                  style: AppTexts.meduimHeading.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  widget.room.name,
                  style: AppTexts.smallBody.copyWith(color: Colors.grey),
                ),

                const SizedBox(height: 16),
                _divider(),

                // -------- SESSION DETAILS --------
                _row(
                  title: 'Start Time',
                  value: widget.sessionHistory.startTimeShort,
                ),
                _row(
                  title: 'End Time',
                  value: widget.sessionHistory.endTimeShort,
                ),
                _row(
                  title: 'Duration',
                  value: widget.sessionHistory.formattedDuration,
                ),

                if (widget.sessionHistory.sessionTypeInfo.isNotEmpty)
                  _row(
                    title: 'Type',
                    value: widget.sessionHistory.sessionTypeInfo,
                  ),

                _divider(),

                // -------- DRINKS --------
                if (widget.orderItem.isNotEmpty) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Drinks',
                        style: AppTexts.meduimHeading.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),

                  ...widget.orderItem.map(
                    (order) => _row(
                      title: order.name,
                      value: '${order.price.toStringAsFixed(0)} \$',
                    ),
                  ),
                  _divider(),
                ],

                // -------- TOTALS --------
                _row(
                  title: 'Session Cost',
                  value: widget.sessionHistory.formattedCost,
                ),
                _row(
                  title: 'Drinks Total',
                  value: '${_ordersTotal.toStringAsFixed(0)} \$',
                ),

                _divider(),

                Row(
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
                      '${grandTotal.toStringAsFixed(0)} \$',
                      style: AppTexts.meduimHeading.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                Text(
                  'Thank you for playing',
                  style: AppTexts.smallBody.copyWith(color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // -------- HELPERS --------
  Widget _row({required String title, required String value}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Text(
            title,
            style: AppTexts.smallBody.copyWith(color: Colors.black),
          ),
          Spacer(),
          Text(
            value,
            style: AppTexts.smallBody.copyWith(
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
        ],
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
              color: index.isEven ? Colors.grey : Colors.transparent,
            ),
          ),
        ),
      ),
    );
  }
}

pw.Widget _pdfRow(String title, String value) {
  return pw.Padding(
    padding: const pw.EdgeInsets.symmetric(vertical: 4),
    child: pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(title),
        pw.Text(
          value,
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
        ),
      ],
    ),
  );
}
