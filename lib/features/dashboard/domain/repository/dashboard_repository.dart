import 'package:quarto/features/dashboard/data/model/room_model.dart';
import 'package:quarto/features/dashboard/data/model/session_history_model.dart';

abstract class DashboardRepository {
  Future<List<Room>> getAllRooms();
  Future<Room> getRoom(String roomId);
  Future<void> startSession({
    required String roomId,
    String? psType,
    bool? isMulti,
    double? hourlyRate,
  });

  Future<void> endSession(String roomId);
  Future<List<SessionHistory>> getRoomHistory(String roomId);
  Future<Map<String, dynamic>> getDashboardStats();
  Future<void> resetAllSessions();
  Future<void> clearAllHistory();
  Future<void> startNewDay();
}
