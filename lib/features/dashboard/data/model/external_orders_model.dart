import 'package:equatable/equatable.dart';

class ExternalOrdersModel extends Equatable {
  final String id;
  final String table;
  final List<ExternalOrderItem> order;
  final bool payment;

  const ExternalOrdersModel({
    required this.id,
    required this.table,
    required this.order,
    required this.payment,
  });

  factory ExternalOrdersModel.fromJson(Map<String, dynamic> json) {
    return ExternalOrdersModel(
      id: json['id']?.toString() ?? '',
      table: json['table']?.toString() ?? '',
      order: (json['order'] as List? ?? [])
          .map((e) => ExternalOrderItem.fromJson(e))
          .toList(),
      payment: json['payment'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order': order.map((e) => e.toJson()).toList(),
      'payment': payment,
    };
  }

  @override
  List<Object?> get props => [
    id,
    table,
    order,
    payment,
  ];
}

class ExternalOrderItem {
  final String name;
  final double price;

  ExternalOrderItem({required this.name, required this.price});

  factory ExternalOrderItem.fromJson(Map<String, dynamic> json) {
    return ExternalOrderItem(
      name: json['name']?.toString() ?? '',
      price: json['price'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'price': price,
    };
  }
}
