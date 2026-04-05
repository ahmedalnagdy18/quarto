import 'package:quarto/features/cafe/data/model/cafe_tabels_model.dart';
import 'package:quarto/features/cafe/data/model/order_model.dart';

DateTime _parseOrderTime(String value) {
  return DateTime.tryParse(value)?.toLocal() ??
      DateTime.fromMillisecondsSinceEpoch(0);
}

OrderModel? latestOrderForTable(String tableId, List<OrderModel> orders) {
  final tableOrders =
      orders
          .where(
            (order) => order.orderType == 'table' && order.tableId == tableId,
          )
          .toList()
        ..sort(
          (a, b) => _parseOrderTime(
            b.orderTime,
          ).compareTo(_parseOrderTime(a.orderTime)),
        );

  if (tableOrders.isEmpty) {
    return null;
  }

  return tableOrders.first;
}

Map<String, OrderModel> activeTableOrders(
  List<OrderModel> orders,
  List<CafeTableModel> tables,
) {
  final activeOrders = <String, OrderModel>{};

  for (final table in tables.where((table) => table.isOccupied)) {
    final latestOrder = latestOrderForTable(table.id, orders);
    if (latestOrder != null) {
      activeOrders[table.id] = latestOrder;
    }
  }

  return activeOrders;
}

List<OrderModel> finalizedCafeOrders(
  List<OrderModel> orders,
  List<CafeTableModel> tables,
) {
  final activeOrderIds = activeTableOrders(
    orders,
    tables,
  ).values.map((order) => order.id).toSet();

  return orders.where((order) => !activeOrderIds.contains(order.id)).toList()
    ..sort(
      (a, b) =>
          _parseOrderTime(b.orderTime).compareTo(_parseOrderTime(a.orderTime)),
    );
}

double calculateOrderTotal(OrderModel order) {
  return order.items.fold<double>(
    0,
    (total, item) => total + (item.price * item.quantity),
  );
}

bool isTodayOrder(OrderModel order) {
  final date = _parseOrderTime(order.orderTime);
  final now = DateTime.now();

  return date.year == now.year &&
      date.month == now.month &&
      date.day == now.day;
}

String formatOrderDate(String value) {
  final date = _parseOrderTime(value);
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  return '$day/$month/${date.year}';
}

String formatOrderTime(String value) {
  final date = _parseOrderTime(value);
  final hour = date.hour.toString().padLeft(2, '0');
  final minute = date.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}

String normalizePaymentMethod(String? value) {
  final normalized = value?.trim().toLowerCase() ?? '';
  if (normalized == 'visa') {
    return 'Visa';
  }
  if (normalized == 'cash') {
    return 'Cash';
  }
  return '--';
}
