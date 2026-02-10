import 'package:quarto/features/dashboard/data/model/external_orders_model.dart';
import 'package:quarto/features/dashboard/domain/repository/dashboard_repository.dart';

class GetExternalOrdersUsecase {
  final DashboardRepository repository;

  GetExternalOrdersUsecase({required this.repository});

  Future<List<ExternalOrdersModel>> call() async {
    return repository.getExternalOrders();
  }
}
