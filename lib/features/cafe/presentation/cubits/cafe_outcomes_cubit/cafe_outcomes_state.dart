part of 'cafe_outcomes_cubit.dart';

@immutable
sealed class CafeOutcomesState {}

final class OutcomesInitial extends CafeOutcomesState {}

// Add cafe outcomes
class LoadingAddCafeOutcomes extends CafeOutcomesState {}

class SuccessAddCafeOutcomes extends CafeOutcomesState {}

class ErrorAddCafeOutcomes extends CafeOutcomesState {
  final String message;

  ErrorAddCafeOutcomes({required this.message});
}

// get cafe outcomes
class LoadingGetCafeOutcomes extends CafeOutcomesState {}

class SuccessGetCafeOutcomes extends CafeOutcomesState {
  final List<CafeOutcomesModel> data;

  SuccessGetCafeOutcomes({required this.data});
}

class ErrorGetCafeOutcomes extends CafeOutcomesState {
  final String message;

  ErrorGetCafeOutcomes({required this.message});
}
