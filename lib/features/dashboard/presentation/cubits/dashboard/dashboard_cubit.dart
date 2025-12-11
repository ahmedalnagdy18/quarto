import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';
import 'package:quarto/features/dashboard/domain/usecases/get_dashboard_stats_usecase.dart';

part 'dashboard_state.dart';

class DashboardCubit extends Cubit<DashboardState> {
  final GetDashboardStatsUsecase getDashboardStatsUsecase;

  DashboardCubit({required this.getDashboardStatsUsecase})
    : super(DashboardInitial());

  Future<void> loadDashboardStats() async {
    emit(DashboardLoading());
    try {
      final stats = await getDashboardStatsUsecase();
      emit(DashboardLoaded(stats));
    } catch (e) {
      emit(DashboardError(e.toString()));
    }
  }
}
