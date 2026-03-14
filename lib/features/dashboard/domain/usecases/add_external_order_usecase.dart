import 'package:quarto/features/dashboard/data/model/external_orders_model.dart';
import 'package:quarto/features/dashboard/domain/repository/dashboard_repository.dart';

class AddExternalOrderUsecase {
  final DashboardRepository repository;

  AddExternalOrderUsecase({required this.repository});

  Future<void> call({required ExternalOrdersModel externalOrdersModel}) async {
    await repository.addExternalOrders(externalOrdersModel);
  }
}
