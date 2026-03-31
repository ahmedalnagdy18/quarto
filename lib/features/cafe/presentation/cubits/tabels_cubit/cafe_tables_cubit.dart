import 'package:bloc/bloc.dart';
import 'package:quarto/features/cafe/data/model/cafe_tabels_model.dart';
import 'package:quarto/features/cafe/domain/usecases/get_tabels_usecase.dart';
import 'package:quarto/features/cafe/domain/usecases/update_tabels_stutes_usecase.dart';

part 'cafe_tables_state.dart';

class CafeTablesCubit extends Cubit<CafeTablesState> {
  final GetTablesUseCase getTablesUseCase;
  final UpdateTableStatusUseCase updateTableStatusUseCase;

  CafeTablesCubit({
    required this.getTablesUseCase,
    required this.updateTableStatusUseCase,
  }) : super(CafeTablesInitial());

  Future<void> getTables() async {
    emit(LoadingGetTables());
    try {
      final tables = await getTablesUseCase();
      emit(SuccessGetTables(tables: tables));
    } catch (e) {
      emit(ErrorGetTables(message: e.toString()));
    }
  }

  Future<void> updateTableStatus(String tableId, bool isOccupied) async {
    emit(LoadingUpdateTableStatus());
    try {
      await updateTableStatusUseCase(tableId: tableId, isOccupied: isOccupied);
      emit(SuccessUpdateTableStatus());
    } catch (e) {
      emit(ErrorUpdateTableStatus(message: e.toString()));
    }
  }
}
