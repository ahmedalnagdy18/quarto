import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import 'package:quarto/features/dashboard/data/model/room_model.dart';
import 'package:quarto/features/dashboard/domain/usecases/add_orders_usecase.dart';
import 'package:quarto/features/dashboard/domain/usecases/get_all_rooms_usecase.dart';
import 'package:quarto/features/dashboard/domain/usecases/get_dashboard_stats_usecase.dart';
import 'package:quarto/features/dashboard/domain/usecases/start_session_usecase.dart';
import 'package:quarto/features/dashboard/domain/usecases/end_session_usecase.dart';

part 'rooms_state.dart';

class RoomsCubit extends Cubit<RoomsState> {
  final GetDashboardStatsUsecase getDashboardStatsUsecase;
  final GetAllRoomsUsecase getAllRoomsUsecase;
  final StartSessionUsecase startSessionUsecase;
  final EndSessionUsecase endSessionUsecase;
  final AddOrdersUsecase addOrdersUsecase;

  RoomsCubit({
    required this.getDashboardStatsUsecase,
    required this.getAllRoomsUsecase,
    required this.startSessionUsecase,
    required this.endSessionUsecase,
    required this.addOrdersUsecase,
  }) : super(RoomsInitial());

  Future<void> loadRoomsAndStats() async {
    emit(RoomsLoading());
    try {
      final stats = await getDashboardStatsUsecase();
      emit(
        RoomsLoaded(
          rooms: stats['rooms'] as List<Room>,
          stats: stats,
        ),
      );
    } catch (e) {
      emit(RoomsError(e.toString()));
    }
  }

  Future<void> startSession(
    String roomId, {
    String? psType,
    bool? isMulti,
    double? hourlyRate,
  }) async {
    try {
      await startSessionUsecase(
        roomId: roomId,
        psType: psType,
        isMulti: isMulti,
        hourlyRate: hourlyRate,
      );
      await loadRoomsAndStats();
    } catch (e) {
      emit(RoomsError(e.toString()));
    }
  }

  Future<void> endSession(String roomId) async {
    try {
      await endSessionUsecase(roomId: roomId);
      await loadRoomsAndStats();
    } catch (e) {
      emit(RoomsError(e.toString()));
    }
  }

  Future<void> refresh() async {
    await loadRoomsAndStats();
  }

  Future<void> addOrders(
    String roomId,
    List<OrderItem> orders, {
    String? sessionId,
  }) async {
    emit(RoomsLoading());
    try {
      await addOrdersUsecase(roomId, orders, sessionId: sessionId);
      emit(RoomOrdersAdded());
      await loadRoomsAndStats();
    } catch (e) {
      emit(RoomsError(e.toString()));
    }
  }
}
