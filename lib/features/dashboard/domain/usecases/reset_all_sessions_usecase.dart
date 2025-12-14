import 'package:quarto/features/dashboard/domain/repository/dashboard_repository.dart';

class ResetAllSessionsUsecase {
  final DashboardRepository repository;

  ResetAllSessionsUsecase({required this.repository});

  Future<void> call() async {
    return await repository.resetAllSessions();
  }
}
