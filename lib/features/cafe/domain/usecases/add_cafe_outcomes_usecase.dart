import 'package:quarto/features/cafe/data/model/cafe_outcomes_model.dart';
import 'package:quarto/features/cafe/domain/repository/cafe_repository.dart';

class AddCafeOutcomesUsecase {
  final CafeRepository repository;

  AddCafeOutcomesUsecase({required this.repository});

  Future<void> call({required CafeOutcomesModel items}) async {
    await repository.addCafeOutcomesItems(items);
  }
}
