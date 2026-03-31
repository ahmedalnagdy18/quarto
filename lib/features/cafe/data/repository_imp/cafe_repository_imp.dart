import 'package:quarto/features/cafe/data/model/cafe_tabels_model.dart';
import 'package:quarto/features/cafe/data/model/order_item_model.dart';
import 'package:quarto/features/cafe/data/model/order_model.dart';
import 'package:quarto/features/cafe/domain/repository/cafe_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CafeRepositoryImp implements CafeRepository {
  final SupabaseClient supabase;

  CafeRepositoryImp({required this.supabase});

  // =========================
  // 🪑 Tables
  // =========================

  @override
  Future<List<CafeTableModel>> getTables() async {
    final response = await supabase
        .from('cafe_tables')
        .select()
        .order('id', ascending: true);

    return (response as List).map((e) => CafeTableModel.fromJson(e)).toList();
  }

  @override
  Future<void> updateTableStatus(String tableId, bool isOccupied) async {
    await supabase
        .from('cafe_tables')
        .update({'is_occupied': isOccupied})
        .eq('id', tableId);
  }

  // =========================
  // 🧾 Orders
  // =========================

  @override
  Future<String> addOrder(OrderModel order) async {
    final response = await supabase
        .from('orders')
        .insert({
          'order_type': order.orderType,
          'table_id': order.tableId,
          'customer_name': order.customerName,
          'staff_name': order.staffName,
        })
        .select()
        .single();

    final orderId = response['id'].toString();

    // ➕ add items
    if (order.items.isNotEmpty) {
      final items = order.items.map((e) {
        return {
          'order_id': orderId,
          'item_name': e.itemName,
          'quantity': e.quantity,
          'price': e.price,
        };
      }).toList();

      await supabase.from('order_items').insert(items);
    }

    return orderId;
  }

  @override
  Future<List<OrderModel>> getOrders() async {
    final response = await supabase
        .from('orders')
        .select('*, order_items(*)')
        .order('order_time', ascending: false);

    return (response as List).map((e) => OrderModel.fromJson(e)).toList();
  }

  @override
  Future<List<OrderModel>> getOrdersByTable(String tableId) async {
    final response = await supabase
        .from('orders')
        .select('*, order_items(*)')
        .eq('table_id', tableId)
        .order('order_time', ascending: false);

    return (response as List).map((e) => OrderModel.fromJson(e)).toList();
  }

  // =========================
  // 🍔 Order Items
  // =========================

  @override
  Future<void> addOrderItems(List<OrderItemModel> items) async {
    final data = items.map((e) => e.toJson()).toList();

    await supabase.from('order_items').insert(data);
  }

  @override
  Future<List<OrderItemModel>> getOrderItems(String orderId) async {
    final response = await supabase
        .from('order_items')
        .select()
        .eq('order_id', orderId);

    return (response as List).map((e) => OrderItemModel.fromJson(e)).toList();
  }
}
