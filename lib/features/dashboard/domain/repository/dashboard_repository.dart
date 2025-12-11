import 'package:quarto/features/dashboard/data/model/room_model.dart';
import 'package:quarto/features/dashboard/data/model/session_history_model.dart';

abstract class DashboardRepository {
  Future<List<Room>> getAllRooms();
  Future<Room> getRoom(String roomId);
  Future<void> startSession(String roomId);
  Future<void> endSession(String roomId);
  Future<List<SessionHistory>> getRoomHistoryToday(String roomId);
  Stream<Map<String, dynamic>> getDashboardStats();
}
