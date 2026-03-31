import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quarto/core/colors/app_colors.dart';
import 'package:quarto/core/fonts/app_text.dart';
import 'package:quarto/features/cafe/data/model/order_item_model.dart';
import 'package:quarto/features/cafe/data/model/order_model.dart';
import 'package:quarto/features/cafe/presentation/cubits/orders_cubit/orders_cubit.dart';
import 'package:quarto/features/dashboard/presentation/widgets/button_widget.dart';

class CafeOrderDailogeWidget extends StatefulWidget {
  const CafeOrderDailogeWidget({
    super.key,
    required this.orderType,
    this.tableId,
  });
  final String orderType;
  final String? tableId;
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

  // Map to store selected items with their quantities
  final Map<String, int> _selectedItems = {};

  // Search functionality
  String _searchQuery = '';

  // Comment controller
  final TextEditingController _commentController = TextEditingController();

  // Loading state
  bool _isLoading = false;

  // Get filtered menu items based on search
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

  // Add item to selected items
  void _addItem(String name, double price) {
    setState(() {
      if (_selectedItems.containsKey(name)) {
        _selectedItems[name] = _selectedItems[name]! + 1;
      } else {
        _selectedItems[name] = 1;
      }
    });
  }

  // Remove item from selected items
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

  // Calculate total price
  double get _totalPrice {
    double total = 0;
    _selectedItems.forEach((name, quantity) {
      total += _menuItems[name]! * quantity;
    });
    return total;
  }

  // Prepare orders list for API
  List<OrderItemModel> _prepareOrders() {
    List<OrderItemModel> items = [];

    _selectedItems.forEach((name, quantity) {
      items.add(
        OrderItemModel(
          orderId: '',
          id: '',
          itemName: name,
          quantity: quantity,
          price: _menuItems[name]!, // ✅ دي أهم نقطة
        ),
      );
    });

    return items;
  }

  // Handle place order
  Future<void> _placeOrder() async {
    if (_selectedItems.isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final cubit = context.read<OrdersCubit>();

      final items = _prepareOrders();

      final order = OrderModel(
        id: '',
        orderType: widget.orderType, // غيرها حسب الاستخدام
        tableId: widget.orderType == "Table" ? widget.tableId : null,
        customerName: null,
        staffName:
            widget.orderType == "Staff" && _commentController.text.isNotEmpty
            ? _commentController.text
            : null,
        orderTime: DateTime.now().toIso8601String(),
        items: items,
      );

      await cubit.addOrder(order);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Order placed successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        print(order.toJson());
        Navigator.pop(context);
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
      insetPadding: const EdgeInsets.symmetric(
        horizontal: 40,
        vertical: 24,
      ),
      content: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: 15,
            sigmaY: 15,
          ),
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: 900,
              constraints: const BoxConstraints(
                maxHeight: 700,
                minHeight: 500,
              ),
              padding: const EdgeInsets.symmetric(
                vertical: 30,
                horizontal: 20,
              ),
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    blurRadius: 30,
                    spreadRadius: -5,
                    color: Colors.black.withOpacity(0.3),
                  ),
                ],
                color: Colors.white.withOpacity(0.05),
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                ),
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
                                Text(
                                  "Menu",
                                  style: AppTexts.smallHeading,
                                ),
                                const SizedBox(height: 20),
                                TextFormField(
                                  onChanged: (value) {
                                    setState(() {
                                      _searchQuery = value;
                                    });
                                  },
                                  decoration: InputDecoration(
                                    hintText: "Search items",
                                    hintStyle: const TextStyle(
                                      color: Colors.white,
                                    ),
                                    suffixIcon: const Icon(
                                      Icons.search_rounded,
                                      color: Colors.white,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(20),
                                      borderSide: BorderSide(
                                        color: Colors.white,
                                      ),
                                    ),
                                    filled: true,
                                    fillColor: Colors.transparent,
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                    ),
                                  ),
                                  style: const TextStyle(
                                    color: Colors.white,
                                  ),
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
                                                      "${item.value.toStringAsFixed(0)} EGP",
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
                        //! part 1
                        const SizedBox(
                          height: double.infinity,
                          child: VerticalDivider(
                            color: Colors.white,
                            thickness: 2,
                            width: 20,
                          ),
                        ),
                        //! part 2
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
                                      "${widget.orderType} Order",
                                      style: AppTexts.meduimHeading,
                                    ),
                                    GestureDetector(
                                      onTap: () => Navigator.pop(context),
                                      child: Icon(
                                        Icons.close,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  "Creat a new order for pick-up or walk-in",
                                  style: AppTexts.smallBody.copyWith(
                                    color: Colors.grey,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 30),
                                if (widget.orderType == 'Staff') ...[
                                  //
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      boxShadow: [
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
                                            Icon(
                                              Icons.comment,
                                              color: Colors.white,
                                            ),
                                            SizedBox(width: 8),
                                            Text(
                                              "Staff Name",
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
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 14,
                                          ),
                                          decoration: InputDecoration(
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
                                  SizedBox(height: 20),
                                ],

                                Text(
                                  "Order Summary",
                                  style: AppTexts.smallHeading,
                                ),
                                SizedBox(height: 12),
                                Expanded(
                                  child: _selectedItems.isEmpty
                                      ? Center(
                                          child: Text(
                                            "No items selected",
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
                                                          "${price.toStringAsFixed(0)} EGP × $quantity",
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
                                                        "${totalPrice.toStringAsFixed(0)} EGP",
                                                        style:
                                                            AppTexts.smallBody,
                                                      ),
                                                      SizedBox(width: 12),
                                                      GestureDetector(
                                                        onTap: () =>
                                                            _removeItem(
                                                              itemName,
                                                            ),
                                                        child: Icon(
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
                                      Text(
                                        "Total",
                                        style: AppTexts.meduimBody,
                                      ),
                                      Text(
                                        "${_totalPrice.toStringAsFixed(0)} EGP",
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
                  // زر الطلب
                  AddButton(
                    title: _isLoading ? 'Placing Order...' : 'Place Order',
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
