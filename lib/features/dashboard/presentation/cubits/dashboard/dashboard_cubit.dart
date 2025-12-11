// lib/features/dashboard/presentation/cubits/dashboard/dashboard_cubit.dart
import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';
import 'package:quarto/features/dashboard/domain/repository/dashboard_repository.dart';
import 'dart:async';

part 'dashboard_state.dart';

class DashboardCubit extends Cubit<DashboardState> {
  final DashboardRepository repository;
  StreamSubscription<Map<String, dynamic>>? _statsSubscription;

  DashboardCubit({
    required this.repository,
  }) : super(DashboardInitial()) {
    // بدء الاستماع للتحديثات فور إنشاء الكيوبت
    _startListening();
  }

  void _startListening() {
    // إلغاء أي اشتراك سابق
    _statsSubscription?.cancel();

    // البدء في الاستماع لـ stream
    _statsSubscription = repository.getDashboardStats().listen(
      (stats) {
        emit(
          DashboardLoaded(
            totalFreeRooms: stats['freeRooms'] as int? ?? 0,
            totalOccupiedRooms: stats['occupiedRooms'] as int? ?? 0,
            todayIncome: stats['todayIncome'] as double? ?? 0.0,
          ),
        );
      },
      onError: (error) {
        emit(DashboardError(error.toString()));
      },
    );
  }

  // إعادة تحميل البيانات يدوياً (اختياري)
  Future<void> reloadStats() async {
    emit(DashboardLoading());
    // سيعود Stream تلقائياً إلى التحديث
  }

  @override
  Future<void> close() {
    _statsSubscription?.cancel();
    return super.close();
  }
}
