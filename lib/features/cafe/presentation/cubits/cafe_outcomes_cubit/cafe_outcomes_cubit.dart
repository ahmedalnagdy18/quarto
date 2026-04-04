import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import 'package:quarto/features/cafe/data/model/cafe_outcomes_model.dart';
import 'package:quarto/features/cafe/domain/usecases/add_cafe_outcomes_usecase.dart';
import 'package:quarto/features/cafe/domain/usecases/get_cafe_outcomes_usecase.dart';

part 'cafe_outcomes_state.dart';

class CafeOutcomesCubit extends Cubit<CafeOutcomesState> {
  final AddCafeOutcomesUsecase addCafeOutcomesUsecase;
  final GetCafeOutcomesUsecase getCafeOutcomesUsecase;

  CafeOutcomesCubit({
    required this.addCafeOutcomesUsecase,
    required this.getCafeOutcomesUsecase,
  }) : super(OutcomesInitial());

  Future<void> addOutCafecomesFunc({
    required CafeOutcomesModel items,
  }) async {
    emit(LoadingAddCafeOutcomes());
    try {
      await addCafeOutcomesUsecase(items: items);
      emit(
        SuccessAddCafeOutcomes(),
      );
    } catch (e) {
      emit(ErrorAddCafeOutcomes(message: e.toString()));
    }
  }

  Future<void> getCafeOutcomes() async {
    emit(LoadingGetCafeOutcomes());
    try {
      final data = await getCafeOutcomesUsecase();
      emit(
        SuccessGetCafeOutcomes(data: data),
      );
    } catch (e) {
      emit(ErrorGetCafeOutcomes(message: e.toString()));
    }
  }
}
