import 'package:quarto/features/cafe/data/model/cafe_outcomes_model.dart';
import 'package:quarto/features/cafe/data/model/cafe_tabels_model.dart';
import 'package:quarto/features/cafe/data/model/order_item_model.dart';
import 'package:quarto/features/cafe/data/model/order_model.dart';

abstract class CafeRepository {
  Future<List<CafeTableModel>> getTables();
  Future<void> updateTableStatus(String tableId, bool isOccupied);
  Future<void> moveTableOrder({
    required String orderId,
    required String fromTableId,
    required String toTableId,
  });
  Future<void> updateOrderPaymentMethod({
    required String orderId,
    required String paymentMethod,
  });

  Future<String> addOrder(OrderModel order);
  Future<List<OrderModel>> getOrders();
  Future<List<OrderModel>> getOrdersByTable(String tableId);

  Future<void> addOrderItems(List<OrderItemModel> items);
  Future<List<OrderItemModel>> getOrderItems(String orderId);

  Future<void> addCafeOutcomesItems(CafeOutcomesModel items);
  Future<List<CafeOutcomesModel>> getCafeOutcomesItems();
}
