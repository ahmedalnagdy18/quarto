import 'package:quarto/features/dashboard/data/model/room_model.dart';
import 'package:quarto/features/dashboard/domain/repository/dashboard_repository.dart';

class AddOrdersUsecase {
  final DashboardRepository repository;

  AddOrdersUsecase({required this.repository});

  // ⭐ أضف sessionId parameter
  Future<void> call(
    String roomId,
    List<OrderItem> orders, {
    String? sessionId,
  }) async {
    if (orders.isEmpty) return;
    await repository.addOrders(roomId, orders, sessionId: sessionId);
  }
}
