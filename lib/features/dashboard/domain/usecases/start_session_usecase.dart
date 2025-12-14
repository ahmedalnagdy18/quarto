import 'package:quarto/features/dashboard/domain/repository/dashboard_repository.dart';

class StartSessionUsecase {
  final DashboardRepository repository;

  StartSessionUsecase({required this.repository});

  Future<void> call({
    required String roomId,
    String? psType,
    bool? isMulti,
    double? hourlyRate,
  }) async {
    return await repository.startSession(
      roomId: roomId,
      psType: psType,
      isMulti: isMulti,
      hourlyRate: hourlyRate,
    );
  }
}
