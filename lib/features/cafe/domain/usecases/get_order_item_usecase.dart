import 'package:quarto/features/cafe/data/model/order_item_model.dart';
import 'package:quarto/features/cafe/domain/repository/cafe_repository.dart';

class GetOrderItemsUseCase {
  final CafeRepository repository;

  GetOrderItemsUseCase({required this.repository});

  Future<List<OrderItemModel>> call({required String orderId}) async {
    return await repository.getOrderItems(orderId);
  }
}
