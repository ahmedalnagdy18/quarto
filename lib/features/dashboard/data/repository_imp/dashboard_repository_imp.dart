import 'package:quarto/features/dashboard/data/model/room_model.dart';
import 'package:quarto/features/dashboard/data/model/session_history_model.dart';
import 'package:quarto/features/dashboard/domain/repository/dashboard_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DashboardRepositoryImp implements DashboardRepository {
  final SupabaseClient supabase;

  DashboardRepositoryImp({required this.supabase});

  @override
  Future<List<Room>> getAllRooms() async {
    final response = await supabase.from('rooms').select().order('name');

    return (response as List).map((json) => Room.fromJson(json)).toList();
  }

  @override
  Future<Map<String, dynamic>> getDashboardStats() async {
    final rooms = await getAllRooms();

    final occupied = rooms.where((r) => r.isOccupied).length;

    // Today income
    final today = DateTime.now();
    final start =
        DateTime(today.year, today.month, today.day).toIso8601String();

    final incomeResponse = await supabase
        .from('session_history')
        .select('total_cost')
        .gte('end_time', start);

    double income = 0;
    for (var s in incomeResponse) {
      income += (s['total_cost'] as num).toDouble();
    }

    return {
      'totalRooms': rooms.length,
      'occupiedRooms': occupied,
      'freeRooms': rooms.length - occupied,
      'todayIncome': income,
      'rooms': rooms,
    };
  }

  @override
  Future<Room> getRoom(String roomId) async {
    final response =
        await supabase.from('rooms').select().eq('id', roomId).single();

    return Room.fromJson(response);
  }

  @override
  Future<List<SessionHistory>> getRoomHistoryToday(String roomId) async {
    final today = DateTime.now();
    final start =
        DateTime(today.year, today.month, today.day).toIso8601String();

    final response = await supabase
        .from('session_history')
        .select()
        .eq('room_id', roomId)
        .gte('start_time', start)
        .order('start_time', ascending: false);

    return (response as List)
        .map((json) => SessionHistory.fromJson(json))
        .toList();
  }

  @override
  Future<void> startSession(String roomId) async {
    final now = DateTime.now().toIso8601String();

    // Update room status
    await supabase
        .from('rooms')
        .update({'is_occupied': true, 'session_start': now})
        .eq('id', roomId);

    // Insert session history
    final room = await getRoom(roomId);

    await supabase.from('session_history').insert({
      'room_id': roomId,
      'start_time': now,
      'hourly_rate': room.hourlyRate,
      'total_cost': 0.0,
    });
  }

  @override
  Future<void> endSession(String roomId) async {
    final room = await getRoom(roomId);
    final now = DateTime.now().toIso8601String();

    final cost = room.currentSessionCost;

    await supabase
        .from('rooms')
        .update({'is_occupied': false, 'session_start': null})
        .eq('id', roomId);

    // Get latest session
    final session =
        await supabase
            .from('session_history')
            .select()
            .eq('room_id', roomId)
            .order('start_time', ascending: false)
            .limit(1)
            .single();

    await supabase
        .from('session_history')
        .update({'end_time': now, 'total_cost': cost})
        .eq('id', session['id']);
  }
}
