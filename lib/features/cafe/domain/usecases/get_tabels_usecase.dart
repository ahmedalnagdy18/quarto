import 'package:quarto/features/cafe/data/model/cafe_tabels_model.dart';
import 'package:quarto/features/cafe/domain/repository/cafe_repository.dart';

class GetTablesUseCase {
  final CafeRepository repository;

  GetTablesUseCase({required this.repository});

  Future<List<CafeTableModel>> call() async {
    return await repository.getTables();
  }
}
