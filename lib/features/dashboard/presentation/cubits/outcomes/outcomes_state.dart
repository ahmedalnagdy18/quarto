part of 'outcomes_cubit.dart';

@immutable
sealed class RoomOutcomesState {}

final class OutcomesInitial extends RoomOutcomesState {}

class LoadingAddOutcomes extends RoomOutcomesState {}

class SuccessAddOutcomes extends RoomOutcomesState {}

class ErrorAddOutcomes extends RoomOutcomesState {
  final String message;

  ErrorAddOutcomes({required this.message});
}

class LoadingGetOutcomes extends RoomOutcomesState {}

class SuccessGetOutcomes extends RoomOutcomesState {
  final List<RoomOutcomesModel> data;

  SuccessGetOutcomes({required this.data});
}

class ErrorGetOutcomes extends RoomOutcomesState {
  final String message;

  ErrorGetOutcomes({required this.message});
}
