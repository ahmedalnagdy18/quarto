import 'package:quarto/features/cafe/data/model/cafe_tabels_model.dart';
import 'package:quarto/features/cafe/data/model/order_item_model.dart';
import 'package:quarto/features/cafe/data/model/order_model.dart';
import 'package:quarto/features/cafe/domain/repository/cafe_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CafeRepositoryImp implements CafeRepository {
  final SupabaseClient supabase;

  CafeRepositoryImp({required this.supabase});

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

  @override
  Future<String> addOrder(OrderModel order) async {
    final orderTypeCandidates = _orderTypeCandidates(order.orderType);
    PostgrestException? lastConstraintError;

    for (final orderType in orderTypeCandidates) {
      try {
        final orderId = await _insertOrder(order, orderType);
        return orderId;
      } on PostgrestException catch (error) {
        if (!_isOrderTypeConstraintError(error) ||
            orderType != orderTypeCandidates.last) {
          if (!_isOrderTypeConstraintError(error)) {
            rethrow;
          }
          lastConstraintError = error;
          continue;
        }
        rethrow;
      }
    }

    if (lastConstraintError != null) {
      throw lastConstraintError;
    }

    throw StateError('Unable to add order.');
  }

  Future<String> _insertOrder(OrderModel order, String orderType) async {
    final response = await supabase
        .from('orders')
        .insert({
          'order_type': orderType,
          'table_id': order.tableId,
          'customer_name': order.customerName,
          'staff_name': order.staffName,
        })
        .select()
        .single();

    final orderId = response['id'].toString();

    if (order.items.isNotEmpty) {
      final items = order.items
          .map(
            (e) => {
              'order_id': orderId,
              'item_name': e.itemName,
              'quantity': e.quantity,
              'price': e.price,
            },
          )
          .toList();

      await supabase.from('order_items').insert(items);
    }

    return orderId;
  }

  List<String> _orderTypeCandidates(String orderType) {
    final normalized = orderType.trim().toLowerCase();

    if (normalized == 'takeaway' || normalized == 'take_away') {
      return const ['takeaway'];
    }

    return [normalized];
  }

  bool _isOrderTypeConstraintError(PostgrestException error) {
    return error.code == '23514' &&
        (error.message.contains('order_type_check') ||
            error.message.contains('orders'));
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

  @override
  Future<void> addOrderItems(List<OrderItemModel> items) async {
    final data = items
        .map(
          (e) => {
            'order_id': e.orderId,
            'item_name': e.itemName,
            'quantity': e.quantity,
            'price': e.price,
          },
        )
        .toList();

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
