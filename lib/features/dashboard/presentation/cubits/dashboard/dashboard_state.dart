part of 'dashboard_cubit.dart';

@immutable
sealed class DashboardState {}

class DashboardInitial extends DashboardState {}

class DashboardLoading extends DashboardState {}

class DashboardLoaded extends DashboardState {
  final Map<String, dynamic> stats;
  DashboardLoaded(this.stats);
}

class DashboardError extends DashboardState {
  final String message;
  DashboardError(this.message);
}
