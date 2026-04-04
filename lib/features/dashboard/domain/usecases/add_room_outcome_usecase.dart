import 'package:quarto/features/dashboard/data/model/room_outcomes_model.dart';
import 'package:quarto/features/dashboard/domain/repository/dashboard_repository.dart';

class AddRoomOutcomeUsecase {
  final DashboardRepository repository;

  AddRoomOutcomeUsecase({required this.repository});

  Future<void> call({required RoomOutcomesModel items}) async {
    await repository.addRoomOutcomesItems(items);
  }
}
