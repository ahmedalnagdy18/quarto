class ExternalOrdersModel {
  final String id;
  final String order;
  final int price;

  ExternalOrdersModel({
    required this.id,
    required this.order,
    required this.price,
  });

  factory ExternalOrdersModel.fromJson(Map<String, dynamic> json) {
    return ExternalOrdersModel(
      id: json['id']?.toString() ?? '',
      order: json['order'] ?? '',
      price: json['price'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order': order,
      'price': price,
    };
  }
}
