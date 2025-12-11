// lib/features/dashboard/presentation/cubits/rooms/rooms_cubit.dart
import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';
import 'package:quarto/features/dashboard/data/model/room_model.dart';
import 'package:quarto/features/dashboard/domain/usecases/get_all_rooms_usecase.dart';
import 'package:quarto/features/dashboard/domain/usecases/start_session_usecase.dart';
import 'package:quarto/features/dashboard/domain/usecases/end_session_usecase.dart';

part 'rooms_state.dart';

class RoomsCubit extends Cubit<RoomsState> {
  final GetAllRoomsUsecase getAllRoomsUsecase;
  final StartSessionUsecase startSessionUsecase;
  final EndSessionUsecase endSessionUsecase;

  Timer? _updateTimer;
  bool _isStreamActive = false;

  RoomsCubit({
    required this.getAllRoomsUsecase,
    required this.startSessionUsecase,
    required this.endSessionUsecase,
  }) : super(RoomsInitial()) {
    _startUpdateTimer();
  }

  @override
  Future<void> close() {
    _stopUpdateTimer();
    return super.close();
  }

  void _startUpdateTimer() {
    if (_isStreamActive) return;

    _updateTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state is RoomsLoaded) {
        _updateOccupiedRooms();
      }
    });
    _isStreamActive = true;
  }

  void _stopUpdateTimer() {
    _updateTimer?.cancel();
    _updateTimer = null;
    _isStreamActive = false;
  }

  void _updateOccupiedRooms() {
    if (state is! RoomsLoaded) return;

    final currentState = state as RoomsLoaded;
    final updatedRooms =
        currentState.rooms.map((room) {
          if (room.isOccupied && room.sessionStart != null) {
            return Room(
              id: room.id,
              name: room.name,
              isOccupied: room.isOccupied,
              sessionStart: room.sessionStart,
              hourlyRate: room.hourlyRate,
            );
          }
          return room;
        }).toList();

    emit(currentState.copyWith(rooms: updatedRooms));
  }

  Future<void> loadRooms() async {
    emit(RoomsLoading());
    try {
      final rooms = await getAllRoomsUsecase();
      emit(RoomsLoaded(rooms: rooms));
    } catch (e) {
      emit(RoomsError(e.toString()));
    }
  }

  Future<void> startSession(String roomId) async {
    try {
      await startSessionUsecase(roomId: roomId);
      await loadRooms(); // إعادة تحميل الغرف بعد البدء
    } catch (e) {
      emit(RoomsError(e.toString()));
    }
  }

  Future<void> endSession(String roomId) async {
    try {
      await endSessionUsecase(roomId: roomId);
      await loadRooms(); // إعادة تحميل الغرف بعد الانتهاء
    } catch (e) {
      emit(RoomsError(e.toString()));
    }
  }

  Future<void> refresh() async {
    await loadRooms();
  }
}
