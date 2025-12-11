import 'package:quarto/features/dashboard/data/model/room_model.dart';
import 'package:quarto/features/dashboard/domain/repository/dashboard_repository.dart';

class GetAllRoomsUsecase {
  final DashboardRepository repository;

  GetAllRoomsUsecase({required this.repository});

  Future<List<Room>> call() async {
    return repository.getAllRooms();
  }
}
