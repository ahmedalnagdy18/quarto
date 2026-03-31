import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quarto/core/consts/app_const.dart';
import 'package:quarto/features/cafe/presentation/cubits/order_items_cubit/order_items_cubit.dart';
import 'package:quarto/features/cafe/presentation/cubits/orders_cubit/orders_cubit.dart';
import 'package:quarto/features/cafe/presentation/cubits/tabels_cubit/cafe_tables_cubit.dart';
import 'package:quarto/features/dashboard/presentation/cubits/dashboard/dashboard_cubit.dart';
import 'package:quarto/features/dashboard/presentation/cubits/outcomes/outcomes_cubit.dart';
import 'package:quarto/features/dashboard/presentation/cubits/rooms/rooms_cubit.dart';
import 'package:quarto/features/dashboard/presentation/cubits/session_history/session_history_cubit.dart';
import 'package:quarto/features/dashboard/presentation/screens/main_app_page.dart';
import 'package:quarto/injection_container.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:window_manager/window_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1️⃣ initialize Firebase
  await Supabase.initialize(
    url: dbUrl,
    anonKey: anonKey,
  );

  // 2️⃣ initialize DI (GetIt)
  await init();
  final isMobile =
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.android);

  if (!isMobile) {
    if (!kIsWeb) {
      //  لازم تستدعي init قبل تشغيل التطبيق
      await windowManager.ensureInitialized();

      WindowOptions windowOptions = const WindowOptions(
        size: Size(1200, 700),
        minimumSize: Size(1200, 700), // 👈 هنا بتحدد أقل حجم ممكن
        center: true,
        backgroundColor: Colors.transparent,
      );

      await windowManager.waitUntilReadyToShow(windowOptions, () async {
        await windowManager.show();
        await windowManager.focus();
      });
    }
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => DashboardCubit(
            startNewDayUsecase: sl(),
            getDashboardStatsUsecase: sl(),
          ),
        ),
        BlocProvider(
          create: (context) => SessionHistoryCubit(
            getRoomHistoryUsecase: sl(),
            addCommentUsecase: sl(),
          ),
        ),
        BlocProvider(
          create: (context) => OutcomesCubit(
            addOutcomeUsecase: sl(),
            getOutcomesUsecase: sl(),
            deleteOutcomeUsecase: sl(),
            clearAllOutcomesUsecase: sl(),
          ),
        ),
        BlocProvider(
          create: (context) => RoomsCubit(
            addOrdersUsecase: sl(),
            getDashboardStatsUsecase: sl(),
            getAllRoomsUsecase: sl(),
            endSessionUsecase: sl(),
            startSessionUsecase: sl(),
          ),
        ),
        BlocProvider(
          create: (context) => CafeTablesCubit(
            getTablesUseCase: sl(),
            updateTableStatusUseCase: sl(),
          ),
        ),
        BlocProvider(
          create: (context) => OrdersCubit(
            addOrderUseCase: sl(),
            getOrdersByTableUseCase: sl(),
            getOrdersUseCase: sl(),
          ),
        ),
        BlocProvider(
          create: (context) => OrderItemsCubit(
            addOrderItemsUseCase: sl(),
            getOrderItemsUseCase: sl(),
          ),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        home: const MainAppPage(),
      ),
    );
  }
}
