import 'package:quarto/features/dashboard/domain/repository/dashboard_repository.dart';

class EndSessionUsecase {
  final DashboardRepository repository;

  EndSessionUsecase({required this.repository});

  Future<void> call({required String roomId}) async {
    return await repository.endSession(roomId);
  }
}
