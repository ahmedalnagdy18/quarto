import 'package:quarto/features/dashboard/data/model/external_orders_model.dart';
import 'package:quarto/features/dashboard/data/model/room_outcomes_model.dart';
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
      rethrow;
    }
  }

  @override
  Future<Map<String, dynamic>> getDashboardStats() async {
    try {
      final rooms = await getAllRooms();

      final occupiedRooms = rooms.where((r) => r.isOccupied).length;
      final freeRooms = rooms.length - occupiedRooms;

      final sessions = await supabase
          .from('session_history')
          .select('total_cost, orders, payment_method')
          .not('end_time', 'is', null);

      double roomsIncome = 0.0;
      double ordersIncome = 0.0;
      double roomCashTotal = 0.0;
      double roomVisaTotal = 0.0;

      for (final session in sessions) {
        final totalCost = (session['total_cost'] as num?)?.toDouble() ?? 0.0;
        final rawOrdersCost = (session['orders'] as num?)?.toDouble() ?? 0.0;
        final ordersCost = rawOrdersCost.clamp(0.0, totalCost);
        final sessionOnlyIncome = (totalCost - ordersCost).clamp(
          0.0,
          double.infinity,
        );
        final paymentMethod = _normalizePaymentMethod(
          session['payment_method']?.toString(),
        );

        ordersIncome += ordersCost;
        roomsIncome += sessionOnlyIncome;
        if (paymentMethod == 'cash') {
          roomCashTotal += totalCost;
        } else if (paymentMethod == 'visa') {
          roomVisaTotal += totalCost;
        }
      }

      return {
        'totalRooms': rooms.length,
        'occupiedRooms': occupiedRooms,
        'freeRooms': freeRooms,
        'roomsIncome': roomsIncome,
        'ordersIncome': ordersIncome,
        'roomCashTotal': roomCashTotal,
        'roomVisaTotal': roomVisaTotal,
        'todayIncome': roomsIncome + ordersIncome,
        'rooms': rooms,
      };
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<Room> getRoom(String roomId) async {
    try {
      final response = await supabase
          .from('rooms')
          .select()
          .eq('id', roomId)
          .single();
      return Room.fromJson(response);
    } catch (e) {
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
      final room = await getRoom(roomId);
      final finalHourlyRate = hourlyRate ?? room.hourlyRate;

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

      final sessionData = {
        'room_id': roomId,
        'start_time': now.toIso8601String(),
        'hourly_rate': finalHourlyRate,
        'total_cost': 0.0,
        'created_at': now.toIso8601String(),
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
  Future<void> moveRoomSession({
    required String fromRoomId,
    required String toRoomId,
  }) async {
    try {
      final now = DateTime.now().toUtc();
      final sourceRoom = await getRoom(fromRoomId);
      final targetRoom = await getRoom(toRoomId);

      if (!sourceRoom.isOccupied || sourceRoom.sessionStart == null) {
        throw Exception('No active session found for this room.');
      }
      if (targetRoom.isOccupied) {
        throw Exception('Target room is already occupied.');
      }

      final activeSession = await _getActiveSession(fromRoomId);
      if (activeSession == null) {
        throw Exception('No active session found in database.');
      }

      final sourceStart = sourceRoom.sessionStart!.toUtc();
      final currentSegmentCost = _calculateSegmentCost(
        start: sourceStart,
        end: now,
        hourlyRate: sourceRoom.hourlyRate,
      );

      final sessionOrdersTotal =
          (activeSession['orders'] as num?)?.toDouble() ??
          sourceRoom.ordersTotal;
      final storedTotal =
          (activeSession['total_cost'] as num?)?.toDouble() ?? 0.0;
      final carriedSessionCost = (storedTotal - sessionOrdersTotal).clamp(
        0.0,
        double.infinity,
      );
      final updatedRunningTotal =
          carriedSessionCost + currentSegmentCost + sessionOrdersTotal;

      await supabase
          .from('rooms')
          .update({
            'is_occupied': false,
            'session_start': null,
            'ps_type': null,
            'is_multi': null,
            'orders': 0,
            'orders_items': <Map<String, dynamic>>[],
            'updated_at': now.toIso8601String(),
          })
          .eq('id', fromRoomId);

      await supabase
          .from('rooms')
          .update({
            'is_occupied': true,
            'session_start': now.toIso8601String(),
            'ps_type': sourceRoom.psType,
            'is_multi': sourceRoom.isMulti,
            'orders': sessionOrdersTotal,
            'orders_items': sourceRoom.ordersList
                .map((item) => item.toJson())
                .toList(),
            'updated_at': now.toIso8601String(),
          })
          .eq('id', toRoomId);

      await supabase
          .from('session_history')
          .update({
            'room_id': toRoomId,
            'start_time': now.toIso8601String(),
            'hourly_rate': targetRoom.hourlyRate,
            'total_cost': updatedRunningTotal,
            'orders': sessionOrdersTotal,
            'ps_type': sourceRoom.psType,
            'is_multi': sourceRoom.isMulti,
            'updated_at': now.toIso8601String(),
          })
          .eq('id', activeSession['id']);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> endSession(
    String roomId, {
    required String paymentMethod,
  }) async {
    try {
      final now = DateTime.now().toUtc();
      final room = await getRoom(roomId);

      if (room.sessionStart == null) {
        throw Exception('No active session found for room $roomId');
      }

      final sessionStartUtc = room.sessionStart!.toUtc();
      final activeSession = await _getActiveSession(roomId);

      if (activeSession == null) {
        throw Exception('No active session found in database');
      }

      final existingOrdersCost =
          (activeSession['orders'] as num?)?.toDouble() ?? room.ordersTotal;
      final storedTotal =
          (activeSession['total_cost'] as num?)?.toDouble() ?? 0.0;
      final carriedSessionCost = (storedTotal - existingOrdersCost).clamp(
        0.0,
        double.infinity,
      );

      double currentSegmentCost = 0;
      if (!sessionStartUtc.isAfter(now)) {
        currentSegmentCost = _calculateSegmentCost(
          start: sessionStartUtc,
          end: now,
          hourlyRate: room.hourlyRate,
        );
      }

      final totalCost =
          carriedSessionCost + currentSegmentCost + existingOrdersCost;

      await supabase
          .from('rooms')
          .update({
            'is_occupied': false,
            'session_start': null,
            'ps_type': null,
            'is_multi': null,
            'orders': 0,
            'orders_items': <Map<String, dynamic>>[],
            'updated_at': now.toIso8601String(),
          })
          .eq('id', roomId);

      await supabase
          .from('session_history')
          .update({
            'end_time': now.toIso8601String(),
            'total_cost': totalCost,
            'orders': existingOrdersCost,
            'payment_method': _normalizePaymentMethod(paymentMethod),
            'updated_at': now.toIso8601String(),
          })
          .eq('id', activeSession['id']);
    } catch (e) {
      rethrow;
    }
  }

  double _calculateSegmentCost({
    required DateTime start,
    required DateTime end,
    required double hourlyRate,
  }) {
    if (start.isAfter(end)) {
      return 0.0;
    }
    final duration = end.difference(start);
    final hours = duration.inMinutes / 60.0;
    return hours * hourlyRate;
  }

  String _normalizePaymentMethod(String? paymentMethod) {
    switch ((paymentMethod ?? '').trim().toLowerCase()) {
      case 'visa':
        return 'visa';
      case 'cash':
      default:
        return 'cash';
    }
  }

  Future<Map<String, dynamic>?> _getActiveSession(String roomId) async {
    try {
      final response = await supabase
          .from('session_history')
          .select()
          .eq('room_id', roomId)
          .filter('end_time', 'is', null)
          .order('start_time', ascending: false)
          .limit(1)
          .maybeSingle();

      return response;
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> clearAllHistory() async {
    try {
      await supabase.from('session_history').delete().not('id', 'is', null);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> resetAllSessions() async {
    try {
      final now = DateTime.now().toUtc();
      final rooms = await getAllRooms();

      for (final room in rooms) {
        try {
          if (room.isOccupied && room.sessionStart != null) {
            try {
              await endSession(room.id, paymentMethod: 'cash');
            } catch (e) {}
          }

          await supabase
              .from('rooms')
              .update({
                'is_occupied': false,
                'session_start': null,
                'ps_type': null,
                'is_multi': null,
                'orders': 0,
                'orders_items': <Map<String, dynamic>>[],
                'updated_at': now.toIso8601String(),
              })
              .eq('id', room.id);
        } catch (e) {}
      }
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> startNewDay() async {
    try {
      await resetAllSessions();

      try {
        await clearAllHistory();
      } catch (e) {}
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> addOrders(
    String roomId,
    List<OrderItem> orders, {
    String? sessionId,
  }) async {
    try {
      if (orders.isEmpty) return;

      final newOrdersPrice = orders.fold(0.0, (sum, item) => sum + item.price);
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

      if (sessionId != null && sessionId.isNotEmpty) {
        final sessionResponse = await supabase
            .from('session_history')
            .select()
            .eq('id', sessionId)
            .single();

        final currentOrdersList =
            (sessionResponse['orders_items'] as List?)
                ?.map((e) => OrderItem.fromJson(Map<String, dynamic>.from(e)))
                .toList() ??
            [];

        final newOrdersList = [...currentOrdersList, ...orders];
        final newOrdersTotal = newOrdersList.fold(
          0.0,
          (sum, item) => sum + item.price,
        );

        final currentTotalCost = (sessionResponse['total_cost'] as num)
            .toDouble();
        final updatedTotalCost = currentTotalCost + newOrdersPrice;

        await supabase
            .from('session_history')
            .update({
              'orders': newOrdersTotal,
              'orders_items': newOrdersList.map((o) => o.toJson()).toList(),
              'total_cost': updatedTotalCost,
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id', sessionId);
      } else {
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

          final currentTotalCost = (activeSession['total_cost'] as num)
              .toDouble();
          final updatedTotalCost = currentTotalCost + newOrdersPrice;

          await supabase
              .from('session_history')
              .update({
                'orders': newOrdersTotal,
                'orders_items': newOrdersList.map((o) => o.toJson()).toList(),
                'total_cost': updatedTotalCost,
                'updated_at': DateTime.now().toIso8601String(),
              })
              .eq('id', activeSession['id']);
        }
      }
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> addRoomOutcomesItems(RoomOutcomesModel items) async {
    try {
      await supabase.from('room_outcomes').insert({
        'material': items.material,
        'quantity': items.quantity,
        'price': items.price,
      });
    } catch (e) {
      throw Exception('Failed to add Room outcome: $e');
    }
  }

  @override
  Future<List<RoomOutcomesModel>> getRoomOutcomesItems() async {
    final response = await supabase
        .from('room_outcomes')
        .select()
        .order('id', ascending: false);

    return (response as List)
        .map((json) => RoomOutcomesModel.fromJson(json))
        .toList();
  }

  @override
  Future<void> addExternalOrders(
    ExternalOrdersModel externalOrdersModel,
  ) async {
    try {
      await supabase.from('external_orders').insert({
        'table': externalOrdersModel.table,
        'order': externalOrdersModel.order,
        'payment': externalOrdersModel.payment,
      });
    } catch (e) {
      throw Exception('Failed to add order: $e');
    }
  }

  @override
  Future<void> deleteExternalOrder(String id) async {
    await supabase.from('external_orders').delete().eq('id', id);
  }

  @override
  Future<List<ExternalOrdersModel>> getExternalOrders() async {
    final response = await supabase
        .from('external_orders')
        .select()
        .order('id', ascending: false);

    return (response as List)
        .map((json) => ExternalOrdersModel.fromJson(json))
        .toList();
  }

  @override
  Future<void> clearAllExternalOrders() async {
    try {
      await supabase.from('external_orders').delete().not('id', 'is', null);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> addComments(
    String comments,
    String roomId, {
    String? sessionId,
  }) async {
    try {
      if (comments.isEmpty) return;

      String? targetSessionId = sessionId;

      if (targetSessionId == null || targetSessionId.isEmpty) {
        final activeSession = await _getActiveSession(roomId);
        if (activeSession != null) {
          targetSessionId = activeSession['id'] as String?;
        } else {
          final lastSession = await supabase
              .from('session_history')
              .select('id')
              .eq('room_id', roomId)
              .not('end_time', 'is', null)
              .order('end_time', ascending: false)
              .limit(1)
              .maybeSingle();

          if (lastSession != null) {
            targetSessionId = lastSession['id'] as String?;
          }
        }
      }

      if (targetSessionId == null || targetSessionId.isEmpty) {
        return;
      }

      final currentSession = await supabase
          .from('session_history')
          .select('comments')
          .eq('id', targetSessionId)
          .maybeSingle();

      List<dynamic> currentComments = [];
      if (currentSession != null && currentSession['comments'] != null) {
        var commentsData = currentSession['comments'];
        if (commentsData is List) {
          currentComments = List.from(commentsData);
        } else if (commentsData is String) {
          currentComments = [commentsData];
        }
      }

      currentComments.add(comments);

      await supabase
          .from('session_history')
          .update({
            'comments': currentComments,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', targetSessionId);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> editExternalOrders(
    ExternalOrdersModel externalOrdersModel,
  ) async {
    try {
      await supabase
          .from('external_orders')
          .update({
            'id': externalOrdersModel.id,
            'table': externalOrdersModel.table,
            'order': externalOrdersModel.order,
            'payment': externalOrdersModel.payment,
          })
          .eq('id', externalOrdersModel.id);
    } catch (e) {
      throw Exception('Failed to update order: $e');
    }
  }
}
