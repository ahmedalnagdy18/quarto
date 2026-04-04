import 'package:quarto/features/cafe/data/model/cafe_outcomes_model.dart';
import 'package:quarto/features/cafe/domain/repository/cafe_repository.dart';

class GetCafeOutcomesUsecase {
  final CafeRepository repository;

  GetCafeOutcomesUsecase({required this.repository});

  Future<List<CafeOutcomesModel>> call() async {
    return await repository.getCafeOutcomesItems();
  }
}
