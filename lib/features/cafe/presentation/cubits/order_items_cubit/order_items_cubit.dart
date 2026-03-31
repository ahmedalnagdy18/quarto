import 'package:bloc/bloc.dart';
import 'package:flutter/cupertino.dart';
import 'package:quarto/features/cafe/data/model/order_item_model.dart';
import 'package:quarto/features/cafe/domain/usecases/add_order_item_usecase.dart';
import 'package:quarto/features/cafe/domain/usecases/get_order_item_usecase.dart';

part 'order_items_state.dart';

class OrderItemsCubit extends Cubit<OrderItemsState> {
  final AddOrderItemsUseCase addOrderItemsUseCase;
  final GetOrderItemsUseCase getOrderItemsUseCase;

  OrderItemsCubit({
    required this.addOrderItemsUseCase,
    required this.getOrderItemsUseCase,
  }) : super(OrderItemsInitial());

  Future<void> addOrderItems(List<OrderItemModel> items) async {
    emit(LoadingAddOrderItems());
    try {
      await addOrderItemsUseCase(items: items);
      emit(SuccessAddOrderItems());
    } catch (e) {
      emit(ErrorAddOrderItems(message: e.toString()));
    }
  }

  Future<void> getOrderItems(String orderId) async {
    emit(LoadingGetOrderItems());
    try {
      final items = await getOrderItemsUseCase(orderId: orderId);
      emit(SuccessGetOrderItems(items: items));
    } catch (e) {
      emit(ErrorGetOrderItems(message: e.toString()));
    }
  }
}
