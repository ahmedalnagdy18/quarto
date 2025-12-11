part of 'session_history_cubit.dart';

@immutable
sealed class SessionHistoryState {}

class SessionHistoryInitial extends SessionHistoryState {}

class SessionHistoryLoading extends SessionHistoryState {}

class SessionHistoryLoaded extends SessionHistoryState {
  final List<SessionHistory> history;

  SessionHistoryLoaded(this.history);
}

class SessionHistoryError extends SessionHistoryState {
  final String message;

  SessionHistoryError(this.message);
}
