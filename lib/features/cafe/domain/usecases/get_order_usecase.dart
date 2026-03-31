import 'package:quarto/features/cafe/data/model/order_model.dart';
import 'package:quarto/features/cafe/domain/repository/cafe_repository.dart';

class GetOrdersUseCase {
  final CafeRepository repository;

  GetOrdersUseCase({required this.repository});

  Future<List<OrderModel>> call() async {
    return await repository.getOrders();
  }
}
