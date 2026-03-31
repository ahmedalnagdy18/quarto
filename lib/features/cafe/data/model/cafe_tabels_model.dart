import 'package:equatable/equatable.dart';

class CafeTableModel extends Equatable {
  final String id;
  final String tableName;
  final bool isOccupied;

  const CafeTableModel({
    required this.id,
    required this.tableName,
    required this.isOccupied,
  });

  factory CafeTableModel.fromJson(Map<String, dynamic> json) {
    return CafeTableModel(
      id: json['id']?.toString() ?? '',
      tableName: json['table_name']?.toString() ?? '',
      isOccupied: json['is_occupied'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'table_name': tableName,
      'is_occupied': isOccupied,
    };
  }

  @override
  List<Object?> get props => [id, tableName, isOccupied];
}
