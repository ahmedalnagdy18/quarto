import 'package:quarto/features/dashboard/domain/repository/dashboard_repository.dart';

class StartNewDayUsecase {
  final DashboardRepository repository;

  StartNewDayUsecase({required this.repository});

  Future<void> call() async {
    return await repository.startNewDay();
  }
}
