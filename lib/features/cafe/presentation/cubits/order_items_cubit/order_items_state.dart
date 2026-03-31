part of 'order_items_cubit.dart';

@immutable
sealed class OrderItemsState {}

final class OrderItemsInitial extends OrderItemsState {}

class LoadingAddOrderItems extends OrderItemsState {}

class SuccessAddOrderItems extends OrderItemsState {}

class ErrorAddOrderItems extends OrderItemsState {
  final String message;
  ErrorAddOrderItems({required this.message});
}

class LoadingGetOrderItems extends OrderItemsState {}

class SuccessGetOrderItems extends OrderItemsState {
  final List<OrderItemModel> items;
  SuccessGetOrderItems({required this.items});
}

class ErrorGetOrderItems extends OrderItemsState {
  final String message;
  ErrorGetOrderItems({required this.message});
}
