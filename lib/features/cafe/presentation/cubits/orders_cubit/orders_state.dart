part of 'orders_cubit.dart';

sealed class OrdersState {}

final class OrdersInitial extends OrdersState {}

class LoadingAddOrder extends OrdersState {}

class SuccessAddOrder extends OrdersState {}

class ErrorAddOrder extends OrdersState {
  final String message;
  ErrorAddOrder({required this.message});
}

class LoadingGetOrders extends OrdersState {}

class SuccessGetOrders extends OrdersState {
  final List<OrderModel> orders;
  SuccessGetOrders({required this.orders});
}

class ErrorGetOrders extends OrdersState {
  final String message;
  ErrorGetOrders({required this.message});
}

class LoadingGetOrdersByTable extends OrdersState {}

class SuccessGetOrdersByTable extends OrdersState {
  final List<OrderModel> orders;
  SuccessGetOrdersByTable({required this.orders});
}

class ErrorGetOrdersByTable extends OrdersState {
  final String message;
  ErrorGetOrdersByTable({required this.message});
}
