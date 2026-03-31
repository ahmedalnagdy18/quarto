import 'package:bloc/bloc.dart';
import 'package:quarto/features/cafe/data/model/order_model.dart';
import 'package:quarto/features/cafe/domain/usecases/add_order_usecase.dart';
import 'package:quarto/features/cafe/domain/usecases/get_order_by_table_usecase.dart';
import 'package:quarto/features/cafe/domain/usecases/get_order_usecase.dart';

part 'orders_state.dart';

class OrdersCubit extends Cubit<OrdersState> {
  final AddOrderUseCase addOrderUseCase;
  final GetOrdersUseCase getOrdersUseCase;
  final GetOrdersByTableUseCase getOrdersByTableUseCase;

  OrdersCubit({
    required this.addOrderUseCase,
    required this.getOrdersUseCase,
    required this.getOrdersByTableUseCase,
  }) : super(OrdersInitial());

  Future<void> addOrder(OrderModel order) async {
    emit(LoadingAddOrder());
    try {
      await addOrderUseCase(order: order);
      emit(SuccessAddOrder());
    } catch (e) {
      emit(ErrorAddOrder(message: e.toString()));
    }
  }

  Future<void> getOrders() async {
    emit(LoadingGetOrders());
    try {
      final orders = await getOrdersUseCase();
      emit(SuccessGetOrders(orders: orders));
    } catch (e) {
      emit(ErrorGetOrders(message: e.toString()));
    }
  }

  Future<void> getOrdersByTable(String tableId) async {
    emit(LoadingGetOrdersByTable());
    try {
      final orders = await getOrdersByTableUseCase(tableId: tableId);
      emit(SuccessGetOrdersByTable(orders: orders));
    } catch (e) {
      emit(ErrorGetOrdersByTable(message: e.toString()));
    }
  }
}
