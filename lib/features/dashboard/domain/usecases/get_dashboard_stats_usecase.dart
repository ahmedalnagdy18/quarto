import 'package:quarto/features/dashboard/domain/repository/dashboard_repository.dart';

class GetDashboardStatsUsecase {
  final DashboardRepository repository;

  GetDashboardStatsUsecase({required this.repository});

  Stream<Map<String, dynamic>> call() {
    return repository.getDashboardStats();
  }
}
