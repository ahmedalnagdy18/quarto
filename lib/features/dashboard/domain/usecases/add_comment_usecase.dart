import 'package:quarto/features/dashboard/domain/repository/dashboard_repository.dart';

class AddCommentUsecase {
  final DashboardRepository repository;

  AddCommentUsecase({required this.repository});

  Future<void> call(String comments, String roomId, {String? sessionId}) async {
    await repository.addComments(comments, roomId, sessionId: sessionId);
  }
}
