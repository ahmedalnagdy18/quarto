import 'package:quarto/features/dashboard/data/model/room_outcomes_model.dart';
import 'package:quarto/features/dashboard/domain/repository/dashboard_repository.dart';

class GetRoomOutcomesUsecase {
  final DashboardRepository repository;

  GetRoomOutcomesUsecase({required this.repository});

  Future<List<RoomOutcomesModel>> call() async {
    return repository.getRoomOutcomesItems();
  }
}
