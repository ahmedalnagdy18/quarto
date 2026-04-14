import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quarto/core/colors/app_colors.dart';
import 'package:quarto/core/fonts/app_text.dart';
import 'package:quarto/features/dashboard/data/model/room_model.dart';
import 'package:quarto/features/dashboard/data/model/session_history_model.dart';
import 'package:quarto/features/dashboard/presentation/cubits/rooms/rooms_cubit.dart';
import 'package:quarto/features/dashboard/presentation/cubits/session_history/session_history_cubit.dart';
import 'package:quarto/features/dashboard/presentation/screens/invoice_page.dart';

/// -------- LOCAL ORDER MODEL (NO IMPACT ON YOUR MODELS) --------
class OrderItemData {
  final String name;
  final double price;

  OrderItemData({required this.name, required this.price});
}

class HistoryDetailsPage extends StatefulWidget {
  const HistoryDetailsPage({
    super.key,
    required this.sessionHistory,
    required this.room,
    required this.sessionId,
  });

  final SessionHistory sessionHistory;
  final Room room;
  final String sessionId;

  @override
  State<HistoryDetailsPage> createState() => _HistoryDetailsPageState();
}

class _HistoryDetailsPageState extends State<HistoryDetailsPage> {
  bool get isMobile =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.android) &&
      MediaQuery.of(context).size.shortestSide < 600;

  final List<OrderItemData> _orders = [];
  List<OrderItemData> _existingOrders = [];

  // ⭐ متغير لتحديث الكومنت محلياً
  String? _currentComment;

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
                  DropdownMenuItem(value: 'Water', child: Text('Water')),
                  DropdownMenuItem(value: 'Coffee', child: Text('Coffee')),
                  DropdownMenuItem(value: 'Coffee d', child: Text('Coffee d')),
                  DropdownMenuItem(value: 'Tea', child: Text('Tea')),
                  DropdownMenuItem(value: 'Herbs', child: Text('Herbs')),
                  DropdownMenuItem(value: 'RedPull', child: Text('RedPull')),
                  DropdownMenuItem(value: 'V cola', child: Text('V cola')),
                  DropdownMenuItem(value: 'Moussy', child: Text('Moussy')),
                  DropdownMenuItem(value: 'Msjito', child: Text('Msjito')),
                  DropdownMenuItem(value: 'Msjito f', child: Text('Msjito f')),
                  DropdownMenuItem(value: 'Latte f', child: Text('Latte f')),
                  DropdownMenuItem(
                    value: 'Classic latte',
                    child: Text('Classic latte'),
                  ),
                ],
                onChanged: (value) => selectedDrink = value!,
                decoration: InputDecoration(
                  labelText: 'Drink',
                  labelStyle: AppTexts.smallHeading,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
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
                      OrderItemData(name: selectedDrink, price: price),
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

  void _showCommentDialog(BuildContext context) {
    final commentController = TextEditingController(
      text: _currentComment == "null" ? "" : _currentComment,
    );

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Comment'),
          content: TextField(
            controller: commentController,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'Enter your comment...',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (commentController.text.isNotEmpty) {
                  await context.read<SessionHistoryCubit>().addCommentFunc(
                    comments: commentController.text,
                    roomId: widget.room.id,
                    sessionId: widget.sessionId,
                  );

                  // ⭐ تحديث محلي بدون انتظار تحميل البيانات
                  setState(() {
                    _currentComment = commentController.text;
                  });

                  if (mounted) Navigator.pop(context);
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    _loadExistingOrders();
    // ⭐ تحميل الكومنت الحالي
    // _currentComment = widget.sessionHistory.comments;
  }

  void _loadExistingOrders() {
    _existingOrders = widget.sessionHistory.ordersList
        .map(
          (orderItem) => OrderItemData(
            name: orderItem.name,
            price: orderItem.price,
          ),
        )
        .toList();
  }

  double _calculateSessionCost() {
    final sessionCost =
        widget.sessionHistory.totalCost - widget.sessionHistory.ordersTotal;
    return sessionCost < 0 ? 0.0 : sessionCost;
  }

  double get _newOrdersTotal {
    return _orders.fold<double>(0.0, (sum, item) => sum + item.price);
  }

  double get _existingOrdersTotal {
    return _existingOrders.fold<double>(0.0, (sum, item) => sum + item.price);
  }

  @override
  Widget build(BuildContext context) {
    final sessionCost = _calculateSessionCost();

    return BlocListener<SessionHistoryCubit, SessionHistoryState>(
      listener: (context, state) {
        if (state is SuccessAddComment) {
          // ⭐ تحديث من الـ Cubit كـ backup
          setState(() {
            _currentComment = state.comment;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Comment added successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.bgCard,
        appBar: AppBar(
          backgroundColor: AppColors.bgDark,
          iconTheme: const IconThemeData(color: Colors.white),
          title: Text(widget.room.name, style: AppTexts.smallHeading),
          centerTitle: true,
          actions: [
            if (!isMobile)
              Padding(
                padding: const EdgeInsets.only(right: 20),
                child: IconButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => InvoicePage(
                          sessionHistory: widget.sessionHistory,
                          room: widget.room,
                          orderItem: _existingOrders,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.receipt),
                ),
              ),
          ],
        ),
        body: BlocConsumer<RoomsCubit, RoomsState>(
          listener: (context, state) {
            if (state is RoomOrdersAdded) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Orders added successfully'),
                  backgroundColor: Colors.green,
                  duration: Duration(seconds: 2),
                ),
              );
              Navigator.pop(context);
            }
          },
          builder: (context, state) {
            return SingleChildScrollView(
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
                            _row(
                              'Payment',
                              _displayHistoryPaymentMethod(
                                widget.sessionHistory.paymentMethod,
                              ),
                            ),
                            if (widget
                                .sessionHistory
                                .sessionTypeInfo
                                .isNotEmpty)
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
                        trailing: isMobile
                            ? null
                            : IconButton(
                                icon: const Icon(
                                  Icons.add,
                                  color: Colors.white,
                                ),
                                onPressed: _addOrderDialog,
                              ),
                        child: _existingOrders.isEmpty && _orders.isEmpty
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
                                children: [
                                  ..._existingOrders.map((order) {
                                    return _row(
                                      order.name,
                                      '${order.price.toStringAsFixed(0)} \$',
                                      trailing: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: Colors.green.withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                        child: Text(
                                          'Saved',
                                          style: AppTexts.smallBody.copyWith(
                                            fontSize: 10,
                                            color: Colors.green,
                                          ),
                                        ),
                                      ),
                                    );
                                  }),
                                  ..._orders.map((order) {
                                    return _row(
                                      order.name,
                                      '${order.price.toStringAsFixed(0)} \$',
                                      trailing: InkWell(
                                        onTap: () {
                                          setState(() => _orders.remove(order));
                                        },
                                        child: const Icon(
                                          Icons.close,
                                          size: 16,
                                          color: Colors.redAccent,
                                        ),
                                      ),
                                    );
                                  }),
                                ],
                              ),
                      ),

                      const SizedBox(height: 16),

                      // ⭐ قسم التعليقات - تحديث مباشر
                      _section(
                        title: "COMMENTS",
                        child: Column(
                          children: [
                            if (_currentComment != null &&
                                _currentComment!.isNotEmpty &&
                                _currentComment != 'null')
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.bgCardLight,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: AppColors.primaryBlue.withOpacity(
                                      0.3,
                                    ),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.comment,
                                          size: 16,
                                          color: AppColors.primaryBlue,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Comment:',
                                          style: AppTexts.smallBody.copyWith(
                                            color: AppColors.primaryBlue,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      _currentComment!,
                                      style: AppTexts.smallBody.copyWith(
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            else
                              Container(),

                            const SizedBox(height: 8),

                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        _currentComment != null &&
                                            _currentComment!.isNotEmpty &&
                                            _currentComment != 'null'
                                        ? Colors.orange
                                        : AppColors.primaryBlue,
                                  ),
                                  onPressed: () => _showCommentDialog(context),
                                  icon: Icon(
                                    _currentComment != null &&
                                            _currentComment!.isNotEmpty &&
                                            _currentComment != 'null'
                                        ? Icons.edit
                                        : Icons.add_comment,
                                    color: Colors.white,
                                  ),
                                  label: Text(
                                    _currentComment != null &&
                                            _currentComment!.isNotEmpty &&
                                            _currentComment != 'null'
                                        ? 'Edit Comment'
                                        : 'Add Comment',
                                    style: AppTexts.smallBody.copyWith(
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      _section(
                        title: 'SUMMARY',
                        child: Column(
                          children: [
                            _row(
                              'Session Time Cost',
                              '${sessionCost.toStringAsFixed(0)} \$',
                            ),
                            _row(
                              'Drinks',
                              '${_existingOrdersTotal.toStringAsFixed(0)} \$',
                            ),
                            if (_orders.isNotEmpty)
                              _row(
                                'New Drinks',
                                '+ ${_newOrdersTotal.toStringAsFixed(0)} \$',
                              ),
                            const Divider(color: Colors.grey),
                            _row(
                              'TOTAL',
                              '${(widget.sessionHistory.totalCost + _newOrdersTotal).toStringAsFixed(0)} \$',
                              isTotal: true,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      if (!isMobile && _orders.isNotEmpty)
                        ElevatedButton(
                          style: ButtonStyle(
                            backgroundColor: MaterialStatePropertyAll(
                              AppColors.primaryBlue,
                            ),
                            foregroundColor: MaterialStatePropertyAll(
                              Colors.white,
                            ),
                          ),
                          onPressed: () {
                            final ordersToSend = _orders
                                .map(
                                  (o) =>
                                      OrderItem(name: o.name, price: o.price),
                                )
                                .toList();

                            context.read<RoomsCubit>().addOrders(
                              widget.room.id,
                              ordersToSend,
                              sessionId: widget.sessionId,
                            );
                          },
                          child: const Text('Add'),
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
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

String _displayHistoryPaymentMethod(String? value) {
  switch ((value ?? '').trim().toLowerCase()) {
    case 'visa':
      return 'Visa';
    case 'cash':
      return 'Cash';
    default:
      return '--';
  }
}
