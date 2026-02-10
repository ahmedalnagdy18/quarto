import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quarto/core/colors/app_colors.dart';
import 'package:quarto/core/fonts/app_text.dart';
import 'package:quarto/features/dashboard/presentation/cubits/external_order/external_orders_cubit.dart';
import 'package:quarto/features/dashboard/presentation/screens/external_order_page.dart';
import 'package:quarto/injection_container.dart';

class OrderItem {
  final String name;
  final double price;
  int quantity;

  OrderItem({
    required this.name,
    required this.price,
    this.quantity = 1,
  });

  double get totalPrice => price * quantity;
}

class ExternalOrderDialogWidget extends StatelessWidget {
  const ExternalOrderDialogWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ExternalOrdersCubit(
        addExternalOrderUsecase: sl(),
        getExternalOrdersUsecase: sl(),
        deleteExternalOrder: sl(),
      ),
      child: _ExternalOrderDialogWidget(),
    );
  }
}

class _ExternalOrderDialogWidget extends StatefulWidget {
  const _ExternalOrderDialogWidget();

  @override
  State<_ExternalOrderDialogWidget> createState() =>
      _ExternalOrderDialogWidgetState();
}

class _ExternalOrderDialogWidgetState
    extends State<_ExternalOrderDialogWidget> {
  final TextEditingController _priceController = TextEditingController();
  final List<OrderItem> _orders = [];

  String selectedDrink = 'Water';
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

  double get totalPrice {
    return _orders.fold(0, (sum, item) => sum + item.totalPrice);
  }

  @override
  void initState() {
    super.initState();
    _updatePriceForSelectedDrink();
  }

  void _updatePriceForSelectedDrink() {
    if (_menuItems.containsKey(selectedDrink)) {
      final price = _menuItems[selectedDrink]!;
      _priceController.text = price == 0 ? '' : price.toStringAsFixed(2);
    }
  }

  void _addOrderItem() {
    final priceText = _priceController.text.trim();
    if (priceText.isEmpty) return;

    final price = double.tryParse(priceText);
    if (price == null || price <= 0) return;

    // Check if item already exists
    final existingIndex = _orders.indexWhere(
      (item) => item.name == selectedDrink && item.price == price,
    );

    if (existingIndex != -1) {
      // Increase quantity of existing item
      setState(() {
        _orders[existingIndex].quantity++;
      });
    } else {
      // Add new item
      setState(() {
        _orders.add(
          OrderItem(
            name: selectedDrink,
            price: price,
            quantity: 1,
          ),
        );
      });
    }

    // Reset for next item
    _priceController.text = '';
  }

  void _removeOrderItem(int index) {
    setState(() {
      _orders.removeAt(index);
    });
  }

  void _updateQuantity(int index, bool increase) {
    setState(() {
      if (increase) {
        _orders[index].quantity++;
      } else {
        if (_orders[index].quantity > 1) {
          _orders[index].quantity--;
        } else {
          _orders.removeAt(index);
        }
      }
    });
  }

  @override
  void dispose() {
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ExternalOrdersCubit, ExternalOrdersState>(
      listener: (context, state) {
        if (state is ErrorAddExternalOrders) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Error adding outcome"),
              backgroundColor: Colors.red,
            ),
          );
          print(state.message);
        }
        if (state is SuccessAddExternalOrders) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Successfully added outcome"),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop(); // Close the dialog
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => ExternalOrderPage(),
            ),
          );
        }
      },
      builder: (context, state) {
        return AlertDialog(
          backgroundColor: AppColors.bgDark,
          title: Text(
            'Add Order',
            style: AppTexts.meduimHeading,
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Existing form
                  DropdownButtonFormField<String>(
                    value: selectedDrink,
                    dropdownColor: AppColors.bgDark,
                    style: AppTexts.smallBody.copyWith(color: Colors.white),
                    items: _menuItems.keys.map((item) {
                      return DropdownMenuItem(
                        value: item,
                        child: Text(
                          item,
                          style: AppTexts.smallBody.copyWith(
                            color: Colors.white,
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedDrink = value!;
                        _updatePriceForSelectedDrink();
                      });
                    },
                    decoration: InputDecoration(
                      labelText: 'Item',
                      labelStyle: AppTexts.smallHeading,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                        RegExp(r'^\d*\.?\d{0,2}'),
                      ),
                    ],
                    controller: _priceController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    style: AppTexts.smallBody.copyWith(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Price',
                      labelStyle: AppTexts.smallHeading,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      prefixText: '\$ ',
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Add button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _addOrderItem,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.add_circle_outline, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Add to Order',
                            style: AppTexts.smallBody.copyWith(
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Added items list
                  if (_orders.isNotEmpty) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.bgDark.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Order Items',
                            style: AppTexts.smallHeading.copyWith(fontSize: 16),
                          ),
                          const SizedBox(height: 12),

                          // Items list
                          Container(
                            constraints: const BoxConstraints(maxHeight: 200),
                            child: ListView.builder(
                              shrinkWrap: true,
                              itemCount: _orders.length,
                              itemBuilder: (context, index) {
                                final item = _orders[index];
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[900],
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                    ),
                                    leading: CircleAvatar(
                                      backgroundColor: AppColors.primaryBlue,
                                      child: Text(
                                        '${item.quantity}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                    title: Text(
                                      item.name,
                                      style: AppTexts.smallBody,
                                    ),
                                    subtitle: Text(
                                      '\$${item.price.toStringAsFixed(2)} each',
                                      style: AppTexts.smallBody.copyWith(
                                        fontSize: 12,
                                        color: Colors.grey[400],
                                      ),
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(
                                            Icons.remove,
                                            size: 18,
                                            color: Colors.white,
                                          ),
                                          onPressed: () =>
                                              _updateQuantity(index, false),
                                        ),
                                        IconButton(
                                          icon: const Icon(
                                            Icons.add,
                                            size: 18,
                                            color: Colors.white,
                                          ),
                                          onPressed: () =>
                                              _updateQuantity(index, true),
                                        ),
                                        IconButton(
                                          icon: const Icon(
                                            Icons.delete,
                                            size: 18,
                                            color: Colors.red,
                                          ),
                                          onPressed: () =>
                                              _removeOrderItem(index),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Total price
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.green[900]!.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: Colors.green[700]!),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Total:',
                                  style: AppTexts.meduimHeading.copyWith(
                                    fontSize: 16,
                                  ),
                                ),
                                Text(
                                  '\$${totalPrice.toStringAsFixed(2)}',
                                  style: AppTexts.meduimHeading.copyWith(
                                    fontSize: 18,
                                    color: Colors.green[400],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: AppTexts.meduimBody,
              ),
            ),
            ElevatedButton(
              style: ButtonStyle(
                backgroundColor: WidgetStatePropertyAll(AppColors.primaryBlue),
              ),
              onPressed: _orders.isEmpty
                  ? null
                  : () {
                      // تغيير طريقة تخزين الطلب
                      String orderString = '';
                      for (var item in _orders) {
                        // تخزين كل عنصر بالصيغة: "اسم المنتج xالكمية"
                        orderString += '${item.name} x${item.quantity}\n';
                      }

                      context.read<ExternalOrdersCubit>().addExternalOrderFunc(
                        price: totalPrice.toInt(),
                        order: orderString.trim(), // إزالة السطر الأخير الفارغ
                      );
                    },
              child: Text(
                'Save Order',
                style: AppTexts.meduimBody,
              ),
            ),
          ],
        );
      },
    );
  }
}
