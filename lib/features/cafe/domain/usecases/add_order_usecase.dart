import 'package:quarto/features/cafe/data/model/order_model.dart';
import 'package:quarto/features/cafe/domain/repository/cafe_repository.dart';

class AddOrderUseCase {
  final CafeRepository repository;

  AddOrderUseCase({required this.repository});

  Future<String> call({required OrderModel order}) async {
    return await repository.addOrder(order);
  }
}
