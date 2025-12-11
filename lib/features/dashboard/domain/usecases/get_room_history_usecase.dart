import 'package:quarto/features/dashboard/data/model/session_history_model.dart';
import 'package:quarto/features/dashboard/domain/repository/dashboard_repository.dart';

class GetRoomHistoryUsecase {
  final DashboardRepository repository;

  GetRoomHistoryUsecase({required this.repository});

  Future<List<SessionHistory>> call({required String roomId}) async {
    return repository.getRoomHistoryToday(roomId);
  }
}
