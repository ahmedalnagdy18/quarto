import 'package:quarto/features/dashboard/data/model/room_model.dart';
import 'package:quarto/features/dashboard/domain/repository/dashboard_repository.dart';

class GetRoomUsecase {
  final DashboardRepository repository;

  GetRoomUsecase({required this.repository});

  Future<Room> call({required String roomId}) async {
    return repository.getRoom(roomId);
  }
}
