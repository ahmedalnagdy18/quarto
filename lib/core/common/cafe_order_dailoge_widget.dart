import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quarto/core/colors/app_colors.dart';
import 'package:quarto/core/fonts/app_text.dart';
import 'package:quarto/features/cafe/data/model/order_item_model.dart';
import 'package:quarto/features/cafe/data/model/order_model.dart';
import 'package:quarto/features/cafe/presentation/cubits/order_items_cubit/order_items_cubit.dart';
import 'package:quarto/features/cafe/presentation/cubits/orders_cubit/orders_cubit.dart';
import 'package:quarto/features/cafe/presentation/cubits/tabels_cubit/cafe_tables_cubit.dart';
import 'package:quarto/features/dashboard/presentation/widgets/button_widget.dart';

class CafeOrderDailogeWidget extends StatefulWidget {
  const CafeOrderDailogeWidget({
    super.key,
    required this.orderType,
    this.tableId,
    this.existingOrderId,
  });

  final String orderType;
  final String? tableId;
  final String? existingOrderId;

  @override
  State<CafeOrderDailogeWidget> createState() => _RoomOrderDailogeWidgetState();
}

class _RoomOrderDailogeWidgetState extends State<CafeOrderDailogeWidget> {
  final Map<String, double> _menuItems = {
    'Water': 10,
    'Coffee': 30,
    'Coffee d': 40,
    'Tea': 25,
    'Herbs': 25,
    'RedPull': 90,
    'V cola': 40,
    'Moussy': 40,
    'Msjito': 65,
    'Msjito f': 75,
    'Latte f': 110,
    'Classic latte': 110,
  };

  final Map<String, int> _selectedItems = {};
  String _searchQuery = '';
  final TextEditingController _commentController = TextEditingController();
  String _selectedPaymentMethod = 'Cash';
  bool _isLoading = false;

  bool get _isTableOrder => widget.orderType.toLowerCase() == 'table';

  bool get _isStaffOrder => widget.orderType.toLowerCase() == 'staff';

  bool get _isUpdatingExistingOrder =>
      widget.existingOrderId != null && widget.existingOrderId!.isNotEmpty;

  bool get _shouldChoosePaymentOnCreate =>
      !_isTableOrder && !_isUpdatingExistingOrder;

  String get _normalizedOrderType {
    switch (widget.orderType.toLowerCase()) {
      case 'table':
        return 'table';
      case 'staff':
        return 'staff';
      case 'takeaway':
        return 'takeaway';
      default:
        return widget.orderType.toLowerCase();
    }
  }

  List<MapEntry<String, double>> get _filteredMenuItems {
    if (_searchQuery.isEmpty) {
      return _menuItems.entries.toList();
    }

    return _menuItems.entries
        .where(
          (entry) =>
              entry.key.toLowerCase().contains(_searchQuery.toLowerCase()),
        )
        .toList();
  }

  void _addItem(String name, double price) {
    setState(() {
      _selectedItems.update(name, (value) => value + 1, ifAbsent: () => 1);
    });
  }

  void _removeItem(String name) {
    setState(() {
      if (_selectedItems.containsKey(name)) {
        if (_selectedItems[name]! > 1) {
          _selectedItems[name] = _selectedItems[name]! - 1;
        } else {
          _selectedItems.remove(name);
        }
      }
    });
  }

  double get _totalPrice {
    double total = 0;
    _selectedItems.forEach((name, quantity) {
      total += _menuItems[name]! * quantity;
    });
    return total;
  }

  List<OrderItemModel> _prepareOrders({String orderId = ''}) {
    final items = <OrderItemModel>[];

    _selectedItems.forEach((name, quantity) {
      items.add(
        OrderItemModel(
          orderId: orderId,
          id: '',
          itemName: name,
          quantity: quantity,
          price: _menuItems[name]!,
        ),
      );
    });

    return items;
  }

