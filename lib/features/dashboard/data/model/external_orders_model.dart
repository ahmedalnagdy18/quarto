class ExternalOrdersModel {
  final String id;
  final String order;
  final int price;
  final bool payment;

  ExternalOrdersModel({
    required this.id,
    required this.order,
    required this.price,
    required this.payment,
  });

  factory ExternalOrdersModel.fromJson(Map<String, dynamic> json) {
    return ExternalOrdersModel(
      id: json['id']?.toString() ?? '',
      order: json['order'] ?? '',
      price: json['price'] ?? 0,
      payment: json['payment'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order': order,
      'price': price,
      'payment': payment,
    };
  }
}
