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
      final response = await supabase.from('rooms').select().order('name');
      return (response as List).map((json) => Room.fromJson(json)).toList();
    } catch (e) {
      print('Error getting rooms: $e');
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
      print('Error getting dashboard stats: $e');
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
      print('Error getting room: $e');
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
          .order('start_time', ascending: false);

      return (response as List)
          .map((json) => SessionHistory.fromJson(json))
          .toList();
    } catch (e) {
      print('Error getting room history: $e');
      rethrow;
    }
  }

  @override
  Future<void> startSession(String roomId) async {
    try {
      final now = DateTime.now().toUtc(); // استخدام UTC

      // الحصول على بيانات الغرفة لمعرفة سعر الساعة
      final room = await getRoom(roomId);

      // تحديث حالة الغرفة
      await supabase
          .from('rooms')
          .update({
            'is_occupied': true,
            'session_start': now.toIso8601String(), // تأكد أنه ISO String
            'updated_at': now.toIso8601String(),
          })
          .eq('id', roomId);

      // إضافة جلسة جديدة مع سعر الساعة الخاص بالغرفة
      await supabase.from('session_history').insert({
        'room_id': roomId,
        'start_time': now.toIso8601String(), // ISO String
        'hourly_rate': room.hourlyRate,
        'total_cost': 0.0,
        'created_at': now.toIso8601String(),
      });
    } catch (e) {
      print('Error starting session: $e');
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
        final duration = Duration.zero;
        final hours = duration.inMinutes / 60.0;
        final totalCost = 0.0;
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
      print('Error ending session: $e');
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
      print('Error getting active session: $e');
      return null;
    }
  }
}
