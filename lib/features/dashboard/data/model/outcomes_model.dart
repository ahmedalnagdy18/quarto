class OutcomesModel {
  final String id;
  final String note;
  final int price;

  OutcomesModel({
    required this.id,
    required this.note,
    required this.price,
  });

  factory OutcomesModel.fromJson(Map<String, dynamic> json) {
    return OutcomesModel(
      id: json['id']?.toString() ?? '',
      note: json['note'] ?? '',
      price: json['price'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'note': note,
      'price': price,
    };
  }
}
