part of 'external_orders_cubit.dart';

@immutable
sealed class ExternalOrdersState {}

final class ExternalOrdersInitial extends ExternalOrdersState {}

class LoadingAddExternalOrders extends ExternalOrdersState {}

class SuccessAddExternalOrders extends ExternalOrdersState {}

class ErrorAddExternalOrders extends ExternalOrdersState {
  final String message;

  ErrorAddExternalOrders({required this.message});
}

class LoadingGetExternalOrders extends ExternalOrdersState {}

class SuccessGetExternalOrders extends ExternalOrdersState {
  final List<ExternalOrdersModel> data;

  SuccessGetExternalOrders({required this.data});
}

class ErrorGetExternalOrders extends ExternalOrdersState {
  final String message;

  ErrorGetExternalOrders({required this.message});
}

class LoadingDeleteExternalOrder extends ExternalOrdersState {}

class SuccessDeleteExternalOrder extends ExternalOrdersState {
  final List<ExternalOrdersModel>? updatedData;
  SuccessDeleteExternalOrder({this.updatedData});
}

class ErrorDeleteExternalOrder extends ExternalOrdersState {
  final String message;
  ErrorDeleteExternalOrder({required this.message});
}

class LoadingClearExternalOrders extends ExternalOrdersState {}

class SuccessClearExternalOrders extends ExternalOrdersState {}

class ErrorClearExternalOrders extends ExternalOrdersState {
  final String message;

  ErrorClearExternalOrders({required this.message});
}
