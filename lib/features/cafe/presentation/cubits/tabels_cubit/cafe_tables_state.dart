part of 'cafe_tables_cubit.dart';

sealed class CafeTablesState {}

final class CafeTablesInitial extends CafeTablesState {}

class LoadingGetTables extends CafeTablesState {}

class SuccessGetTables extends CafeTablesState {
  final List<CafeTableModel> tables;
  SuccessGetTables({required this.tables});
}

class ErrorGetTables extends CafeTablesState {
  final String message;
  ErrorGetTables({required this.message});
}

class LoadingUpdateTableStatus extends CafeTablesState {}

class SuccessUpdateTableStatus extends CafeTablesState {}

class ErrorUpdateTableStatus extends CafeTablesState {
  final String message;
  ErrorUpdateTableStatus({required this.message});
}
