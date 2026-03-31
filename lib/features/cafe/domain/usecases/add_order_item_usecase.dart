import 'package:quarto/features/cafe/data/model/order_item_model.dart';
import 'package:quarto/features/cafe/domain/repository/cafe_repository.dart';

class AddOrderItemsUseCase {
  final CafeRepository repository;

  AddOrderItemsUseCase({required this.repository});

  Future<void> call({required List<OrderItemModel> items}) async {
    await repository.addOrderItems(items);
  }
}
