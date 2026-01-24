import 'package:quarto/features/dashboard/data/model/outcomes_model.dart';
import 'package:quarto/features/dashboard/domain/repository/dashboard_repository.dart';

class GetOutcomesUsecase {
  final DashboardRepository repository;

  GetOutcomesUsecase({required this.repository});

  Future<List<OutcomesModel>> call() async {
    return repository.outComesData();
  }
}
