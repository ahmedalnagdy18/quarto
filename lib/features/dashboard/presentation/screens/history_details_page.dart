import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:quarto/core/colors/app_colors.dart';
import 'package:quarto/core/fonts/app_text.dart';
import 'package:quarto/features/dashboard/data/model/room_model.dart';
import 'package:quarto/features/dashboard/data/model/session_history_model.dart';
import 'package:quarto/features/dashboard/presentation/screens/invoice_page.dart';

/// -------- LOCAL ORDER MODEL (NO IMPACT ON YOUR MODELS) --------
class OrderItem {
  final String name;
  final double price;

  OrderItem({required this.name, required this.price});
}

class HistoryDetailsPage extends StatefulWidget {
  const HistoryDetailsPage({
    super.key,
    required this.sessionHistory,
    required this.room,
  });

  final SessionHistory sessionHistory;
  final Room room;

  @override
  State<HistoryDetailsPage> createState() => _HistoryDetailsPageState();
}

class _HistoryDetailsPageState extends State<HistoryDetailsPage> {
  void _addOrderDialog() {
    String selectedDrink = 'Water';
    final priceController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.bgDark,
          title: Text(
            'Add Drink',
            style: AppTexts.meduimHeading,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: selectedDrink,
                dropdownColor: AppColors.bgDark,
                style: AppTexts.smallBody,
                items: [
                  DropdownMenuItem(
                    value: 'Water',
                    child: Text('Water'),
                  ),
                  DropdownMenuItem(
                    value: 'Coffee',
                    child: Text('Coffee'),
                  ),
                  DropdownMenuItem(
                    value: 'Tea',
                    child: Text('Tea'),
                  ),
                ],
                onChanged: (value) {
                  selectedDrink = value!;
                },
                decoration: InputDecoration(
                  labelText: 'Drink',
                  labelStyle: AppTexts.smallHeading,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
                controller: priceController,
                keyboardType: TextInputType.number,
                style: AppTexts.smallBody,
                decoration: InputDecoration(
                  labelText: 'Price',
                  labelStyle: AppTexts.smallHeading,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final price = double.tryParse(priceController.text);
                if (price != null) {
                  setState(() {
                    _orders.add(
                      OrderItem(name: selectedDrink, price: price),
                    );
                  });
                  Navigator.pop(context);
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  final List<OrderItem> _orders = [];

  double get _ordersTotal => _orders.fold(0, (sum, item) => sum + item.price);

  @override
  Widget build(BuildContext context) {
    final grandTotal = widget.sessionHistory.totalCost + _ordersTotal;

    return Scaffold(
      backgroundColor: AppColors.bgCard,
      appBar: AppBar(
        backgroundColor: AppColors.bgDark,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(widget.room.name, style: AppTexts.smallHeading),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.receipt_long),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (_) => InvoicePage(
                        sessionHistory: widget.sessionHistory,
                        room: widget.room,
                        orderItem: _orders,
                      ),
                ),
              );
            },
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: SizedBox(
            width: 520,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _section(
                  title: 'SESSION INFO',
                  child: Column(
                    children: [
                      _row('Start', widget.sessionHistory.startTimeShort),
                      _row('End', widget.sessionHistory.endTimeShort),
                      _row(
                        'Duration',
                        widget.sessionHistory.formattedDuration,
                      ),
                      if (widget.sessionHistory.sessionTypeInfo.isNotEmpty)
                        _row(
                          'Type',
                          widget.sessionHistory.sessionTypeInfo,
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                _section(
                  title: 'DRINKS',
                  trailing: IconButton(
                    icon: const Icon(Icons.add, color: Colors.white),
                    onPressed: _addOrderDialog,
                  ),
                  child:
                      _orders.isEmpty
                          ? Padding(
                            padding: const EdgeInsets.all(12),
                            child: Text(
                              'No drinks added',
                              style: AppTexts.smallBody.copyWith(
                                color: Colors.grey,
                              ),
                            ),
                          )
                          : Column(
                            children:
                                _orders.map((order) {
                                  return _row(
                                    order.name,
                                    '${order.price.toStringAsFixed(0)} \$',
                                    trailing: InkWell(
                                      onTap: () {
                                        setState(() {
                                          _orders.remove(order);
                                        });
                                      },
                                      child: const Icon(
                                        Icons.close,
                                        size: 16,
                                        color: Colors.redAccent,
                                      ),
                                    ),
                                  );
                                }).toList(),
                          ),
                ),

                const SizedBox(height: 16),

                _section(
                  title: 'SUMMARY',
                  child: Column(
                    children: [
                      _row(
                        'Session Cost',
                        widget.sessionHistory.formattedCost,
                      ),
                      _row(
                        'Drinks',
                        '${_ordersTotal.toStringAsFixed(0)} \$',
                      ),
                      const Divider(color: Colors.grey),
                      _row(
                        'TOTAL',
                        '${grandTotal.toStringAsFixed(0)} \$',
                        isTotal: true,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ---------- UI HELPERS ----------

  Widget _section({
    required String title,
    required Widget child,
    Widget? trailing,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgDark,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                title,
                style: AppTexts.smallHeading.copyWith(letterSpacing: 1),
              ),
              const Spacer(),
              if (trailing != null) trailing,
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _row(
    String title,
    String value, {
    Widget? trailing,
    bool isTotal = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Text(
            title,
            style: AppTexts.smallBody.copyWith(
              color: isTotal ? Colors.white : Colors.grey,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: AppTexts.smallBody.copyWith(
              fontWeight: FontWeight.w600,
              color: isTotal ? Colors.white : Colors.white70,
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 8),
            trailing,
          ],
        ],
      ),
    );
  }
}
