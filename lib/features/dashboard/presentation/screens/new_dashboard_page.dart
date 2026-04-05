import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quarto/core/colors/app_colors.dart';
import 'package:quarto/features/dashboard/data/model/room_model.dart';
import 'package:quarto/features/dashboard/domain/repository/dashboard_repository.dart';
import 'package:quarto/features/dashboard/presentation/cubits/dashboard/dashboard_cubit.dart';
import 'package:quarto/features/dashboard/presentation/cubits/outcomes/outcomes_cubit.dart';
import 'package:quarto/features/dashboard/presentation/cubits/rooms/rooms_cubit.dart';
import 'package:quarto/features/dashboard/presentation/screens/room_details_page.dart';
import 'package:quarto/features/dashboard/presentation/screens/rooms_outcomes_page.dart';
import 'package:quarto/features/dashboard/presentation/widgets/button_widget.dart';
import 'package:quarto/features/dashboard/presentation/widgets/card_widget.dart';
import 'package:quarto/injection_container.dart';

class NewDashboardPage extends StatefulWidget {
  const NewDashboardPage({super.key});

  @override
  State<NewDashboardPage> createState() => _NewDashboardPageState();
}

class _NewDashboardPageState extends State<NewDashboardPage> {
  final DashboardRepository _dashboardRepository = sl<DashboardRepository>();

  @override
  void initState() {
    context.read<RoomsCubit>().loadRoomsAndStats();
    context.read<DashboardCubit>().loadDashboardStats();
    context.read<RoomOutcomesCubit>().getRoomOutcomes();
    super.initState();
  }

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _moveRoom(Room sourceRoom, List<Room> allRooms) async {
    if (!sourceRoom.isOccupied) {
      _showMessage('No active session found for this room.');
      return;
    }

    final availableRooms = allRooms
        .where((room) => !room.isOccupied && room.id != sourceRoom.id)
        .toList();

    if (availableRooms.isEmpty) {
      _showMessage('No available rooms to move this session.');
      return;
    }

    final roomsCubit = context.read<RoomsCubit>();
    final dashboardCubit = context.read<DashboardCubit>();

    final targetRoom = await showDialog<Room>(
      context: context,
      barrierDismissible: true,
      builder: (context) => _MoveRoomDialog(
        sourceRoom: sourceRoom,
        availableRooms: availableRooms,
      ),
    );

    if (targetRoom == null) {
      return;
    }

    try {
      await _dashboardRepository.moveRoomSession(
        fromRoomId: sourceRoom.id,
        toRoomId: targetRoom.id,
      );
      await roomsCubit.loadRoomsAndStats();
      await dashboardCubit.loadDashboardStats();
      if (!mounted) {
        return;
      }
      _showMessage('${sourceRoom.name} moved to ${targetRoom.name}.');
    } catch (error) {
      _showMessage(error.toString().replaceFirst('Exception: ', ''));
    }
  }

