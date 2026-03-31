import 'package:flutter/material.dart';
import 'package:quarto/features/dashboard/data/model/room_model.dart';

Widget buildOrdersList(List<OrderItem> orders) {
  // Group orders by name
  final Map<String, int> groupedOrders = {};
  final Map<String, double> orderPrices = {};

  for (var order in orders) {
    groupedOrders[order.name] = (groupedOrders[order.name] ?? 0) + 1;
    orderPrices[order.name] = order.price; // Store price for each item
  }

  final uniqueOrders = groupedOrders.entries.toList();

  return ListView.separated(
    itemCount: uniqueOrders.length,
    separatorBuilder: (context, index) => SizedBox(height: 12),
    itemBuilder: (context, index) {
      final entry = uniqueOrders[index];
      final orderName = entry.key;
      final quantity = entry.value;
      final price = orderPrices[orderName] ?? 0;
      final totalPrice = price * quantity;

      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '$quantity × $orderName',
            style: TextStyle(
              color: Colors.white,
            ),
          ),
          Text(
            '${totalPrice.toStringAsFixed(0)} EGP',
            style: TextStyle(
              color: Colors.white,
            ),
          ),
        ],
      );
    },
  );
}
