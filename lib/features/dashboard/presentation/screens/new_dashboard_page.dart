import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quarto/core/colors/app_colors.dart';
import 'package:quarto/features/dashboard/presentation/cubits/dashboard/dashboard_cubit.dart';
import 'package:quarto/features/dashboard/presentation/cubits/rooms/rooms_cubit.dart';
import 'package:quarto/features/dashboard/presentation/screens/room_details_page.dart';
import 'package:quarto/features/dashboard/presentation/screens/rooms_outcomes_page.dart';
import 'package:quarto/features/dashboard/presentation/widgets/button_widget.dart';
import 'package:quarto/features/dashboard/presentation/widgets/card_widget.dart';

class NewDashboardPage extends StatefulWidget {
  const NewDashboardPage({super.key});

  @override
  State<NewDashboardPage> createState() => _NewDashboardPageState();
}

class _NewDashboardPageState extends State<NewDashboardPage> {
  @override
  void initState() {
    context.read<RoomsCubit>().loadRoomsAndStats();
    context.read<DashboardCubit>().loadDashboardStats();
    super.initState();
  }

  double? totalRevenue;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Padding(
        padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 30),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Image.asset(
                    'images/quarto_logo.png',
                    scale: 4,
                  ),
                  Spacer(),
                  ExportButtonsWidget(
                    title: 'Export rooms',
                    icon: Icons.download,
                    onPressed: () {},
                  ),
                  SizedBox(width: 20),
                  ExportButtonsWidget(
                    title: 'Outcomes',
                    icon: Icons.wallet,
                    onPressed: () {
                      Navigator.push(
                        context,
                        CupertinoPageRoute(
                          builder: (context) => RoomsOutcomesPage(
                            totalRevenue: totalRevenue ?? 0,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
              SizedBox(height: 40),
              Text(
                'Gaming Station',
                style: TextStyle(
                  fontSize: 20,
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 16),
              Text(
                'Manage your playStaion gaming lounge',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 30),
              BlocBuilder<DashboardCubit, DashboardState>(
                builder: (context, state) {
                  int freeRooms = 0;
                  int occupiedRooms = 0;
                  double todayIncome = 0.0;

                  if (state is DashboardLoaded) {
                    freeRooms = state.totalFreeRooms;
                    occupiedRooms = state.totalOccupiedRooms;
                    todayIncome = state.todayIncome;
                    totalRevenue = todayIncome;
                  }
                  return Row(
                    children: [
                      Expanded(
                        child: CardWidget(
                          data: "$freeRooms",
                          title: 'Free rooms',
                          state: state,
                        ),
                      ),
                      SizedBox(width: 20),
                      Expanded(
                        child: CardWidget(
                          data: "$occupiedRooms",
                          title: 'Occupied rooms',
                          state: state,
                        ),
                      ),
                      SizedBox(width: 20),
                      Expanded(
                        child: CardWidget(
                          data: '${todayIncome.toStringAsFixed(0)}\$',
                          title: 'Rooms income',
                          state: state,
                        ),
                      ),
                      SizedBox(width: 20),
                      Expanded(
                        child: CardWidget(
                          data: "1500\$",
                          title: 'Orders income',
                        ),
                      ),
                      SizedBox(width: 20),
                      Expanded(
                        child: CardWidget(
                          data: "20\$",
                          title: 'Outcomes',
                        ),
                      ),
                    ],
                  );
                },
              ),
              SizedBox(height: 30),
              Text(
                'Rooms',
                style: TextStyle(
                  fontSize: 20,
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 30),
              BlocListener<RoomsCubit, RoomsState>(
                listener: (context, state) {
                  if (state is RoomsLoaded) {
                    context.read<DashboardCubit>().loadDashboardStats();
                    //todo: add ==============
                  }
                },
                child: BlocBuilder<RoomsCubit, RoomsState>(
                  builder: (context, state) {
                    if (state is RoomsLoaded) {
                      return Wrap(
                        spacing: 15,
                        runSpacing: 15,
                        children: List.generate(
                          9, // عدد العناصر
                          (index) => GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                CupertinoPageRoute(
                                  builder: (context) => RoomDetailsPage(
                                    room: state.rooms[index],
                                  ),
                                ),
                              );
                            },
                            child: NewRoomCardWidget(
                              room: state.rooms[index],
                            ),
                          ),
                        ),
                      );
                    }
                    return Center(
                      child: CircularProgressIndicator(
                        color: AppColors.yellowColor,
                      ),
                    );
                  },
                ),
              ),
              SizedBox(height: 50),
            ],
          ),
        ),
      ),
    );
  }
}
