import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';
import 'package:quarto/features/dashboard/data/model/external_orders_model.dart';
import 'package:quarto/features/dashboard/domain/usecases/add_external_order_usecase.dart';
import 'package:quarto/features/dashboard/domain/usecases/clear_all_external_orders_usecase.dart';
import 'package:quarto/features/dashboard/domain/usecases/delete_external_order.dart';
import 'package:quarto/features/dashboard/domain/usecases/get_external_orders_usecase.dart';

part 'external_orders_state.dart';

class ExternalOrdersCubit extends Cubit<ExternalOrdersState> {
  final AddExternalOrderUsecase addExternalOrderUsecase;
  final GetExternalOrdersUsecase getExternalOrdersUsecase;
  final DeleteExternalOrder deleteExternalOrder;
  final ClearAllExternalOrdersUsecase clearAllExternalOrdersUsecase;
  ExternalOrdersCubit({
    required this.addExternalOrderUsecase,
    required this.getExternalOrdersUsecase,
    required this.deleteExternalOrder,
    required this.clearAllExternalOrdersUsecase,
  }) : super(ExternalOrdersInitial());

  Future<void> addExternalOrderFunc({
    required int price,
    required String order,
  }) async {
    emit(LoadingAddExternalOrders());
    try {
      await addExternalOrderUsecase(order: order, price: price);
      emit(
        SuccessAddExternalOrders(),
      );
    } catch (e) {
      emit(ErrorAddExternalOrders(message: e.toString()));
    }
  }

  Future<void> getExternalOrders() async {
    emit(LoadingGetExternalOrders());
    try {
      final data = await getExternalOrdersUsecase();
      emit(
        SuccessGetExternalOrders(data: data),
      );
    } catch (e) {
      emit(ErrorGetExternalOrders(message: e.toString()));
    }
  }

  Future<void> deleteOrderFunc(String id) async {
    emit(LoadingDeleteExternalOrder());
    try {
      await deleteExternalOrder(id);

      emit(SuccessDeleteExternalOrder());
    } catch (e) {
      emit(ErrorDeleteExternalOrder(message: e.toString()));
    }
  }

  Future<void> clearAllExternalOrders() async {
    emit(LoadingClearExternalOrders());
    try {
      await clearAllExternalOrdersUsecase();
      emit(
        SuccessClearExternalOrders(),
      );
    } catch (e) {
      emit(ErrorClearExternalOrders(message: e.toString()));
    }
  }
}