  double? totalRevenue;
  double? totalOutcomess;

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
                  const Spacer(),
                  ExportButtonsWidget(
                    title: 'Export history',
                    icon: Icons.download,
                    onPressed: () {},
                  ),
                  const SizedBox(width: 20),
                  ExportButtonsWidget(
                    title: 'Start New Day',
                    icon: Icons.list_alt_outlined,
                    onPressed: () {},
                  ),
                  const SizedBox(width: 20),
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
              const SizedBox(height: 40),
              const Text(
                'Gaming Stations',
                style: TextStyle(
                  fontSize: 20,
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Manage your PlayStation gaming lounge',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 30),
              BlocBuilder<DashboardCubit, DashboardState>(
                builder: (context, state) {
                  int freeRooms = 0;
                  int occupiedRooms = 0;
                  double roomsIncome = 0.0;
                  double ordersIncome = 0.0;

                  if (state is DashboardLoaded) {
                    freeRooms = state.totalFreeRooms;
                    occupiedRooms = state.totalOccupiedRooms;
                    roomsIncome = state.roomsIncome;
                    ordersIncome = state.ordersIncome;
                    totalRevenue = state.totalIncome;
                  }
                  return Row(
                    children: [
                      Expanded(
                        child: CardWidget(
                          data: '$freeRooms',
                          title: 'Free rooms',
                          state: state,
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: CardWidget(
                          data: '$occupiedRooms',
                          title: 'Occupied rooms',
                          state: state,
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: CardWidget(
                          data: '${roomsIncome.toStringAsFixed(0)}\$',
                          title: 'Rooms income',
                          state: state,
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: CardWidget(
                          data: '${ordersIncome.toStringAsFixed(0)}\$',
                          title: 'Orders income',
                          state: state,
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child:
                            BlocBuilder<RoomOutcomesCubit, RoomOutcomesState>(
                              builder: (context, state) {
                                if (state is SuccessGetOutcomes) {
                                  final totalOutcomes = state.data.fold<double>(
                                    0,
                                    (sum, item) =>
                                        sum + (item.price * item.quantity),
                                  );
                                  totalOutcomess = totalOutcomes;
                                }
                                return CardWidget(
                                  data:
                                      '${totalOutcomess?.toStringAsFixed(0)}\$',
                                  title: 'Outcomes',
                                );
                              },
                            ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 30),
              const Text(
                'Rooms',
                style: TextStyle(
                  fontSize: 20,
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 30),
              BlocListener<RoomsCubit, RoomsState>(
                listener: (context, state) {
                  if (state is RoomsLoaded) {
                    context.read<DashboardCubit>().loadDashboardStats();
                  }
                },
                child: BlocBuilder<RoomsCubit, RoomsState>(
                  builder: (context, state) {
                    if (state is RoomsLoaded) {
                      return Wrap(
                        spacing: 15,
                        runSpacing: 15,
                        children: List.generate(
                          state.rooms.length,
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
                              onMove: state.rooms[index].isOccupied
                                  ? () => _moveRoom(
                                      state.rooms[index],
                                      state.rooms,
                                    )
                                  : null,
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
              const SizedBox(height: 50),
            ],
          ),
        ),
      ),
    );
  }
}

class _MoveRoomDialog extends StatefulWidget {
  const _MoveRoomDialog({
    required this.sourceRoom,
    required this.availableRooms,
  });

  final Room sourceRoom;
  final List<Room> availableRooms;

  @override
  State<_MoveRoomDialog> createState() => _MoveRoomDialogState();
}

class _MoveRoomDialogState extends State<_MoveRoomDialog> {
  String? _selectedRoomId;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 120, vertical: 60),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 840),
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: const Color(0xFF11133E),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white30),
          boxShadow: [
            BoxShadow(
              color: AppColors.blueColor.withValues(alpha: 0.18),
              blurRadius: 40,
              spreadRadius: 8,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Move Session',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Transfer the current session from ${widget.sourceRoom.name} to a different room.',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: Colors.white),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text(
              'Choose between available rooms',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: widget.availableRooms.map((room) {
                final isSelected = _selectedRoomId == room.id;
                return InkWell(
                  onTap: () {
                    setState(() {
                      _selectedRoomId = room.id;
                    });
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: 226,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.blueColor.withValues(alpha: 0.28)
                          : Colors.white.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.yellowColor
                            : Colors.white24,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.meeting_room_outlined,
                          color: isSelected
                              ? AppColors.yellowColor
                              : Colors.white70,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            room.name,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 28),
            Center(
              child: ElevatedButton.icon(
                onPressed: _selectedRoomId == null
                    ? null
                    : () {
                        final selectedRoom = widget.availableRooms.firstWhere(
                          (room) => room.id == _selectedRoomId,
                        );
                        Navigator.pop(context, selectedRoom);
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.blueColor,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.white12,
                  disabledForegroundColor: Colors.white38,
                  side: BorderSide(color: AppColors.yellowColor, width: 3),
                  shape: ContinuousRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 12,
                  ),
                ),
                icon: const Icon(Icons.move_down_outlined, size: 18),
                label: const Text(
                  'Move',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
