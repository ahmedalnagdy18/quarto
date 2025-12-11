part of 'rooms_cubit.dart';

@immutable
sealed class RoomsState {}

class RoomsInitial extends RoomsState {}

class RoomsLoading extends RoomsState {}

class RoomsLoaded extends RoomsState {
  final List<Room> rooms;
  RoomsLoaded(this.rooms);
}

class RoomLoading extends RoomsState {}

class RoomLoaded extends RoomsState {
  final Room room;
  RoomLoaded(this.room);
}

class RoomsError extends RoomsState {
  final String message;
  RoomsError(this.message);
}
