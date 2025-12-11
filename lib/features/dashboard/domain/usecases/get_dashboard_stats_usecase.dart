import 'package:quarto/features/dashboard/domain/repository/dashboard_repository.dart';

class GetDashboardStatsUsecase {
  final DashboardRepository repository;

  GetDashboardStatsUsecase({required this.repository});

  Future<Map<String, dynamic>> call() async {
    return repository.getDashboardStats();
  }
}