  Future<void> _placeOrder() async {
    if (_selectedItems.isEmpty) return;

    if (_isTableOrder && (widget.tableId == null || widget.tableId!.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Table id is missing for this order.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      if (_isUpdatingExistingOrder) {
        final items = _prepareOrders(orderId: widget.existingOrderId!);
        await context.read<OrderItemsCubit>().addOrderItems(items);
      } else {
        final order = OrderModel(
          id: '',
          orderType: _normalizedOrderType,
          tableId: _isTableOrder ? widget.tableId : null,
          customerName: null,
          staffName: _isStaffOrder && _commentController.text.trim().isNotEmpty
              ? _commentController.text.trim()
              : null,
          orderTime: DateTime.now().toIso8601String(),
          paymentMethod: _shouldChoosePaymentOnCreate
              ? _selectedPaymentMethod.toLowerCase()
              : '',
          items: _prepareOrders(),
        );

        await context.read<OrdersCubit>().addOrder(order);

        if (_isTableOrder && mounted) {
          await context.read<CafeTablesCubit>().updateTableStatus(
            widget.tableId!,
            true,
          );
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isUpdatingExistingOrder
                  ? 'Order updated successfully!'
                  : 'Order placed successfully!',
            ),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to place order: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      alignment: Alignment.center,
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
      content: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: 900,
              constraints: const BoxConstraints(maxHeight: 700, minHeight: 500),
              padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    blurRadius: 30,
                    spreadRadius: -5,
                    color: Colors.black.withOpacity(0.3),
                  ),
                ],
                color: Colors.white.withOpacity(0.05),
                border: Border.all(color: Colors.white.withOpacity(0.2)),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 1,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 25),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Menu', style: AppTexts.smallHeading),
                                const SizedBox(height: 20),
                                TextFormField(
                                  onChanged: (value) {
                                    setState(() {
                                      _searchQuery = value;
                                    });
                                  },
                                  decoration: InputDecoration(
                                    hintText: 'Search items',
                                    hintStyle: const TextStyle(
                                      color: Colors.white,
                                    ),
                                    suffixIcon: const Icon(
                                      Icons.search_rounded,
                                      color: Colors.white,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(20),
                                      borderSide: const BorderSide(
                                        color: Colors.white,
                                      ),
                                    ),
                                    filled: true,
                                    fillColor: Colors.transparent,
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                    ),
                                  ),
                                  style: const TextStyle(color: Colors.white),
                                ),
                                const SizedBox(height: 20),
                                Expanded(
                                  child: ListView.separated(
                                    scrollDirection: Axis.vertical,
                                    separatorBuilder: (context, index) =>
                                        const SizedBox(height: 8),
                                    itemCount: _filteredMenuItems.length,
                                    itemBuilder: (context, index) {
                                      final item = _filteredMenuItems[index];
                                      return GestureDetector(
                                        onTap: () =>
                                            _addItem(item.key, item.value),
                                        child: Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            boxShadow: [
                                              BoxShadow(
                                                blurRadius: 30,
                                                spreadRadius: -5,
                                                color: Colors.black.withOpacity(
                                                  0.3,
                                                ),
                                              ),
                                            ],
                                            color: Colors.white.withOpacity(
                                              0.05,
                                            ),
                                            border: Border.all(
                                              color: Colors.white.withOpacity(
                                                0.2,
                                              ),
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      item.key,
                                                      style:
                                                          AppTexts.meduimBody,
                                                    ),
                                                    const SizedBox(height: 8),
                                                    Text(
                                                      '${item.value.toStringAsFixed(0)} EGP',
                                                      style: AppTexts.meduimBody
                                                          .copyWith(
                                                            color: AppColors
                                                                .yellowColor,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                          ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              Icon(
                                                Icons.add_circle_outline,
                                                color: AppColors.yellowColor,
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(
                          height: double.infinity,
                          child: VerticalDivider(
                            color: Colors.white,
                            thickness: 2,
                            width: 20,
                          ),
                        ),
                        Expanded(
                          flex: 1,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 25),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Text(
                                      '${widget.orderType} Order',
                                      style: AppTexts.meduimHeading,
                                    ),
                                    GestureDetector(
                                      onTap: () => Navigator.pop(context),
                                      child: const Icon(
                                        Icons.close,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  _isUpdatingExistingOrder
                                      ? 'Add more items to the current order'
                                      : 'Creat a new order for pick-up or walk-in',
                                  style: AppTexts.smallBody.copyWith(
                                    color: Colors.grey,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 30),
                                if (_isStaffOrder &&
                                    !_isUpdatingExistingOrder) ...[
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      boxShadow: const [
                                        BoxShadow(
                                          blurRadius: 1,
                                          color: Colors.white10,
                                          spreadRadius: 0,
                                          offset: Offset(0, 0),
                                        ),
                                      ],
                                      borderRadius: BorderRadius.circular(12),
                                      color: Colors.transparent,
                                      border: Border.all(color: Colors.white10),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            const Icon(
                                              Icons.comment,
                                              color: Colors.white,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              'Staff Name',
                                              style: AppTexts.smallHeading
                                                  .copyWith(
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 16),
                                        TextField(
                                          controller: _commentController,
                                          maxLines: 3,
                                          minLines: 2,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 14,
                                          ),
                                          decoration: const InputDecoration(
                                            hintText: 'Add your Name',
                                            hintStyle: TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
                                            ),
                                            border: OutlineInputBorder(),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                ],
                                if (_shouldChoosePaymentOnCreate) ...[
                                  Text(
                                    'Payment method',
                                    style: AppTexts.smallHeading,
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      _PaymentOptionChip(
                                        label: 'Cash',
                                        selected:
                                            _selectedPaymentMethod == 'Cash',
                                        onTap: () {
                                          setState(() {
                                            _selectedPaymentMethod = 'Cash';
                                          });
                                        },
                                      ),
                                      const SizedBox(width: 12),
                                      _PaymentOptionChip(
                                        label: 'Visa',
                                        selected:
                                            _selectedPaymentMethod == 'Visa',
                                        onTap: () {
                                          setState(() {
                                            _selectedPaymentMethod = 'Visa';
                                          });
                                        },
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 20),
                                ],
                                Text(
                                  'Order Summary',
                                  style: AppTexts.smallHeading,
                                ),
                                const SizedBox(height: 12),
                                Expanded(
                                  child: _selectedItems.isEmpty
                                      ? Center(
                                          child: Text(
                                            'No items selected',
                                            style: AppTexts.smallBody.copyWith(
                                              color: Colors.grey,
                                            ),
                                          ),
                                        )
                                      : ListView.builder(
                                          itemCount: _selectedItems.length,
                                          itemBuilder: (context, index) {
                                            final entry = _selectedItems.entries
                                                .toList()[index];
                                            final itemName = entry.key;
                                            final quantity = entry.value;
                                            final price = _menuItems[itemName]!;
                                            final totalPrice = price * quantity;

                                            return Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    vertical: 8,
                                                  ),
                                              child: Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Text(
                                                          itemName,
                                                          style: AppTexts
                                                              .smallBody,
                                                        ),
                                                        Text(
                                                          '${price.toStringAsFixed(0)} EGP x $quantity',
                                                          style: AppTexts
                                                              .smallBody
                                                              .copyWith(
                                                                fontSize: 12,
                                                                color:
                                                                    Colors.grey,
                                                              ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  Row(
                                                    children: [
                                                      Text(
                                                        '${totalPrice.toStringAsFixed(0)} EGP',
                                                        style:
                                                            AppTexts.smallBody,
                                                      ),
                                                      const SizedBox(width: 12),
                                                      GestureDetector(
                                                        onTap: () =>
                                                            _removeItem(
                                                              itemName,
                                                            ),
                                                        child: const Icon(
                                                          Icons
                                                              .remove_circle_outline,
                                                          color: Colors.red,
                                                          size: 20,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            );
                                          },
                                        ),
                                ),
                                if (_selectedItems.isNotEmpty) ...[
                                  const Divider(),
                                  const SizedBox(height: 12),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text('Total', style: AppTexts.meduimBody),
                                      Text(
                                        '${_totalPrice.toStringAsFixed(0)} EGP',
                                        style: AppTexts.meduimBody,
                                      ),
                                    ],
                                  ),
                                ],
                                const SizedBox(height: 12),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  AddButton(
                    title: _isLoading
                        ? (_isUpdatingExistingOrder
                              ? 'Updating Order...'
                              : 'Placing Order...')
                        : 'Place Order',
                    onPressed: _selectedItems.isEmpty || _isLoading
                        ? null
                        : _placeOrder,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PaymentOptionChip extends StatelessWidget {
  const _PaymentOptionChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.yellowColor : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? AppColors.yellowColor : Colors.white30,
            width: 1.4,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? AppColors.blueColor : Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
