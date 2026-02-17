import 'package:quarto/features/dashboard/domain/repository/dashboard_repository.dart';

class ClearAllOutcomesUsecase {
  final DashboardRepository repository;

  ClearAllOutcomesUsecase({required this.repository});

  Future<void> call() async {
    return await repository.clearAllOutComes();
  }
}
