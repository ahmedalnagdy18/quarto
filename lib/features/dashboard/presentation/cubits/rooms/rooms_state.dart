// lib/features/dashboard/presentation/cubits/rooms/rooms_state.dart
part of 'rooms_cubit.dart';

@immutable
sealed class RoomsState {}

class RoomsInitial extends RoomsState {}

class RoomsLoading extends RoomsState {}

class RoomsLoaded extends RoomsState {
  final List<Room> rooms;

  RoomsLoaded({required this.rooms});

  RoomsLoaded copyWith({
    List<Room>? rooms,
  }) {
    return RoomsLoaded(
      rooms: rooms ?? this.rooms,
    );
  }
}

class RoomsError extends RoomsState {
  final String message;

  RoomsError(this.message);
}
