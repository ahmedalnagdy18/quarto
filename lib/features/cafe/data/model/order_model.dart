import 'package:equatable/equatable.dart';
import 'order_item_model.dart';

class OrderModel extends Equatable {
  final String id;
  final String orderType;
  final String? tableId;
  final String? customerName;
  final String? staffName;
  final String orderTime;
  final List<OrderItemModel> items;

  const OrderModel({
    required this.id,
    required this.orderType,
    this.tableId,
    this.customerName,
    this.staffName,
    required this.orderTime,
    required this.items,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      id: json['id']?.toString() ?? '',
      orderType: json['order_type']?.toString() ?? '',
      tableId: json['table_id']?.toString(),
      customerName: json['customer_name']?.toString(),
      staffName: json['staff_name']?.toString(),
      orderTime: json['order_time']?.toString() ?? '',
      items: (json['order_items'] as List? ?? [])
          .map((e) => OrderItemModel.fromJson(e))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order_type': orderType,
      'table_id': tableId,
      'customer_name': customerName,
      'staff_name': staffName,
      'order_time': orderTime,
      'order_items': items.map((e) => e.toJson()).toList(),
    };
  }

  @override
  List<Object?> get props => [
    id,
    orderType,
    tableId,
    customerName,
    staffName,
    orderTime,
    items,
  ];
}
