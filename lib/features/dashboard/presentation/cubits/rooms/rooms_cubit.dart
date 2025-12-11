import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';
import 'package:quarto/features/dashboard/data/model/room_model.dart';
import 'package:quarto/features/dashboard/domain/usecases/end_session_usecase.dart';
import 'package:quarto/features/dashboard/domain/usecases/get_all_rooms_usecase.dart';
import 'package:quarto/features/dashboard/domain/usecases/get_room_usecase.dart';
import 'package:quarto/features/dashboard/domain/usecases/start_session_usecase.dart';

part 'rooms_state.dart';

class RoomsCubit extends Cubit<RoomsState> {
  final GetAllRoomsUsecase getAllRoomsUsecase;
  final GetRoomUsecase getRoomUsecase;
  final StartSessionUsecase startSessionUsecase;
  final EndSessionUsecase endSessionUsecase;

  RoomsCubit({
    required this.getAllRoomsUsecase,
    required this.getRoomUsecase,
    required this.startSessionUsecase,
    required this.endSessionUsecase,
  }) : super(RoomsInitial());

  Future<void> loadRooms() async {
    emit(RoomsLoading());
    try {
      final rooms = await getAllRoomsUsecase();
      emit(RoomsLoaded(rooms));
    } catch (e) {
      emit(RoomsError(e.toString()));
    }
  }

  Future<void> startSession(String roomId) async {
    try {
      await startSessionUsecase(roomId: roomId);
      loadRooms(); // refresh after action
    } catch (e) {
      emit(RoomsError(e.toString()));
    }
  }

  Future<void> endSession(String roomId) async {
    try {
      await endSessionUsecase(roomId: roomId);
      loadRooms(); // refresh after action
    } catch (e) {
      emit(RoomsError(e.toString()));
    }
  }
}
