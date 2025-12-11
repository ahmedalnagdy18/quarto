import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quarto/core/colors/app_colors.dart';
import 'package:quarto/core/fonts/app_text.dart';
import 'package:quarto/features/dashboard/presentation/cubits/dashboard/dashboard_cubit.dart';
import 'package:quarto/features/dashboard/presentation/cubits/rooms/rooms_cubit.dart';
import 'package:quarto/features/dashboard/presentation/cubits/session_history/session_history_cubit.dart';
import 'package:quarto/features/dashboard/data/model/room_model.dart';
import 'package:quarto/features/dashboard/data/model/session_history_model.dart';

class TestPage extends StatefulWidget {
  const TestPage({super.key});

  @override
  State<TestPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<TestPage> {
  Room? selectedRoom;

  @override
  void initState() {
    super.initState();
    context.read<DashboardCubit>().loadDashboardStats();
    context.read<RoomsCubit>().loadRooms();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgCard,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 30),
        child: Column(
          children: [
            // ------------------- DASHBOARD STATS -------------------
            BlocBuilder<DashboardCubit, DashboardState>(
              builder: (context, state) {
                if (state is DashboardLoading) {
                  return const Center(child: CircularProgressIndicator());
                } else if (state is DashboardLoaded) {
                  final stats = state.stats;
                  return _statsContainer(
                    freeRooms: (stats["freeRooms"] ?? 0).toInt(),
                    occupiedRooms: (stats["occupiedRooms"] ?? 0).toInt(),
                    todayIncome: (stats["todayIncome"] ?? 0).toInt(),
                  );
                } else if (state is DashboardError) {
                  return Text(state.message, style: AppTexts.smallBody);
                }
                return const SizedBox();
              },
            ),
            const SizedBox(height: 20),

            // ------------------- ROOMS + DETAILS -------------------
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ------------------- ROOMS CARDS -------------------
                Expanded(
                  child: BlocBuilder<RoomsCubit, RoomsState>(
                    builder: (context, state) {
                      if (state is RoomsLoading) {
                        return const Center(child: CircularProgressIndicator());
                      } else if (state is RoomsLoaded) {
                        final rooms = state.rooms;
                        return _roomsList(
                          rooms: rooms,
                          onRoomSelected: (room) {
                            setState(() {
                              selectedRoom = room;
                            });
                            context.read<SessionHistoryCubit>().loadRoomHistory(
                              room.id,
                            );
                          },
                        );
                      } else if (state is RoomsError) {
                        return Text(state.message, style: AppTexts.smallBody);
                      }
                      return const SizedBox();
                    },
                  ),
                ),
                const SizedBox(width: 20),

                // ------------------- ROOM DETAILS -------------------
                Expanded(
                  child:
                      selectedRoom == null
                          ? const Center(
                            child: Text("Select a room to view details"),
                          )
                          : BlocBuilder<
                            SessionHistoryCubit,
                            SessionHistoryState
                          >(
                            builder: (context, state) {
                              List<SessionHistory> history = [];
                              if (state is SessionHistoryLoaded) {
                                history = state.history;
                              }
                              return _roomDetails(selectedRoom!, history);
                            },
                          ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ------------------- STATS -------------------
  Widget _statsContainer({
    required int freeRooms,
    required int occupiedRooms,
    required int todayIncome,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      height: 140,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: AppColors.bgDark,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _statItem("Total Free Rooms", freeRooms.toString()),
          _statItem("Total Occupied Rooms", occupiedRooms.toString()),
          _statItem("Today Incomes", todayIncome.toString()),
        ],
      ),
    );
  }

  Widget _statItem(String title, String value) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(title, style: AppTexts.smallHeading),
        const SizedBox(height: 12),
        Text(value, style: AppTexts.largeHeading),
      ],
    );
  }

  // ------------------- ROOMS -------------------
  Widget _roomsList({
    required List<Room> rooms,
    required Function(Room) onRoomSelected,
  }) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: AppColors.bgDark,
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children:
            rooms
                .map(
                  (room) => _roomCard(
                    room: room,
                    onTap: () => onRoomSelected(room),
                  ),
                )
                .toList(),
      ),
    );
  }

  Widget _roomCard({required Room room, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: AppColors.bgCardLight,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(room.name, style: AppTexts.smallHeading),
            const SizedBox(height: 4),
            Text(
              room.isOccupied ? "Occupied" : "Free",
              style: AppTexts.meduimBody.copyWith(
                color:
                    room.isOccupied ? Colors.deepOrange : AppColors.statusFree,
              ),
            ),
            const SizedBox(height: 12),
            MaterialButton(
              shape: ContinuousRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              minWidth: 150,
              onPressed: () {
                if (room.isOccupied) {
                  context.read<RoomsCubit>().endSession(room.id);
                } else {
                  context.read<RoomsCubit>().startSession(room.id);
                }
              },
              color: room.isOccupied ? Colors.red : AppColors.primaryBlue,
              child: Text(
                room.isOccupied
                    ? "End Session (\$${room.currentSessionCost.toStringAsFixed(0)})"
                    : "Start Session",
                style: AppTexts.smallBody,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ------------------- ROOM DETAILS -------------------
  Widget _roomDetails(Room room, List<SessionHistory> history) {
    final totalIncome = history.fold<double>(
      0,
      (sum, h) => sum + h.totalCost,
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: AppColors.bgDark,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("${room.name} - Details", style: AppTexts.smallHeading),
          const SizedBox(height: 20),
          if (room.isOccupied) ...[
            Text("Current Session", style: AppTexts.meduimBody),
            const SizedBox(height: 12),
            Text(
              "Start Time: ${room.sessionStartShort}",
              style: AppTexts.smallBody,
            ),
            const SizedBox(height: 6),
            Text(
              "Timer: ${room.currentSessionDuration.inHours}h ${room.currentSessionDuration.inMinutes.remainder(60)}m",
              style: AppTexts.smallBody,
            ),
            const SizedBox(height: 20),
          ],
          Text("Today History", style: AppTexts.meduimBody),
          const SizedBox(height: 12),
          DataTable(
            dataTextStyle: const TextStyle(color: Colors.white),
            headingTextStyle: const TextStyle(color: Colors.white),
            border: TableBorder.all(color: AppColors.borderLight),
            columns: const [
              DataColumn(label: Text("#")),
              DataColumn(label: Text("Start")),
              DataColumn(label: Text("End")),
              DataColumn(label: Text("Duration")),
              DataColumn(label: Text("Cost")),
            ],
            rows: List.generate(history.length, (i) {
              final h = history[i];
              return DataRow(
                cells: [
                  DataCell(Text("${i + 1}")),
                  DataCell(Text(h.startTimeShort)),
                  DataCell(Text(h.endTimeShort)),
                  DataCell(Text(h.formattedDuration)),
                  DataCell(Text(h.totalCost.toStringAsFixed(0))),
                ],
              );
            }),
          ),
          const SizedBox(height: 12),
          Text(
            "Total of day: ${totalIncome.toStringAsFixed(0)}",
            style: const TextStyle(color: Colors.white),
          ),
        ],
      ),
    );
  }
}
