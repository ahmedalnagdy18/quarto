import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quarto/core/colors/app_colors.dart';
import 'package:quarto/core/fonts/app_text.dart';
import 'package:quarto/features/dashboard/data/model/room_model.dart';
import 'package:quarto/features/dashboard/data/model/session_history_model.dart';
import 'package:quarto/features/dashboard/presentation/cubits/dashboard/dashboard_cubit.dart';
import 'package:quarto/features/dashboard/presentation/cubits/rooms/rooms_cubit.dart';
import 'package:quarto/features/dashboard/presentation/cubits/session_history/session_history_cubit.dart';

// RoomCardWidget مع التحديث الحي
class RoomCardWidget extends StatefulWidget {
  final Room room;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onToggleStatus;

  const RoomCardWidget({
    Key? key,
    required this.room,
    required this.isSelected,
    required this.onTap,
    required this.onToggleStatus,
  }) : super(key: key);

  @override
  State<RoomCardWidget> createState() => _RoomCardWidgetState();
}

class _RoomCardWidgetState extends State<RoomCardWidget> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // بدء التايمر فقط إذا كانت الغرفة مشغولة
    if (widget.room.isOccupied) {
      _startTimer();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          // إعادة البناء للتحديث - لا حاجة لتغيير أي شيء، فقط إعادة build
        });
      }
    });
  }

  @override
  void didUpdateWidget(RoomCardWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    // إذا تغيرت حالة الغرفة من/إلى مشغولة
    if (oldWidget.room.isOccupied != widget.room.isOccupied) {
      if (widget.room.isOccupied) {
        _startTimer();
      } else {
        _timer?.cancel();
        _timer = null;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color:
              widget.isSelected
                  ? AppColors.primaryBlue.withOpacity(0.2)
                  : AppColors.bgCardLight,
          border: Border.all(
            color:
                widget.isSelected ? AppColors.primaryBlue : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(widget.room.name, style: AppTexts.smallHeading),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color:
                        widget.room.isOccupied
                            ? Colors.deepOrange
                            : AppColors.statusFree.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    widget.room.isOccupied ? "Occupied" : "Free",
                    style: AppTexts.smallBody.copyWith(
                      color:
                          widget.room.isOccupied
                              ? Colors.white
                              : AppColors.statusFree,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            if (!widget.room.isOccupied)
              const SizedBox(height: 40)
            else ...[
              // تظهر البيانات الحية فقط للغرف المشغولة
              StreamBuilder<int>(
                stream: Stream.periodic(const Duration(seconds: 1), (i) => i),
                builder: (context, snapshot) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Start: ${_formatTime(widget.room.sessionStart)}",
                        style: AppTexts.smallBody,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Live Duration: ${widget.room.liveDuration}",
                        style: AppTexts.smallBody,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Current Cost: ${widget.room.calculatedCost.toStringAsFixed(0)} ₪",
                        style: AppTexts.smallBody,
                      ),
                    ],
                  );
                },
              ),
            ],

            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      widget.room.isOccupied
                          ? Colors.red
                          : AppColors.primaryBlue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: widget.onToggleStatus,
                child: Text(
                  widget.room.isOccupied ? "End Session" : "Start Session",
                  style: AppTexts.smallBody.copyWith(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime? time) {
    if (time == null) return "--:--";
    final localTime = time.toLocal();
    final hour = localTime.hour.toString().padLeft(2, '0');
    final minute = localTime.minute.toString().padLeft(2, '0');
    return "$hour:$minute";
  }
}

// Stream Builder للغرفة المحددة في التفاصيل
class _RoomDetailsStreamBuilder extends StatelessWidget {
  final Room room;
  final Widget Function(BuildContext, Room) builder;

  const _RoomDetailsStreamBuilder({
    required this.room,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<int>(
      stream: Stream.periodic(const Duration(seconds: 1), (i) => i),
      builder: (context, snapshot) {
        return builder(context, room);
      },
    );
  }
}

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  String _selectedTab = "Today";
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
    if (time == null) return "--:--";
    final localTime = time.toLocal();
    final hour = localTime.hour.toString().padLeft(2, '0');
    final minute = localTime.minute.toString().padLeft(2, '0');
    return "$hour:$minute";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgCard,
      body: RefreshIndicator(
        onRefresh: () async {
          await context.read<DashboardCubit>().loadDashboardStats();
          await context.read<RoomsCubit>().refresh();
          if (_selectedRoom != null) {
            await context.read<SessionHistoryCubit>().loadRoomHistory(
              _selectedRoom!.id,
            );
          }
        },
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 30),
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
                "${todayIncome.toStringAsFixed(0)} ₪",
                state,
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
          const CircularProgressIndicator()
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
                  _buildTabs(),
                  Divider(color: AppColors.borderLight),
                  const SizedBox(height: 8),
                  _buildRoomsContent(state),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTabs() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildTab("Today"),
        _buildTab("Yesterday"),
        _buildTab("Custom Date"),
      ],
    );
  }

  Widget _buildTab(String title) {
    return GestureDetector(
      onTap: () => setState(() => _selectedTab = title),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        decoration: BoxDecoration(
          color:
              _selectedTab == title
                  ? AppColors.primaryBlue
                  : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          title,
          style: AppTexts.meduimBody.copyWith(
            color: _selectedTab == title ? Colors.white : Colors.grey,
          ),
        ),
      ),
    );
  }

  Widget _buildRoomsContent(RoomsState state) {
    if (state is RoomsLoading) {
      return const Center(child: CircularProgressIndicator());
    } else if (state is RoomsError) {
      return Center(child: Text("Error: ${state.message}"));
    } else if (state is RoomsLoaded) {
      return _buildRoomsGrid(state.rooms);
    } else {
      return const Center(child: CircularProgressIndicator());
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
      onToggleStatus: () {
        if (room.isOccupied) {
          context.read<RoomsCubit>().endSession(room.id);
        } else {
          context.read<RoomsCubit>().startSession(room.id);
        }
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
    return StreamBuilder<int>(
      stream: Stream.periodic(const Duration(seconds: 1), (i) => i),
      builder: (context, snapshot) {
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
                "${room.calculatedCost.toStringAsFixed(0)} ₪",
                style: AppTexts.meduimBody.copyWith(
                  color: AppColors.primaryBlue,
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildHistoryContent(
    SessionHistoryState state,
    List<SessionHistory> history,
  ) {
    if (state is SessionHistoryLoading) {
      return const Center(child: CircularProgressIndicator());
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
                DataCell(Text("${session.totalCost.toStringAsFixed(0)} ₪")),
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
            "${total.toStringAsFixed(0)} ₪",
            style: AppTexts.largeHeading.copyWith(color: AppColors.primaryBlue),
          ),
        ],
      ),
    );
  }
}
