import 'package:quarto/features/cafe/domain/repository/cafe_repository.dart';

class UpdateTableStatusUseCase {
  final CafeRepository repository;

  UpdateTableStatusUseCase({required this.repository});

  Future<void> call({
    required String tableId,
    required bool isOccupied,
  }) async {
    await repository.updateTableStatus(tableId, isOccupied);
  }
}
