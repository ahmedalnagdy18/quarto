import 'package:equatable/equatable.dart';

class RoomOutcomesModel extends Equatable {
  final String? id;
  final String material;
  final int quantity;
  final double price;
  final String? date;

  const RoomOutcomesModel({
    this.id,
    required this.material,
    required this.quantity,
    required this.price,
    this.date,
  });

  factory RoomOutcomesModel.fromJson(Map<String, dynamic> json) {
    return RoomOutcomesModel(
      id: json['id']?.toString() ?? '',
      material: json['material']?.toString() ?? '',
      quantity: json['quantity'] ?? 1,
      price: (json['price'] ?? 0).toDouble(),
      date: json['date']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'material': material,
      'quantity': quantity,
      'price': price,
      'date': date,
    };
  }

  @override
  List<Object?> get props => [
    id,
    material,
    quantity,
    price,
    date,
  ];
}
