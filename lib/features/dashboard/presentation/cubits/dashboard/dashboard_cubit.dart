import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import 'package:quarto/features/dashboard/domain/usecases/get_dashboard_stats_usecase.dart';
import 'package:quarto/features/dashboard/domain/usecases/start_new_day_usecase.dart';

part 'dashboard_state.dart';

class DashboardCubit extends Cubit<DashboardState> {
  final GetDashboardStatsUsecase getDashboardStatsUsecase;
  final StartNewDayUsecase startNewDayUsecase;

  DashboardCubit({
    required this.getDashboardStatsUsecase,
    required this.startNewDayUsecase,
  }) : super(DashboardInitial());

  Future<void> loadDashboardStats() async {
    emit(DashboardLoading());
    try {
      final stats = await getDashboardStatsUsecase();
      emit(
        DashboardLoaded(
          totalFreeRooms: stats['freeRooms'] as int? ?? 0,
          totalOccupiedRooms: stats['occupiedRooms'] as int? ?? 0,
          roomsIncome: stats['roomsIncome'] as double? ?? 0.0,
          ordersIncome: stats['ordersIncome'] as double? ?? 0.0,
          totalIncome: stats['todayIncome'] as double? ?? 0.0,
        ),
      );
    } catch (e) {
      emit(DashboardError(e.toString()));
    }
  }

  Future<void> startNewDay() async {
    emit(DashboardLoading());
    try {
      await startNewDayUsecase();

      emit(
        DashboardLoaded(
          totalFreeRooms: 0,
          totalOccupiedRooms: 0,
          roomsIncome: 0.0,
          ordersIncome: 0.0,
          totalIncome: 0.0,
        ),
      );
    } catch (e) {
      emit(DashboardError(e.toString()));
    }
  }
}
