import 'package:quarto/features/dashboard/data/model/external_orders_model.dart';
import 'package:quarto/features/dashboard/data/model/room_outcomes_model.dart';
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
  Future<void> moveRoomSession({
    required String fromRoomId,
    required String toRoomId,
  });
  Future<List<SessionHistory>> getRoomHistory(String roomId);
  Future<Map<String, dynamic>> getDashboardStats();
  Future<void> resetAllSessions();
  Future<void> clearAllHistory();
  Future<void> startNewDay();
  Future<void> addOrders(
    String roomId,
    List<OrderItem> orders, {
    String? sessionId,
  });

  Future<void> addRoomOutcomesItems(RoomOutcomesModel items);
  Future<List<RoomOutcomesModel>> getRoomOutcomesItems();

  Future<void> addExternalOrders(ExternalOrdersModel externalOrdersModel);
  Future<List<ExternalOrdersModel>> getExternalOrders();
  Future<void> deleteExternalOrder(String id);
  Future<void> clearAllExternalOrders();
  Future<void> addComments(String comments, String roomId, {String? sessionId});
  Future<void> editExternalOrders(ExternalOrdersModel externalOrdersModel);
}
