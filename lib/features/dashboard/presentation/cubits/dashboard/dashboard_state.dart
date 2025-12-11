// lib/features/dashboard/presentation/cubits/dashboard/dashboard_state.dart
part of 'dashboard_cubit.dart';

@immutable
sealed class DashboardState {}

class DashboardInitial extends DashboardState {}

class DashboardLoading extends DashboardState {}

class DashboardLoaded extends DashboardState {
  final int totalFreeRooms;
  final int totalOccupiedRooms;
  final double todayIncome;

  DashboardLoaded({
    required this.totalFreeRooms,
    required this.totalOccupiedRooms,
    required this.todayIncome,
  });
}

class DashboardError extends DashboardState {
  final String message;

  DashboardError(this.message);
}
