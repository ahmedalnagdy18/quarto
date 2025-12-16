import 'package:quarto/features/dashboard/domain/repository/dashboard_repository.dart';

class ClearTodayHistoryUsecase {
  final DashboardRepository repository;

  ClearTodayHistoryUsecase({required this.repository});

  Future<void> call() async {
    return await repository.clearAllHistory();
  }
}
