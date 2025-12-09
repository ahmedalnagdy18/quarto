// lib/services/supabase_service.dart
import 'package:quarto/features/dashboard/data/model/room_model.dart';
import 'package:quarto/features/dashboard/data/model/session_history_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  final supabase = Supabase.instance.client;

  // Room operations
  Future<List<Room>> getAllRooms() async {
    final response = await supabase.from('rooms').select().order('name');

    return (response as List).map((json) => Room.fromJson(json)).toList();
  }

  Future<Room> getRoom(String roomId) async {
    final response = await supabase
        .from('rooms')
        .select()
        .eq('id', roomId)
        .single();

    return Room.fromJson(response);
  }

  Future<void> updateRoom(Room room) async {
    await supabase.from('rooms').update(room.toJson()).eq('id', room.id);
  }

  Future<void> startSession(String roomId) async {
    await supabase
        .from('rooms')
        .update({
          'is_occupied': true,
          'session_start': DateTime.now().toIso8601String(),
        })
        .eq('id', roomId);

    // Create session history record
    final room = await getRoom(roomId);
    await supabase.from('session_history').insert({
      'room_id': roomId,
      'start_time': DateTime.now().toIso8601String(),
      'hourly_rate': room.hourlyRate,
      'total_cost': 0.0, // Will be updated when session ends
    });
  }

  Future<void> endSession(String roomId) async {
    final room = await getRoom(roomId);
    final cost = room.currentSessionCost;

    // Update room
    await supabase
        .from('rooms')
        .update({
          'is_occupied': false,
          'session_start': null,
        })
        .eq('id', roomId);

    // Update session history with end time and cost
    // Get the latest session for this room
    final sessionResponse = await supabase
        .from('session_history')
        .select()
        .eq('room_id', roomId)
        // .is('end_time', null)
        .order('start_time', ascending: false)
        .limit(1)
        .single();

    await supabase
        .from('session_history')
        .update({
          'end_time': DateTime.now().toIso8601String(),
          'total_cost': cost,
        })
        .eq('id', sessionResponse['id']);
  }

  // Session history operations
  Future<List<SessionHistory>> getRoomHistoryToday(String roomId) async {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = DateTime(today.year, today.month, today.day, 23, 59, 59);

    final response = await supabase
        .from('session_history')
        .select()
        .eq('room_id', roomId)
        .gte('start_time', startOfDay.toIso8601String())
        .lte('start_time', endOfDay.toIso8601String())
        .order('start_time', ascending: false);

    return (response as List)
        .map((json) => SessionHistory.fromJson(json))
        .toList();
  }

  Future<List<SessionHistory>> getRoomHistoryByDate(
    String roomId,
    DateTime date,
  ) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

    final response = await supabase
        .from('session_history')
        .select()
        .eq('room_id', roomId)
        .gte('start_time', startOfDay.toIso8601String())
        .lte('start_time', endOfDay.toIso8601String())
        .order('start_time', ascending: false);

    return (response as List)
        .map((json) => SessionHistory.fromJson(json))
        .toList();
  }

  // Dashboard statistics
  Future<Map<String, dynamic>> getDashboardStats() async {
    final rooms = await getAllRooms();
    final totalRooms = rooms.length;
    final occupiedRooms = rooms.where((room) => room.isOccupied).length;
    final freeRooms = totalRooms - occupiedRooms;

    // Calculate today's income
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);

    final incomeResponse = await supabase
        .from('session_history')
        .select('total_cost')
        .not('end_time', 'is', null)
        .gte('end_time', startOfDay.toIso8601String());

    double todayIncome = 0;
    for (var session in incomeResponse) {
      todayIncome += (session['total_cost'] as num).toDouble();
    }

    return {
      'totalRooms': totalRooms,
      'occupiedRooms': occupiedRooms,
      'freeRooms': freeRooms,
      'todayIncome': todayIncome,
      'rooms': rooms,
    };
  }
}
