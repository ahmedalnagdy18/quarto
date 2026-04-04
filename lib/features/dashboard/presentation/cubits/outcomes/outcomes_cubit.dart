import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import 'package:quarto/features/dashboard/data/model/room_outcomes_model.dart';
import 'package:quarto/features/dashboard/domain/usecases/add_room_outcome_usecase.dart';
import 'package:quarto/features/dashboard/domain/usecases/get_room_outcomes_usecase.dart';

part 'outcomes_state.dart';

class RoomOutcomesCubit extends Cubit<RoomOutcomesState> {
  final AddRoomOutcomeUsecase addRoomOutcomeUsecase;
  final GetRoomOutcomesUsecase getRoomOutcomesUsecase;
  RoomOutcomesCubit({
    required this.addRoomOutcomeUsecase,
    required this.getRoomOutcomesUsecase,
  }) : super(OutcomesInitial());

  Future<void> addRoomOutcomesFunc({
    required RoomOutcomesModel items,
  }) async {
    emit(LoadingAddOutcomes());
    try {
      await addRoomOutcomeUsecase(items: items);
      emit(
        SuccessAddOutcomes(),
      );
    } catch (e) {
      emit(ErrorAddOutcomes(message: e.toString()));
    }
  }

  Future<void> getRoomOutcomes() async {
    emit(LoadingGetOutcomes());
    try {
      final data = await getRoomOutcomesUsecase();
      emit(
        SuccessGetOutcomes(data: data),
      );
    } catch (e) {
      emit(ErrorGetOutcomes(message: e.toString()));
    }
  }
}
