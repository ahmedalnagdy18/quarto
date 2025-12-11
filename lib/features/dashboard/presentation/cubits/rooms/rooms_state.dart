// lib/features/dashboard/presentation/cubits/rooms/rooms_state.dart
part of 'rooms_cubit.dart';

@immutable
sealed class RoomsState {}

class RoomsInitial extends RoomsState {}

class RoomsLoading extends RoomsState {}

class RoomsLoaded extends RoomsState {
  final List<Room> rooms;
  final Map<String, dynamic> stats;

  RoomsLoaded({
    required this.rooms,
    required this.stats,
  });

  RoomsLoaded copyWith({
    List<Room>? rooms,
    Map<String, dynamic>? stats,
  }) {
    return RoomsLoaded(
      rooms: rooms ?? this.rooms,
      stats: stats ?? this.stats,
    );
  }
}

class RoomsError extends RoomsState {
  final String message;

  RoomsError(this.message);
}
