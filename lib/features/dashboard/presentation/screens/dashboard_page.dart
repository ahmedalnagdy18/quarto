import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quarto/core/colors/app_colors.dart';
import 'package:quarto/core/common/app_loading_widget.dart';
import 'package:quarto/core/extentions/app_extentions.dart';
import 'package:quarto/core/fonts/app_text.dart';
import 'package:quarto/features/dashboard/data/model/room_model.dart';
import 'package:quarto/features/dashboard/data/model/session_history_model.dart';
import 'package:quarto/features/dashboard/presentation/cubits/dashboard/dashboard_cubit.dart';
import 'package:quarto/features/dashboard/presentation/cubits/rooms/rooms_cubit.dart';
import 'package:quarto/features/dashboard/presentation/cubits/session_history/session_history_cubit.dart';
import 'package:quarto/features/dashboard/presentation/widgets/room_card_widget.dart';
import 'package:quarto/features/dashboard/presentation/widgets/start_new_day_widget.dart';

// Add this helper class
class StartNewDayDialog extends StatefulWidget {
  final BuildContext parentContext;

  const StartNewDayDialog({super.key, required this.parentContext});

  @override
  State<StartNewDayDialog> createState() => _StartNewDayDialogState();
}

class _StartNewDayDialogState extends State<StartNewDayDialog> {
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _startNewDay();
  }

  Future<void> _startNewDay() async {
    // 🔹 Extract everything from context BEFORE await
    final dashboardCubit = widget.parentContext.read<DashboardCubit>();
    final roomsCubit = widget.parentContext.read<RoomsCubit>();
    final sessionHistoryCubit =
        widget.parentContext.read<SessionHistoryCubit>();

    final parentState =
        widget.parentContext.findAncestorStateOfType<_DashboardPageState>();

    try {
      await dashboardCubit.startNewDay();
      await roomsCubit.refresh();

      if (parentState != null && parentState._selectedRoom != null) {
        await sessionHistoryCubit.loadRoomHistory(
          parentState._selectedRoom!.id,
        );
      }

      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _error = null;
      });

      // Auto-close after 1 second
      Future.delayed(const Duration(seconds: 1), () {
        if (!mounted) return;
        Navigator.pop(widget.parentContext);
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.bgDark,
      content:
          _isLoading
              ? const Row(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(width: 16),
                  Text(
                    'Starting new day...',
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              )
              : _error != null
              ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error, color: Colors.red, size: 40),
                  const SizedBox(height: 16),
                  Text(
                    _error!,
                    style: const TextStyle(color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                ],
              )
              : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.check_circle, color: Colors.green, size: 40),
                  const SizedBox(height: 16),
                  const Text(
                    'New day started successfully!',
                    style: TextStyle(color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
      actions:
          _error != null
              ? [
                TextButton(
                  onPressed: () => Navigator.pop(widget.parentContext),
                  child: const Text(
                    'OK',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ]
              : null,
    );
  }
}

class _RoomDetailsStreamBuilder extends StatelessWidget {
  final Room room;
  final Widget Function(BuildContext, Room) builder;

  const _RoomDetailsStreamBuilder({
    required this.room,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    // Just call the builder directly without streaming
    return builder(context, room);
  }
}

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  Room? _selectedRoom;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DashboardCubit>().loadDashboardStats();
      context.read<RoomsCubit>().loadRoomsAndStats();
    });
  }

  void _selectRoom(Room room) {
    setState(() {
      _selectedRoom = room;
    });
    context.read<SessionHistoryCubit>().loadRoomHistory(room.id);
  }

  double _calculateTotalForSelectedRoom(List<SessionHistory> history) {
    try {
      double total = 0.0;
      for (var session in history) {
        if (session.endTime != null) {
          total += session.totalCost;
        }
      }
      return total;
    } catch (e) {
      print('Error calculating total: $e');
      return 0.0;
    }
  }

  String _formatTime(DateTime? time) {
    return TimeFormatter.formatTo12Hour(time);
  }

  void _showStartNewDayDialog(BuildContext context) {
    showDialog(context: context, builder: (context) => StartNewDayWidget());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgCard,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(top: 30, right: 30),
        child: FloatingActionButton.extended(
          onPressed: () => _showStartNewDayDialog(context),
          backgroundColor: AppColors.bgDark,
          foregroundColor: Colors.white,
          elevation: 4,
          label: const Text('Start New Day'),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: RefreshIndicator(
        onRefresh: () async {
          // 🔹 Read from context BEFORE any await
          final dashboardCubit = context.read<DashboardCubit>();
          final roomsCubit = context.read<RoomsCubit>();
          final sessionHistoryCubit = context.read<SessionHistoryCubit>();

          await dashboardCubit.loadDashboardStats();
          await roomsCubit.refresh();

          if (_selectedRoom != null) {
            await sessionHistoryCubit.loadRoomHistory(
              _selectedRoom!.id,
            );
          }
        },
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 30),
            child: BlocListener<RoomsCubit, RoomsState>(
              listener: (context, state) {
                if (state is RoomsLoaded) {
                  // فقط عند تغييرات مهمة، ليس كل تحديث
                  final prevState = context.read<DashboardCubit>().state;
                  if (prevState is DashboardLoaded) {
                    final newFree =
                        state.rooms.where((r) => !r.isOccupied).length;
                    final newOccupied =
                        state.rooms.where((r) => r.isOccupied).length;

                    // تحديث فقط إذا تغيرت الأرقام
                    if (newFree != prevState.totalFreeRooms ||
                        newOccupied != prevState.totalOccupiedRooms) {
                      context.read<DashboardCubit>().updateStatsFromRooms(
                        state.rooms,
                      );
                    }
                  }
                }
              },
              child: Column(
                children: [
                  _buildStatisticsContainer(),
                  const SizedBox(height: 20),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _buildRoomsContainer()),
                      const SizedBox(width: 20),
                      Expanded(child: _buildRoomDetailsContainer()),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatisticsContainer() {
    return BlocBuilder<DashboardCubit, DashboardState>(
      builder: (context, state) {
        int freeRooms = 0;
        int occupiedRooms = 0;
        double todayIncome = 0.0;

        if (state is DashboardLoaded) {
          freeRooms = state.totalFreeRooms;
          occupiedRooms = state.totalOccupiedRooms;
          todayIncome = state.todayIncome;
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          height: 140,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: AppColors.bgDark,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatColumn("Total Free Rooms", freeRooms.toString(), state),
              _buildStatColumn(
                "Total Occupied Rooms",
                occupiedRooms.toString(),
                state,
              ),
              _buildStatColumn(
                "Today Income",
                "${todayIncome.toStringAsFixed(0)} \$",
                state,
              ),
              IconButton(
                onPressed: () {
                  context.read<DashboardCubit>().loadDashboardStats();
                  context.read<RoomsCubit>().refresh();
                  if (_selectedRoom != null) {
                    context.read<SessionHistoryCubit>().loadRoomHistory(
                      _selectedRoom!.id,
                    );
                  }
                },
                icon: Icon(Icons.refresh),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatColumn(String title, String value, DashboardState state) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(title, style: AppTexts.smallHeading),
        const SizedBox(height: 12),
        if (state is DashboardLoading)
          const AppLoadingWidget()
        else if (state is DashboardError)
          Text("Error", style: AppTexts.largeHeading)
        else
          Text(value, style: AppTexts.largeHeading),
      ],
    );
  }

  Widget _buildRoomsContainer() {
    return BlocConsumer<RoomsCubit, RoomsState>(
      listener: (context, state) {
        if (state is RoomsLoaded &&
            _selectedRoom == null &&
            state.rooms.isNotEmpty) {
          _selectRoom(state.rooms.first);
        }
      },
      builder: (context, state) {
        return Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: AppColors.bgDark,
          ),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  _buildRoomsContent(state),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildRoomsContent(RoomsState state) {
    if (state is RoomsLoading) {
      return const Center(child: AppLoadingWidget());
    } else if (state is RoomsError) {
      return Center(child: Text("Error: ${state.message}"));
    } else if (state is RoomsLoaded) {
      return _buildRoomsGrid(state.rooms);
    } else {
      return const Center(child: AppLoadingWidget());
    }
  }

  Widget _buildRoomsGrid(List<Room> rooms) {
    return Wrap(
      alignment: WrapAlignment.start,
      crossAxisAlignment: WrapCrossAlignment.start,
      spacing: 12,
      runSpacing: 12,
      children: rooms.map((room) => _buildRoomCard(room)).toList(),
    );
  }

  Widget _buildRoomCard(Room room) {
    return RoomCardWidget(
      room: room,
      isSelected: _selectedRoom?.id == room.id,
      onTap: () => _selectRoom(room),
      onEndSession: () {
        context.read<RoomsCubit>().endSession(room.id);
      },
      onStartSession: ({
        String? psType,
        bool? isMulti,
        double? hourlyRate,
      }) async {
        await context.read<RoomsCubit>().startSession(
          room.id,
          psType: psType,
          isMulti: isMulti,
          hourlyRate: hourlyRate,
        );
      },
    );
  }

  Widget _buildRoomDetailsContainer() {
    if (_selectedRoom == null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: AppColors.bgDark,
        ),
        child: const Center(
          child: Text(
            "Select a room to view details",
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    return _RoomDetailsStreamBuilder(
      room: _selectedRoom!,
      builder: (context, liveRoom) {
        return BlocBuilder<SessionHistoryCubit, SessionHistoryState>(
          builder: (context, state) {
            List<SessionHistory> history = [];
            if (state is SessionHistoryLoaded) {
              history = state.history;
            }

            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: AppColors.bgDark,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "${liveRoom.name} - DETAILS",
                    style: AppTexts.smallHeading,
                  ),
                  const SizedBox(height: 20),

                  // Current Session with live updates
                  _buildLiveSessionInfo(liveRoom),
                  const SizedBox(height: 20),

                  // Today History
                  Text("Today History", style: AppTexts.meduimBody),
                  const SizedBox(height: 12),
                  _buildHistoryContent(state, history),
                  const SizedBox(height: 12),

                  // Total of day
                  _buildTotalDay(history),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildLiveSessionInfo(Room room) {
    // Remove StreamBuilder, just show static info
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Current Session", style: AppTexts.meduimBody),
        const SizedBox(height: 12),
        Text("Start Time", style: AppTexts.smallBody),
        const SizedBox(height: 6),
        Text(
          room.isOccupied
              ? _formatTime(room.sessionStart)
              : "No active session",
          style: AppTexts.meduimBody,
        ),
        const SizedBox(height: 12),
        Text("Timer", style: AppTexts.smallBody),
        const SizedBox(height: 6),
        Text(
          room.isOccupied ? room.liveDuration : "0h 0m",
          style: AppTexts.meduimBody,
        ),
        const SizedBox(height: 8),
        if (room.isOccupied) ...[
          Text("Current Cost", style: AppTexts.smallBody),
          const SizedBox(height: 6),
          Text(
            "${room.calculatedCost.toStringAsFixed(0)} \$",
            style: AppTexts.meduimBody.copyWith(
              color: AppColors.primaryBlue,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildHistoryContent(
    SessionHistoryState state,
    List<SessionHistory> history,
  ) {
    if (state is SessionHistoryLoading) {
      return const Center(child: AppLoadingWidget());
    } else if (state is SessionHistoryError) {
      return Text("Error: ${state.message}", style: AppTexts.smallBody);
    } else if (history.isEmpty) {
      return const Text(
        "No history today",
        style: TextStyle(color: Colors.grey),
      );
    } else {
      return _buildHistoryTable(history);
    }
  }

  Widget _buildHistoryTable(List<SessionHistory> history) {
    return DataTable(
      dataTextStyle: const TextStyle(color: Colors.white),
      headingTextStyle: const TextStyle(color: Colors.white),
      border: TableBorder.all(color: AppColors.borderLight),
      headingRowColor: MaterialStateProperty.all(AppColors.borderColor),
      columnSpacing: 20,
      horizontalMargin: 12,
      columns: const [
        DataColumn(label: Text("#")),
        DataColumn(label: Text("Start")),
        DataColumn(label: Text("End")),
        DataColumn(label: Text("Duration")),
        DataColumn(label: Text("Cost")),
      ],
      rows:
          history.asMap().entries.map((entry) {
            final index = entry.key;
            final session = entry.value;
            return DataRow(
              cells: [
                DataCell(Text("${index + 1}")),
                DataCell(Text(session.startTimeShort)),
                DataCell(
                  Text(
                    session.endTime != null ? session.endTimeShort : "Running",
                  ),
                ),
                DataCell(Text(session.formattedDuration)),
                DataCell(Text("${session.totalCost.toStringAsFixed(0)} \$")),
              ],
            );
          }).toList(),
    );
  }

  Widget _buildTotalDay(List<SessionHistory> history) {
    final total = _calculateTotalForSelectedRoom(history);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.bgCardLight,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text("Total of day:", style: AppTexts.meduimBody),
          Text(
            "${total.toStringAsFixed(0)} \$",
            style: AppTexts.largeHeading.copyWith(color: AppColors.primaryBlue),
          ),
        ],
      ),
    );
  }
}
