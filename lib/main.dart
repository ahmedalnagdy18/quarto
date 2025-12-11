import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quarto/core/consts/app_const.dart';
import 'package:quarto/features/dashboard/presentation/cubits/dashboard/dashboard_cubit.dart';
import 'package:quarto/features/dashboard/presentation/cubits/rooms/rooms_cubit.dart';
import 'package:quarto/features/dashboard/presentation/cubits/session_history/session_history_cubit.dart';
import 'package:quarto/features/dashboard/presentation/screens/dashboard_page.dart';
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

  // لازم تستدعي init قبل تشغيل التطبيق
  await windowManager.ensureInitialized();

  WindowOptions windowOptions = const WindowOptions(
    size: Size(1000, 700),
    minimumSize: Size(950, 600), // 👈 هنا بتحدد أقل حجم ممكن
    center: true,
    backgroundColor: Colors.transparent,
  );

  await windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create:
              (context) => DashboardCubit(
                getDashboardStatsUsecase: sl(),
              ),
        ),
        BlocProvider(
          create:
              (context) => SessionHistoryCubit(
                getRoomHistoryUsecase: sl(),
              ),
        ),

        BlocProvider(
          create:
              (context) => RoomsCubit(
                getDashboardStatsUsecase: sl(),
                getAllRoomsUsecase: sl(),
                endSessionUsecase: sl(),
                startSessionUsecase: sl(),
              ),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        home: const DashboardPage(),
      ),
    );
  }
}
