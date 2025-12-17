import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quarto/core/colors/app_colors.dart';
import 'package:quarto/core/common/app_loading_widget.dart';
import 'package:quarto/core/fonts/app_text.dart';
import 'package:quarto/features/dashboard/data/model/room_model.dart';
import 'package:quarto/features/dashboard/data/model/session_history_model.dart';
import 'package:quarto/features/dashboard/presentation/cubits/dashboard/dashboard_cubit.dart';
import 'package:quarto/features/dashboard/presentation/cubits/rooms/rooms_cubit.dart';
import 'package:quarto/features/dashboard/presentation/cubits/session_history/session_history_cubit.dart';
import 'package:quarto/features/dashboard/presentation/screens/history_details_page.dart';
import 'package:quarto/features/dashboard/presentation/widgets/room_card_widget.dart';

class MobileDashboardPage extends StatefulWidget {
  const MobileDashboardPage({super.key});

  @override
  State<MobileDashboardPage> createState() => _MobileDashboardPageState();
}

class _MobileDashboardPageState extends State<MobileDashboardPage> {
  int _currentIndex = 0;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgCard,
      body: RefreshIndicator(
        onRefresh: () async {
          final dashboardCubit = context.read<DashboardCubit>();
          final roomsCubit = context.read<RoomsCubit>();
          final sessionHistoryCubit = context.read<SessionHistoryCubit>();

          await dashboardCubit.loadDashboardStats();
          await roomsCubit.refresh();

          if (_selectedRoom != null) {
            await sessionHistoryCubit.loadRoomHistory(_selectedRoom!.id);
          }
        },
        child: IndexedStack(
          index: _currentIndex,
          children: [
            // Tab 1: Rooms Overview
            _buildRoomsTab(),

            // Tab 2: Selected Room Details
            _selectedRoom != null
                ? _buildRoomDetailsTab()
                : _buildNoRoomSelected(),

            // Tab 3: Dashboard Statistics
            _buildStatisticsTab(),
          ],
        ),
      ),
      bottomNavigationBar: Theme(
        data: Theme.of(context).copyWith(
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          backgroundColor: AppColors.bgDark,
          selectedItemColor: AppColors.primaryBlue,
          unselectedItemColor: Colors.white70,
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.meeting_room),
              label: 'Rooms',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.info),
              label: 'Details',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.analytics),
              label: 'Stats',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoomsTab() {
    return BlocBuilder<RoomsCubit, RoomsState>(
      builder: (context, state) {
        if (state is RoomsLoading) {
          return const Center(child: AppLoadingWidget());
        } else if (state is RoomsError) {
          return Center(child: Text("Error: ${state.message}"));
        } else if (state is RoomsLoaded) {
          return _buildRoomsList(state.rooms);
        } else {
          return const Center(child: AppLoadingWidget());
        }
      },
    );
  }

  Widget _buildRoomsList(List<Room> rooms) {
    return SafeArea(
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: rooms.length,
        itemBuilder: (context, index) {
          final room = rooms[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            child: RoomCardWidget(
              room: room,
              isSelected: _selectedRoom?.id == room.id,
              onTap: () {
                _selectRoom(room);
                setState(() => _currentIndex = 1); // Switch to details tab
              },
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
            ),
          );
        },
      ),
    );
  }

  Widget _buildRoomDetailsTab() {
    return BlocBuilder<SessionHistoryCubit, SessionHistoryState>(
      builder: (context, state) {
        List<SessionHistory> history = [];
        if (state is SessionHistoryLoaded) {
          history = state.history;
        }

        return CustomScrollView(
          slivers: [
            // Room Header
            SliverAppBar(
              backgroundColor: AppColors.bgDark,
              expandedHeight: 120,
              flexibleSpace: FlexibleSpaceBar(
                title: Text(
                  _selectedRoom?.name ?? 'Room',
                  style: AppTexts.smallHeading,
                ),
                background: Container(
                  color: AppColors.bgDark,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _selectedRoom!.isOccupied
                          ? Text(
                            'Occupied',
                            style: AppTexts.smallBody.copyWith(
                              color: Colors.red,
                            ),
                          )
                          : Text(
                            'Available',
                            style: AppTexts.smallBody.copyWith(
                              color: Colors.green,
                            ),
                          ),
                    ],
                  ),
                ),
              ),
            ),

            // Room Details
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Today\'s History',
                      style: AppTexts.meduimBody.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (state is SessionHistoryLoading)
                      const AppLoadingWidget()
                    else if (state is SessionHistoryError)
                      Text("Error: ${state.message}", style: AppTexts.smallBody)
                    else if (history.isEmpty)
                      const Text(
                        "No sessions today",
                        style: TextStyle(color: Colors.grey),
                      )
                    else
                      ...history.map((session) => _buildSessionCard(session)),
                    const SizedBox(height: 16),
                    _buildTotalDay(history),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSessionCard(SessionHistory session) {
    final sessionCost = _calculateSessionCost(session);
    final ordersCost = session.ordersTotal;
    final totalCost = sessionCost + ordersCost;

    return Card(
      color: AppColors.bgDark,
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Session',
                  style: AppTexts.smallBody.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) => HistoryDetailsPage(
                              sessionHistory: session,
                              room: _selectedRoom!,
                              sessionId: session.id,
                            ),
                      ),
                    );
                  },
                  child: Icon(
                    Icons.remove_red_eye,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _buildMobileRow("Start", session.startTimeShort),
            _buildMobileRow(
              "End",
              session.endTime != null ? session.endTimeShort : "Running",
            ),
            _buildMobileRow("Duration", session.formattedDuration),
            _buildMobileRow(
              "Session Cost",
              "${sessionCost.toStringAsFixed(0)} \$",
            ),
            if (ordersCost > 0)
              _buildMobileRow(
                "Orders",
                "${ordersCost.toStringAsFixed(0)} \$",
                color: Colors.green,
              ),
            const Divider(color: Colors.grey, height: 12),
            _buildMobileRow(
              "TOTAL",
              "${totalCost.toStringAsFixed(0)} \$",
              isBold: true,
              color: AppColors.primaryBlue,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileRow(
    String title,
    String value, {
    bool isBold = false,
    Color color = Colors.white,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: AppTexts.smallBody.copyWith(
                color: Colors.white70,
              ),
            ),
          ),
          Text(
            value,
            style: AppTexts.smallBody.copyWith(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalDay(List<SessionHistory> history) {
    final (sessionCosts, ordersCosts, total) = _calculateDetailedTotal(history);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.bgCardLight,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Today's Total", style: AppTexts.meduimBody),
          const SizedBox(height: 8),
          _buildTotalRow("Session Costs:", sessionCosts),
          _buildTotalRow(
            "Orders Costs:",
            ordersCosts,
            isOrders: ordersCosts > 0,
          ),
          const Divider(color: Colors.grey, height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "TOTAL:",
                style: AppTexts.meduimBody.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                "${total.toStringAsFixed(0)} \$",
                style: AppTexts.largeHeading.copyWith(
                  color: AppColors.primaryBlue,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTotalRow(String label, double value, {bool isOrders = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTexts.smallBody),
          Text(
            "${value.toStringAsFixed(0)} \$",
            style: AppTexts.smallBody.copyWith(
              color: isOrders && value > 0 ? Colors.green : Colors.white70,
              fontWeight:
                  isOrders && value > 0 ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoRoomSelected() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.meeting_room_outlined,
            size: 64,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          Text(
            "Select a Room",
            style: AppTexts.meduimHeading,
          ),
          const SizedBox(height: 8),
          Text(
            "Tap on a room from the Rooms tab to view details",
            style: AppTexts.smallBody.copyWith(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsTab() {
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

        return SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Today Income Card
              Card(
                color: AppColors.bgDark,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Text(
                        "Today's Income",
                        style: AppTexts.meduimHeading,
                      ),
                      const SizedBox(height: 12),
                      if (state is DashboardLoading)
                        const AppLoadingWidget()
                      else if (state is DashboardError)
                        Text("Error", style: AppTexts.smallBody)
                      else
                        Column(
                          children: [
                            Text(
                              "${todayIncome.toStringAsFixed(0)} \$",
                              style: AppTexts.largeHeading.copyWith(
                                color: AppColors.primaryBlue,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "(Sessions + Orders)",
                              style: AppTexts.smallBody.copyWith(
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Rooms Stats
              Row(
                children: [
                  Expanded(
                    child: Card(
                      color: AppColors.bgDark,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Text(
                              "Free",
                              style: AppTexts.smallHeading,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              freeRooms.toString(),
                              style: AppTexts.largeHeading,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Card(
                      color: AppColors.bgDark,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Text(
                              "Occupied",
                              style: AppTexts.smallHeading,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              occupiedRooms.toString(),
                              style: AppTexts.largeHeading,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Quick Actions
              Card(
                color: AppColors.bgDark,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Quick Actions",
                        style: AppTexts.meduimBody.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryBlue,
                                foregroundColor: Colors.white,
                              ),
                              onPressed: () {
                                context
                                    .read<DashboardCubit>()
                                    .loadDashboardStats();
                                context.read<RoomsCubit>().refresh();
                              },
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.refresh, size: 18),
                                  const SizedBox(width: 4),
                                  Text("Refresh", style: AppTexts.smallBody),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  double _calculateSessionCost(SessionHistory session) {
    if (session.endTime == null) return 0.0;
    final duration = session.endTime!.difference(session.startTime);
    final hours = duration.inMinutes / 60.0;
    return hours * session.hourlyRate;
  }

  (double, double, double) _calculateDetailedTotal(
    List<SessionHistory> history,
  ) {
    double sessionCosts = 0.0;
    double ordersCosts = 0.0;
    double total = 0.0;

    for (var session in history) {
      if (session.endTime != null) {
        final duration = session.endTime!.difference(session.startTime);
        final hours = duration.inMinutes / 60.0;
        final sessionCost = hours * session.hourlyRate;
        final ordersCost = session.ordersTotal;

        sessionCosts += sessionCost;
        ordersCosts += ordersCost;
        total += (sessionCost + ordersCost);
      }
    }

    return (sessionCosts, ordersCosts, total);
  }
}
