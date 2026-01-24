import 'package:quarto/features/dashboard/domain/repository/dashboard_repository.dart';

class DeleteOutcomeUsecase {
  final DashboardRepository repository;

  DeleteOutcomeUsecase({required this.repository});

  Future<void> call(String id) async {
    return repository.deleteOutComesData(id);
  }
}
