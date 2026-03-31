import 'package:equatable/equatable.dart';

class OrderItemModel extends Equatable {
  final String id;
  final String orderId;
  final String itemName;
  final int quantity;
  final double price;

  const OrderItemModel({
    required this.id,
    required this.orderId,
    required this.itemName,
    required this.quantity,
    required this.price,
  });

  factory OrderItemModel.fromJson(Map<String, dynamic> json) {
    return OrderItemModel(
      id: json['id']?.toString() ?? '',
      orderId: json['order_id']?.toString() ?? '',
      itemName: json['item_name']?.toString() ?? '',
      quantity: json['quantity'] ?? 1,
      price: (json['price'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order_id': orderId,
      'item_name': itemName,
      'quantity': quantity,
      'price': price,
    };
  }

  @override
  List<Object?> get props => [
    id,
    orderId,
    itemName,
    quantity,
    price,
  ];
}
