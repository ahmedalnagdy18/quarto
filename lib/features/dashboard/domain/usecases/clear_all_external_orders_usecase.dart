import 'package:quarto/features/dashboard/domain/repository/dashboard_repository.dart';

class ClearAllExternalOrdersUsecase {
  final DashboardRepository repository;

  ClearAllExternalOrdersUsecase({required this.repository});

  Future<void> call() async {
    return await repository.clearAllExternalOrders();
  }
}
