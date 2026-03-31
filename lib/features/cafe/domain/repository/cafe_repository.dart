import 'package:quarto/features/cafe/data/model/cafe_tabels_model.dart';
import 'package:quarto/features/cafe/data/model/order_item_model.dart';
import 'package:quarto/features/cafe/data/model/order_model.dart';

abstract class CafeRepository {
  // 🪑 Tables
  Future<List<CafeTableModel>> getTables();
  Future<void> updateTableStatus(String tableId, bool isOccupied);

  // 🧾 Orders
  Future<String> addOrder(OrderModel order);
  Future<List<OrderModel>> getOrders();
  Future<List<OrderModel>> getOrdersByTable(String tableId);

  // 🍔 Order Items
  Future<void> addOrderItems(List<OrderItemModel> items);
  Future<List<OrderItemModel>> getOrderItems(String orderId);
}
