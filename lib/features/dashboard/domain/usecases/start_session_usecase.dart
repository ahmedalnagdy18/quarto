import 'package:quarto/features/dashboard/domain/repository/dashboard_repository.dart';

class StartSessionUsecase {
  final DashboardRepository repository;

  StartSessionUsecase({required this.repository});

  Future<void> call({required String roomId}) async {
    return repository.startSession(roomId);
  }
}
