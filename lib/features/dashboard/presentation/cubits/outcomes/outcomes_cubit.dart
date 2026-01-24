import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import 'package:quarto/features/dashboard/data/model/outcomes_model.dart';
import 'package:quarto/features/dashboard/domain/usecases/add_outcome_usecase.dart';
import 'package:quarto/features/dashboard/domain/usecases/delete_outcome_usecase.dart';
import 'package:quarto/features/dashboard/domain/usecases/get_outcomes_usecase.dart';

part 'outcomes_state.dart';

class OutcomesCubit extends Cubit<OutcomesState> {
  final AddOutcomeUsecase addOutcomeUsecase;
  final GetOutcomesUsecase getOutcomesUsecase;
  final DeleteOutcomeUsecase deleteOutcomeUsecase;
  OutcomesCubit({
    required this.addOutcomeUsecase,
    required this.getOutcomesUsecase,
    required this.deleteOutcomeUsecase,
  }) : super(OutcomesInitial());

  Future<void> addOutcomesFunc({
    required int price,
    required String note,
  }) async {
    emit(LoadingAddOutcomes());
    try {
      await addOutcomeUsecase(note: note, price: price);
      emit(
        SuccessAddOutcomes(),
      );
    } catch (e) {
      emit(ErrorAddOutcomes(message: e.toString()));
    }
  }

  Future<void> getOutcomes() async {
    emit(LoadingGetOutcomes());
    try {
      final data = await getOutcomesUsecase();
      emit(
        SuccessGetOutcomes(data: data),
      );
    } catch (e) {
      emit(ErrorGetOutcomes(message: e.toString()));
    }
  }

  Future<void> deleteOutcome(String id) async {
    emit(LoadingDeleteOutcome());
    try {
      await deleteOutcomeUsecase(id);

      emit(SuccessDeleteOutcome());
    } catch (e) {
      emit(ErrorDeleteOutcome(message: e.toString()));
    }
  }
}
