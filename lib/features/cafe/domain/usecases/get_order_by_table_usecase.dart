import 'package:quarto/features/cafe/data/model/order_model.dart';
import 'package:quarto/features/cafe/domain/repository/cafe_repository.dart';

class GetOrdersByTableUseCase {
  final CafeRepository repository;

  GetOrdersByTableUseCase({required this.repository});

  Future<List<OrderModel>> call({required String tableId}) async {
    return await repository.getOrdersByTable(tableId);
  }
}
