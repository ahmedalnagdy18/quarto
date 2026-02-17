part of 'outcomes_cubit.dart';

@immutable
sealed class OutcomesState {}

final class OutcomesInitial extends OutcomesState {}

class LoadingAddOutcomes extends OutcomesState {}

class SuccessAddOutcomes extends OutcomesState {}

class ErrorAddOutcomes extends OutcomesState {
  final String message;

  ErrorAddOutcomes({required this.message});
}

class LoadingGetOutcomes extends OutcomesState {}

class SuccessGetOutcomes extends OutcomesState {
  final List<OutcomesModel> data;

  SuccessGetOutcomes({required this.data});
}

class ErrorGetOutcomes extends OutcomesState {
  final String message;

  ErrorGetOutcomes({required this.message});
}

class LoadingDeleteOutcome extends OutcomesState {}

class SuccessDeleteOutcome extends OutcomesState {
  final List<OutcomesModel>? updatedData;
  SuccessDeleteOutcome({this.updatedData});
}

class ErrorDeleteOutcome extends OutcomesState {
  final String message;
  ErrorDeleteOutcome({required this.message});
}

class LoadingClearAllOutcomes extends OutcomesState {}

class SuccessClearAllOutcomes extends OutcomesState {}

class ErrorClearAllOutcomes extends OutcomesState {
  final String message;

  ErrorClearAllOutcomes({required this.message});
}
