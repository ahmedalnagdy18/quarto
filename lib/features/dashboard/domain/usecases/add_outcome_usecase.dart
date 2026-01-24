import 'package:quarto/features/dashboard/domain/repository/dashboard_repository.dart';

class AddOutcomeUsecase {
  final DashboardRepository repository;

  AddOutcomeUsecase({required this.repository});

  Future<void> call({required int price, required String note}) async {
    await repository.addOutComes(note: note, price: price);
  }
}
