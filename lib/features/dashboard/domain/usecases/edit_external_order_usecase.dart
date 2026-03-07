import 'package:quarto/features/dashboard/domain/repository/dashboard_repository.dart';

class EditExternalOrderUsecase {
  final DashboardRepository repository;

  EditExternalOrderUsecase({required this.repository});

  Future<void> call({
    required String id,
    required int price,
    required String order,
    required bool payment,
  }) async {
    await repository.editExternalOrders(
      id: id,
      order: order,
      price: price,
      payment: payment,
    );
  }
}
