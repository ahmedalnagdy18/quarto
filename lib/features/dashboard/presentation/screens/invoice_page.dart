import 'package:flutter/material.dart';
import 'package:quarto/core/colors/app_colors.dart';
import 'package:quarto/core/fonts/app_text.dart';
import 'package:quarto/features/dashboard/data/model/room_model.dart';
import 'package:quarto/features/dashboard/data/model/session_history_model.dart';
import 'package:quarto/features/dashboard/presentation/screens/history_details_page.dart';

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
  double get _ordersTotal {
    return widget.orderItem.fold(0, (sum, item) => sum + item.price);
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
            onPressed: () {
              // TODO: print receipt
            },
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
                  'Thank you for playing 🎮',
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
