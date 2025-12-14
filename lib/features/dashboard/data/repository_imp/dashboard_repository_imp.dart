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

      // دخل اليوم من session_history
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);

      final incomeResponse = await supabase
          .from('session_history')
          .select('total_cost')
          .gte('end_time', startOfDay.toIso8601String())
          .not('end_time', 'is', null); // فقط الجلسات المنتهية

      double todayIncome = 0;
      for (var session in incomeResponse) {
        final cost = session['total_cost'];
        if (cost != null) {
          todayIncome += (cost as num).toDouble();
        }
      }

      return {
        'totalRooms': rooms.length,
        'occupiedRooms': occupiedRooms,
        'freeRooms': freeRooms,
        'todayIncome': todayIncome,
        'rooms': rooms,
      };
    } catch (e) {
      // print('Error getting dashboard stats: $e');
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
  Future<List<SessionHistory>> getRoomHistoryToday(String roomId) async {
    try {
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);

      final response = await supabase
          .from('session_history')
          .select()
          .eq('room_id', roomId)
          .gte('start_time', startOfDay.toIso8601String())
          .order('start_time', ascending: true);

      return (response as List)
          .map((json) => SessionHistory.fromJson(json))
          .toList();
    } catch (e) {
      // print('Error getting room history: $e');
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
      };

      if (psType != null) {
        sessionData['ps_type'] = psType;
      }
      if (isMulti != null) {
        sessionData['is_multi'] = isMulti;
      }

      await supabase.from('session_history').insert(sessionData);
    } catch (e) {
      // print('Error starting session: $e');
      rethrow;
    }
  }

  @override
  Future<void> endSession(String roomId) async {
    try {
      final now = DateTime.now().toUtc(); // استخدام UTC

      // الحصول على بيانات الغرفة
      final room = await getRoom(roomId);

      if (room.sessionStart == null) {
        throw Exception('No active session found for room $roomId');
      }

      // تحويل sessionStart إلى UTC للتأكد
      final sessionStartUtc = room.sessionStart!.toUtc();

      // التحقق من أن وقت البداية ليس في المستقبل
      if (sessionStartUtc.isAfter(now)) {
        // إذا كان وقت البداية في المستقبل، نستخدم وقت الآن
      } else {
        // حساب المدة بشكل صحيح
        final duration = now.difference(sessionStartUtc);
        final hours = duration.inMinutes / 60.0;
        final totalCost = (hours * room.hourlyRate);

        // تحديث حالة الغرفة
        await supabase
            .from('rooms')
            .update({
              'is_occupied': false,
              'session_start': null,
              'updated_at': now.toIso8601String(),
            })
            .eq('id', roomId);

        // البحث عن الجلسة النشطة
        final activeSession = await _getActiveSession(roomId);

        if (activeSession == null) {
          throw Exception('No active session found in database');
        }

        // تحديث الجلسة
        await supabase
            .from('session_history')
            .update({
              'end_time': now.toIso8601String(),
              'total_cost': totalCost,
            })
            .eq('id', activeSession['id']);
      }
    } catch (e) {
      // print('Error ending session: $e');
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
  Future<void> clearTodayHistory() async {
    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      // print('Clearing today\'s history from $startOfDay to $endOfDay');

      // Delete all session history from today
      final response = await supabase
          .from('session_history')
          .delete()
          .gte('start_time', startOfDay.toIso8601String())
          .lt('start_time', endOfDay.toIso8601String());

      // Handle null response (no rows deleted)
      final deletedCount = response?.length ?? 0;
      print('Deleted $deletedCount sessions from today');
    } catch (e) {
      // print('Error clearing today history: $e');
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
        await clearTodayHistory();
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
}
