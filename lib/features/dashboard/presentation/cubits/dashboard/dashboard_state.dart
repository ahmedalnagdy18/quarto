part of 'dashboard_cubit.dart';

@immutable
sealed class DashboardState {}

class DashboardInitial extends DashboardState {}

class DashboardLoading extends DashboardState {}

class DashboardLoaded extends DashboardState {
  final int totalFreeRooms;
  final int totalOccupiedRooms;
  final double roomsIncome;
  final double ordersIncome;
  final double roomCashTotal;
  final double roomVisaTotal;
  final double totalIncome;

  DashboardLoaded({
    required this.totalFreeRooms,
    required this.totalOccupiedRooms,
    required this.roomsIncome,
    required this.ordersIncome,
    required this.roomCashTotal,
    required this.roomVisaTotal,
    required this.totalIncome,
  });
}

class DashboardError extends DashboardState {
  final String message;

  DashboardError(this.message);
}
