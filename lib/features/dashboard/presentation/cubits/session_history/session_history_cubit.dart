import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import 'package:quarto/features/dashboard/data/model/session_history_model.dart';
import 'package:quarto/features/dashboard/domain/usecases/get_room_history_usecase.dart';

part 'session_history_state.dart';

class SessionHistoryCubit extends Cubit<SessionHistoryState> {
  final GetRoomHistoryUsecase getRoomHistoryUsecase;

  SessionHistoryCubit({
    required this.getRoomHistoryUsecase,
  }) : super(SessionHistoryInitial());

  Future<void> loadRoomHistory(String roomId) async {
    emit(SessionHistoryLoading());
    try {
      final history = await getRoomHistoryUsecase(roomId: roomId);
      emit(SessionHistoryLoaded(history));
    } catch (e) {
      emit(SessionHistoryError(e.toString()));
    }
  }
}
