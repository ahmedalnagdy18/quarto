import 'package:quarto/features/dashboard/data/model/room_model.dart';
import 'package:quarto/features/dashboard/data/model/session_history_model.dart';
import 'package:quarto/features/dashboard/domain/repository/dashboard_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DashboardRepositoryImp implements DashboardRepository {
  final SupabaseClient supabase;

  DashboardRepositoryImp({required this.supabase});

  @override
  Future<List<Room>> getAllRooms() async {
    try {
      final response = await supabase
          .from('rooms')
          .select()
          .order('name', ascending: true);
      return (response as List).map((json) => Room.fromJson(json)).toList();
    } catch (e) {
      // print('Error getting rooms: $e');
      rethrow;
    }
  }

  @override
  Future<Map<String, dynamic>> getDashboardStats() async {
    try {
      final rooms = await getAllRooms();

      final occupiedRooms = rooms.where((r) => r.isOccupied).length;
      final freeRooms = rooms.length - occupiedRooms;

      // ================= احسب دخل كل الغرف =================
      double totalIncome = 0;

      // تحقق من كل الجلسات في الداتابيز
      // final allSessions = await supabase
      //     .from('session_history')
      //     .select('id, total_cost, orders, start_time, room_id')
      //     .not('end_time', 'is', null);

      // for (var session in allSessions) {
      //   final cost = session['total_cost'] ?? 0;
      //   final orders = session['orders'] ?? 0;
      //   final sessionCost =
      //       (cost as num).toDouble() - (orders as num).toDouble();
      //   print(
      //     "  - Session ${session['id']}: Total=$cost, Orders=$orders, Session Cost=${sessionCost.toStringAsFixed(2)}",
      //   );
      // }

      for (var room in rooms) {
        try {
          final roomHistoryResponse = await supabase
              .from('session_history')
              .select('total_cost, orders, start_time, end_time')
              .eq('room_id', room.id)
              .not('end_time', 'is', null);

          double roomTotal = 0;
          for (var session in roomHistoryResponse) {
            final cost = session['total_cost'];
            if (cost != null) {
              roomTotal += (cost as num).toDouble();
            }
          }

          if (roomTotal > 0) {
            // print("  - ${room.name}: ${roomTotal.toStringAsFixed(0)} \$");
            totalIncome += roomTotal;
          }
        } catch (e) {
          // print("  - Error for ${room.name}: $e");
        }
      }

      // print("💰 FINAL TOTAL: ${totalIncome.toStringAsFixed(0)} \$");

      return {
        'totalRooms': rooms.length,
        'occupiedRooms': occupiedRooms,
        'freeRooms': freeRooms,
        'todayIncome': totalIncome,
        'rooms': rooms,
      };
    } catch (e) {
      // print("❌ Error in getDashboardStats: $e");
      rethrow;
    }
  }

  @override
  Future<Room> getRoom(String roomId) async {
    try {
      final response =
          await supabase.from('rooms').select().eq('id', roomId).single();
      return Room.fromJson(response);
    } catch (e) {
      // print('Error getting room: $e');
      rethrow;
    }
  }

  @override
  Future<List<SessionHistory>> getRoomHistory(String roomId) async {
    try {
      final response = await supabase
          .from('session_history')
          .select()
          .eq('room_id', roomId)
          .order('start_time', ascending: true);

      return (response as List)
          .map((json) => SessionHistory.fromJson(json))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> startSession({
    required String roomId,
    String? psType,
    bool? isMulti,
    double? hourlyRate,
  }) async {
    try {
      final now = DateTime.now().toUtc();

      // Get room info
      final room = await getRoom(roomId);

      // Use provided hourly rate or calculate based on selection
      final finalHourlyRate = hourlyRate ?? room.hourlyRate;

      // Update room with session info
      final updateData = {
        'is_occupied': true,
        'session_start': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
      };

      if (psType != null) {
        updateData['ps_type'] = psType;
      }
      if (isMulti != null) {
        updateData['is_multi'] = isMulti;
      }
      if (hourlyRate != null) {
        updateData['hourly_rate'] = hourlyRate;
      }

      await supabase.from('rooms').update(updateData).eq('id', roomId);

      // Add session to history
      final sessionData = {
        'room_id': roomId,
        'start_time': now.toIso8601String(),
        'hourly_rate': finalHourlyRate,
        'total_cost': 0.0,
        'created_at': now.toIso8601String(),
        // REMOVE 'updated_at' if column doesn't exist
        // 'updated_at': now.toIso8601String(),
      };

      if (psType != null) {
        sessionData['ps_type'] = psType;
      }
      if (isMulti != null) {
        sessionData['is_multi'] = isMulti;
      }

      await supabase.from('session_history').insert(sessionData);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> endSession(String roomId) async {
    try {
      final now = DateTime.now().toUtc();

      // الحصول على بيانات الغرفة
      final room = await getRoom(roomId);

      if (room.sessionStart == null) {
        throw Exception('No active session found for room $roomId');
      }

      // تحويل sessionStart إلى UTC
      final sessionStartUtc = room.sessionStart!.toUtc();

      // البحث عن الجلسة النشطة
      final activeSession = await _getActiveSession(roomId);

      if (activeSession == null) {
        throw Exception('No active session found in database');
      }

      // حساب تكلفة الجلسة
      double sessionCost = 0;
      if (!sessionStartUtc.isAfter(now)) {
        final duration = now.difference(sessionStartUtc);
        final hours = duration.inMinutes / 60.0;
        sessionCost = (hours * room.hourlyRate);
      }

      // ⭐⭐ هنا المشكلة ⭐⭐
      // بدل ما نأخذ room.orders (كل الأوردرات في تاريخ الغرفة)
      // نأخذ الأوردرات الخاصة بالجلسة النشطة فقط

      double existingOrdersCost = 0;

      // خد الأوردرات من الجلسة النشطة
      if (activeSession['orders_items'] != null) {
        final currentOrdersList =
            (activeSession['orders_items'] as List)
                .map((e) => OrderItem.fromJson(Map<String, dynamic>.from(e)))
                .toList();

        if (currentOrdersList.isNotEmpty) {
          existingOrdersCost = currentOrdersList.fold(
            0.0,
            (sum, item) => sum + item.price,
          );
        }
      }

      // الإجمالي = تكلفة الجلسة + الأوردرات
      final totalCost = sessionCost + existingOrdersCost;

      // تحديث حالة الغرفة
      await supabase
          .from('rooms')
          .update({
            'is_occupied': false,
            'session_start': null,
            'updated_at': now.toIso8601String(),
          })
          .eq('id', roomId);

      // تحديث الجلسة
      await supabase
          .from('session_history')
          .update({
            'end_time': now.toIso8601String(),
            'total_cost': totalCost,
            'orders': existingOrdersCost,
            'updated_at': now.toIso8601String(),
          })
          .eq('id', activeSession['id']);

      print("✅ Session ended successfully");
    } catch (e) {
      // print("❌ Error ending session: $e");
      rethrow;
    }
  }

  // دالة مساعدة للحصول على الجلسة النشطة
  Future<Map<String, dynamic>?> _getActiveSession(String roomId) async {
    try {
      final response =
          await supabase
              .from('session_history')
              .select()
              .eq('room_id', roomId)
              .filter('end_time', 'is', null) // البحث عن الجلسات النشطة
              .order('start_time', ascending: false)
              .limit(1)
              .maybeSingle();

      return response;
    } catch (e) {
      // print('Error getting active session: $e');
      return null;
    }
  }

  @override
  Future<void> clearAllHistory() async {
    try {
      await supabase
          .from('session_history')
          .delete()
          .not('id', 'is', null); // <-- ده بيمسح كل الصفوف فعليًا

      // print('All session history cleared');
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> resetAllSessions() async {
    try {
      final now = DateTime.now().toUtc();

      // print('Resetting all sessions...');

      // 1. Get all rooms
      final rooms = await getAllRooms();

      // 2. Reset each room individually (safer, always works)
      for (final room in rooms) {
        try {
          // If room is occupied, try to end session properly
          if (room.isOccupied && room.sessionStart != null) {
            try {
              await endSession(room.id);
              // print('Ended session for room: ${room.name}');
            } catch (e) {
              // print('Could not properly end session for ${room.name}: $e');
            }
          }

          // Always reset the room state
          await supabase
              .from('rooms')
              .update({
                'is_occupied': false,
                'session_start': null,
                'ps_type': null,
                'is_multi': null,
                'updated_at': now.toIso8601String(),
              })
              .eq('id', room.id);

          // print('Reset room: ${room.name}');
        } catch (e) {
          // print('Error resetting room ${room.name}: $e');
          // Continue with next room
        }
      }

      // print('All rooms reset successfully');
    } catch (e) {
      // print('Error resetting all sessions: $e');
      rethrow;
    }
  }

  // Optional: Combined method to start new day
  @override
  Future<void> startNewDay() async {
    try {
      // print('Starting new day...');

      // 1. Reset all sessions (end active ones, reset rooms)
      await resetAllSessions();

      // 2. Clear today's history (wrap in try-catch to continue even if it fails)
      try {
        await clearAllHistory();
      } catch (e) {
        // print('Warning: Could not clear history: $e');
        // Continue anyway - rooms are already reset
      }

      // print('New day started successfully');
    } catch (e) {
      //  print('Error starting new day: $e');
      rethrow;
    }
  }

  @override
  Future<void> addOrders(
    String roomId,
    List<OrderItem> orders, {
    String? sessionId, //
  }) async {
    try {
      if (orders.isEmpty) return;

      final newOrdersPrice = orders.fold(0.0, (sum, item) => sum + item.price);

      // 1. تحديث الغرفة
      final room = await getRoom(roomId);
      final updatedOrdersList = [...room.ordersList, ...orders];
      final updatedOrdersTotal = updatedOrdersList.fold(
        0.0,
        (sum, item) => sum + item.price,
      );

      await supabase
          .from('rooms')
          .update({
            'orders': updatedOrdersTotal,
            'orders_items': updatedOrdersList.map((o) => o.toJson()).toList(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', roomId);

      // 2. تحديث الجلسة في session_history
      if (sessionId != null && sessionId.isNotEmpty) {
        // جلب بيانات الجلسة الحالية
        final sessionResponse =
            await supabase
                .from('session_history')
                .select()
                .eq('id', sessionId)
                .single();

        // Parse existing orders
        final currentOrdersList =
            (sessionResponse['orders_items'] as List?)
                ?.map((e) => OrderItem.fromJson(Map<String, dynamic>.from(e)))
                .toList() ??
            [];

        // ⭐⭐ هنا الفرق: newOrdersList للعرض فقط، لكن في الحساب نستخدم الجديدة بس
        final newOrdersList = [...currentOrdersList, ...orders];
        final newOrdersTotal = newOrdersList.fold(
          0.0,
          (sum, item) => sum + item.price,
        );

        // ⭐⭐ الحساب الصحيح: نضيف سعر الأوردرات الجديدة فقط
        final currentTotalCost =
            (sessionResponse['total_cost'] as num).toDouble();
        final ordersToAdd = newOrdersPrice; // ⭐ بس الأوردرات الجديدة
        final updatedTotalCost = currentTotalCost + ordersToAdd;

        // تحديث الجلسة
        await supabase
            .from('session_history')
            .update({
              'orders': newOrdersTotal, // الإجمالي الجديد لكل الأوردرات
              'orders_items': newOrdersList.map((o) => o.toJson()).toList(),
              'total_cost': updatedTotalCost, // ⭐ صحيح: تضيف الجديدة فقط
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id', sessionId);

        // print("✅ Updated session_history table for session: $sessionId");
      } else {
        // إذا sessionId مش موجود، نبحث عن الجلسة النشطة
        final activeSession = await _getActiveSession(roomId);
        if (activeSession != null) {
          final currentOrdersList =
              (activeSession['orders_items'] as List?)
                  ?.map((e) => OrderItem.fromJson(Map<String, dynamic>.from(e)))
                  .toList() ??
              [];

          final newOrdersList = [...currentOrdersList, ...orders];
          final newOrdersTotal = newOrdersList.fold(
            0.0,
            (sum, item) => sum + item.price,
          );

          // نفس المنطق: نضيف الجديدة فقط
          final currentTotalCost =
              (activeSession['total_cost'] as num).toDouble();
          final ordersToAdd = newOrdersPrice;
          final updatedTotalCost = currentTotalCost + ordersToAdd;

          await supabase
              .from('session_history')
              .update({
                'orders': newOrdersTotal,
                'orders_items': newOrdersList.map((o) => o.toJson()).toList(),
                'total_cost': updatedTotalCost,
                'updated_at': DateTime.now().toIso8601String(),
              })
              .eq('id', activeSession['id']);

          // print("✅ Updated active session in session_history");
        } else {
          // print("⚠️ No active session found for room: $roomId");
        }
      }

      // print("🎉 Orders added successfully to both tables!");
    } catch (e) {
      // print("❌ Error in addOrders: $e");
      rethrow;
    }
  }
}
