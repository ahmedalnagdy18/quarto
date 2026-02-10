import 'package:quarto/features/dashboard/domain/repository/dashboard_repository.dart';

class AddExternalOrderUsecase {
  final DashboardRepository repository;

  AddExternalOrderUsecase({required this.repository});

  Future<void> call({required int price, required String order}) async {
    await repository.addExternalOrders(order: order, price: price);
  }
}
