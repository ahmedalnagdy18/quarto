import 'package:get_it/get_it.dart';
import 'package:quarto/features/dashboard/data/repository_imp/dashboard_repository_imp.dart';
import 'package:quarto/features/dashboard/domain/repository/dashboard_repository.dart';
import 'package:quarto/features/dashboard/domain/usecases/add_external_order_usecase.dart';
import 'package:quarto/features/dashboard/domain/usecases/add_orders_usecase.dart';
import 'package:quarto/features/dashboard/domain/usecases/add_outcome_usecase.dart';
import 'package:quarto/features/dashboard/domain/usecases/clear_all_external_orders_usecase.dart';
import 'package:quarto/features/dashboard/domain/usecases/clear_all_outcomes_usecase.dart';
import 'package:quarto/features/dashboard/domain/usecases/delete_external_order.dart';
import 'package:quarto/features/dashboard/domain/usecases/delete_outcome_usecase.dart';
import 'package:quarto/features/dashboard/domain/usecases/end_session_usecase.dart';
import 'package:quarto/features/dashboard/domain/usecases/get_all_rooms_usecase.dart';
import 'package:quarto/features/dashboard/domain/usecases/get_dashboard_stats_usecase.dart';
import 'package:quarto/features/dashboard/domain/usecases/get_external_orders_usecase.dart';
import 'package:quarto/features/dashboard/domain/usecases/get_outcomes_usecase.dart';
import 'package:quarto/features/dashboard/domain/usecases/get_room_history_usecase.dart';
import 'package:quarto/features/dashboard/domain/usecases/get_room_usecase.dart';
import 'package:quarto/features/dashboard/domain/usecases/start_new_day_usecase.dart';
import 'package:quarto/features/dashboard/domain/usecases/start_session_usecase.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final sl = GetIt.instance;

Future<void> init() async {
  // 1. Supabase Client
  sl.registerLazySingleton<SupabaseClient>(() => Supabase.instance.client);

  // 2. Repository
  sl.registerLazySingleton<DashboardRepository>(
    () => DashboardRepositoryImp(supabase: sl()),
  );

  // 3. Usecases
  sl.registerLazySingleton<EndSessionUsecase>(
    () => EndSessionUsecase(repository: sl()),
  );
  sl.registerLazySingleton<GetAllRoomsUsecase>(
    () => GetAllRoomsUsecase(repository: sl()),
  );
  sl.registerLazySingleton<GetDashboardStatsUsecase>(
    () => GetDashboardStatsUsecase(repository: sl()),
  );
  sl.registerLazySingleton<GetRoomHistoryUsecase>(
    () => GetRoomHistoryUsecase(repository: sl()),
  );
  sl.registerLazySingleton<GetRoomUsecase>(
    () => GetRoomUsecase(repository: sl()),
  );
  sl.registerLazySingleton<StartSessionUsecase>(
    () => StartSessionUsecase(repository: sl()),
  );
  sl.registerLazySingleton<StartNewDayUsecase>(
    () => StartNewDayUsecase(repository: sl()),
  );
  sl.registerLazySingleton<AddOrdersUsecase>(
    () => AddOrdersUsecase(repository: sl()),
  );
  sl.registerLazySingleton<AddOutcomeUsecase>(
    () => AddOutcomeUsecase(repository: sl()),
  );
  sl.registerLazySingleton<GetOutcomesUsecase>(
    () => GetOutcomesUsecase(repository: sl()),
  );

  sl.registerLazySingleton<DeleteOutcomeUsecase>(
    () => DeleteOutcomeUsecase(repository: sl()),
  );
  sl.registerLazySingleton<AddExternalOrderUsecase>(
    () => AddExternalOrderUsecase(repository: sl()),
  );
  sl.registerLazySingleton<GetExternalOrdersUsecase>(
    () => GetExternalOrdersUsecase(repository: sl()),
  );
  sl.registerLazySingleton<DeleteExternalOrder>(
    () => DeleteExternalOrder(repository: sl()),
  );
  sl.registerLazySingleton<ClearAllExternalOrdersUsecase>(
    () => ClearAllExternalOrdersUsecase(repository: sl()),
  );
  sl.registerLazySingleton<ClearAllOutcomesUsecase>(
    () => ClearAllOutcomesUsecase(repository: sl()),
  );
}
