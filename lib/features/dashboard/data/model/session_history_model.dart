import 'package:quarto/core/extentions/app_extentions.dart';
import 'package:quarto/features/dashboard/data/model/room_model.dart';

class SessionHistory {
  final String id;
  final String roomId;
  final DateTime startTime;
  final DateTime? endTime;
  final double hourlyRate;
  final double totalCost; // شامل الأوردرات
  final String? psType;
  final bool? isMulti;
  final double? orders; // مجموع الأوردرات
  final List<OrderItem> ordersList;

  SessionHistory({
    required this.id,
    required this.roomId,
    required this.startTime,
    this.endTime,
    required this.hourlyRate,
    required this.totalCost,
    this.psType,
    this.isMulti,
    this.orders,
    this.ordersList = const [],
  });

  factory SessionHistory.fromJson(Map<String, dynamic> json) {
    DateTime parseTime(dynamic value) {
      if (value == null) throw Exception('Null timestamp');
      if (value is DateTime) return value;
      if (value is String) return DateTime.parse(value).toLocal();
      return DateTime.parse(value.toString()).toLocal();
    }

    List<OrderItem> parseOrders(dynamic value) {
      if (value is List) {
        return value.map((e) => OrderItem.fromJson(e)).toList();
      }
      return [];
    }

    return SessionHistory(
      id: json['id'].toString(),
      roomId: json['room_id'].toString(),
      startTime: parseTime(json['start_time']),
      endTime: json['end_time'] != null ? parseTime(json['end_time']) : null,
      hourlyRate: (json['hourly_rate'] as num).toDouble(),
      totalCost: (json['total_cost'] as num).toDouble(),
      psType: json['ps_type'] as String?,
      isMulti: json['is_multi'] as bool?,
      orders: (json['orders'] as num?)?.toDouble() ?? 0,
      ordersList: parseOrders(json['orders_items']),
    );
  }

  // Total orders cost
  double get ordersTotal => ordersList.fold(0, (sum, item) => sum + item.price);

  String get startTimeShort => TimeFormatter.formatTo12Hour(startTime);

  String get endTimeShort {
    if (endTime == null) return 'Running';
    return TimeFormatter.formatTo12Hour(endTime!);
  }

  String get formattedDuration {
    if (endTime == null) return 'Running';
    final duration = endTime!.difference(startTime);
    if (duration.isNegative) return '0m';
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    return hours > 0 ? '${hours}h ${minutes}m' : '${minutes}m';
  }

  String get formattedCost => '${totalCost.toStringAsFixed(0)} \$';

  String get sessionTypeInfo {
    final parts = [];
    if (psTypeDisplay != null) parts.add(psTypeDisplay!);
    if (sessionTypeDisplay != null) parts.add(sessionTypeDisplay!);
    return parts.join(' - ');
  }

  String? get psTypeDisplay {
    if (psType == 'ps4') return 'PS4';
    if (psType == 'ps5') return 'PS5';
    return null;
  }

  String? get sessionTypeDisplay {
    if (isMulti == true) return 'Multi';
    if (isMulti == false) return 'Single';
    return null;
  }
}
