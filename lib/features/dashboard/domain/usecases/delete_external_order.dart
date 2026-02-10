import 'package:quarto/features/dashboard/domain/repository/dashboard_repository.dart';

class DeleteExternalOrder {
  final DashboardRepository repository;

  DeleteExternalOrder({required this.repository});

  Future<void> call(String id) async {
    return repository.deleteExternalOrder(id);
  }
}
