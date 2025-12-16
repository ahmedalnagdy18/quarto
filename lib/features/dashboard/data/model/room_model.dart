class Room {
  final String id;
  final String name;
  final bool isOccupied;
  final DateTime? sessionStart;
  final double hourlyRate;
  final bool isVip;
  final String? psType;
  final bool? isMulti;
  final double? orders; // مجموع الأوردرات
  final List<OrderItem> ordersList; // الأصناف نفسها

  Room({
    required this.id,
    required this.name,
    required this.isOccupied,
    this.sessionStart,
    required this.hourlyRate,
    this.isVip = false,
    this.psType,
    this.isMulti,
    this.orders,
    this.ordersList = const [],
  });

  factory Room.fromJson(Map<String, dynamic> json) {
    DateTime? parseDateTime(dynamic value) {
      if (value == null) return null;
      if (value is DateTime) return value.toLocal();
      if (value is String) {
        try {
          return DateTime.parse(value).toLocal();
        } catch (e) {
          return null;
        }
      }
      return null;
    }

    List<OrderItem> parseOrders(dynamic value) {
      if (value is List) {
        return value.map((e) => OrderItem.fromJson(e)).toList();
      }
      return [];
    }

    return Room(
      id: json['id'].toString(),
      name: json['name'] ?? 'Room',
      isOccupied: json['is_occupied'] == true,
      sessionStart: parseDateTime(json['session_start']),
      hourlyRate: (json['hourly_rate'] as num?)?.toDouble() ?? 100.0,
      isVip: json['is_vip'] == true,
      psType: json['ps_type'] as String?,
      isMulti: json['is_multi'] as bool?,
      orders: (json['orders'] as num?)?.toDouble() ?? 0,
      ordersList: parseOrders(json['orders_items']),
    );
  }

  double get ordersTotal => ordersList.fold(0, (sum, item) => sum + item.price);

  // حساب تكلفة الجلسة الحالية
  double get calculatedCost {
    if (sessionStart == null) return 0.0;
    final now = DateTime.now();
    final start = sessionStart!;
    if (start.isAfter(now)) return 0.0;
    final duration = now.difference(start);
    final hours = duration.inMinutes / 60.0;
    final cost = hours * hourlyRate;
    return cost < 0 ? 0.0 : cost;
  }

  String get formattedCurrentCost => '${calculatedCost.toStringAsFixed(0)} \$';

  // -------- Live Duration و Room Type Description --------
  String get liveDuration {
    if (sessionStart == null) return '0h 0m';
    final now = DateTime.now();
    final duration = now.difference(sessionStart!);
    if (duration.isNegative) return '0h 0m';
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    return '${hours}h ${minutes}m';
  }

  String get roomTypeDescription {
    if (name.toLowerCase().contains('room 8') ||
        name.toLowerCase().contains('room8')) {
      return "Room 8 (Special)";
    }
    return isVip ? "VIP Room" : "Standard Room";
  }

  // Get display name for PS type
  String? get psTypeDisplay {
    if (psType == 'ps4') return 'PS4';
    if (psType == 'ps5') return 'PS5';
    return null;
  }

  // Get display name for session type
  String? get sessionTypeDisplay {
    if (isMulti == true) return 'Multi';
    if (isMulti == false) return 'Single';
    return null;
  }
}

class OrderItem {
  final String name;
  final double price;

  OrderItem({
    required this.name,
    required this.price,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      name: json['name'] as String,
      price: (json['price'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'price': price,
  };
}
