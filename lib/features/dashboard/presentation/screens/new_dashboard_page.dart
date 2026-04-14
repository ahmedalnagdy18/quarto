import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quarto/core/colors/app_colors.dart';
import 'package:quarto/core/services/day_reset_service.dart';
import 'package:quarto/core/services/system_export_service.dart';
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

  Future<void> _exportAllRooms() async {
    await SystemExportService.exportRoomsReport(context);
  }

  Future<void> _confirmStartNewDay() async {
    final roomsCubit = context.read<RoomsCubit>();
    final dashboardCubit = context.read<DashboardCubit>();
    final roomOutcomesCubit = context.read<RoomOutcomesCubit>();

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF11133E),
        title: const Text(
          'Start New Day?',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'A full backup for rooms and cafe will be created first, then all current data will be cleared to start a new day.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('OK'),
          ),
        ],
      ),
    );

    if (confirm != true) {
      return;
    }

    if (!mounted) {
      return;
    }

    try {
      await DayResetService.startNewDay(context);
      if (!mounted) {
        return;
      }
      await roomsCubit.loadRoomsAndStats();
      await dashboardCubit.loadDashboardStats();
      await roomOutcomesCubit.getRoomOutcomes();
    } catch (_) {}
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

  Future<void> _endRoomSession(Room room) async {
    if (!room.isOccupied) {
      _showMessage('No active session found for this room.');
      return;
    }

    final roomsCubit = context.read<RoomsCubit>();
    final dashboardCubit = context.read<DashboardCubit>();
    final paymentMethod = await showDialog<String>(
      context: context,
      builder: (context) => _RoomFinalPaymentDialog(room: room),
    );

    if (paymentMethod == null || paymentMethod.isEmpty) {
      return;
    }

    try {
      await roomsCubit.endSession(
        room.id,
        paymentMethod: paymentMethod.toLowerCase(),
      );
      if (!mounted) {
        return;
      }
      await dashboardCubit.loadDashboardStats();
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
                    title: 'Start New Day',
                    icon: Icons.list_alt_outlined,
                    onPressed: _confirmStartNewDay,
                  ),
                  const SizedBox(width: 20),
                  ExportButtonsWidget(
                    title: 'Export history',
                    icon: Icons.download,
                    onPressed: _exportAllRooms,
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
                  double roomCashTotal = 0.0;
                  double roomVisaTotal = 0.0;

                  if (state is DashboardLoaded) {
                    freeRooms = state.totalFreeRooms;
                    occupiedRooms = state.totalOccupiedRooms;
                    roomsIncome = state.roomsIncome;
                    ordersIncome = state.ordersIncome;
                    roomCashTotal = state.roomCashTotal;
                    roomVisaTotal = state.roomVisaTotal;
                    totalRevenue = state.totalIncome;
                  }
                  return Column(
                    children: [
                      Row(
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
                                BlocBuilder<
                                  RoomOutcomesCubit,
                                  RoomOutcomesState
                                >(
                                  builder: (context, state) {
                                    if (state is SuccessGetOutcomes) {
                                      final totalOutcomes = state.data
                                          .fold<double>(
                                            0,
                                            (sum, item) =>
                                                sum +
                                                (item.price * item.quantity),
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
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: CardWidget(
                              data: '${roomCashTotal.toStringAsFixed(0)}\$',
                              title: 'Cash total',
                              state: state,
                            ),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: CardWidget(
                              data: '${roomVisaTotal.toStringAsFixed(0)}\$',
                              title: 'Visa total',
                              state: state,
                            ),
                          ),
                          const SizedBox(width: 20),
                          const Expanded(child: SizedBox()),
                          const SizedBox(width: 20),
                          const Expanded(child: SizedBox()),
                          const SizedBox(width: 20),
                          const Expanded(child: SizedBox()),
                        ],
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
                              onEnd: state.rooms[index].isOccupied
                                  ? () => _endRoomSession(state.rooms[index])
                                  : null,
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

class _RoomFinalPaymentDialog extends StatefulWidget {
  const _RoomFinalPaymentDialog({required this.room});

  final Room room;

  @override
  State<_RoomFinalPaymentDialog> createState() =>
      _RoomFinalPaymentDialogState();
}

class _RoomFinalPaymentDialogState extends State<_RoomFinalPaymentDialog> {
  String _selectedPaymentMethod = 'Cash';

  @override
  Widget build(BuildContext context) {
    final totalCost = widget.room.calculatedCost + widget.room.ordersTotal;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 410,
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: const Color(0xFF11133E),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white30),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Final Payment',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                InkWell(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.close, color: Colors.white),
                ),
              ],
            ),
            const SizedBox(height: 14),
            const Text(
              'Choose how this room session will be paid before closing it.',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 20),
            Center(
              child: Text(
                'Total cost : ${totalCost.toStringAsFixed(2)}',
                style: TextStyle(
                  color: AppColors.yellowColor,
                  fontSize: 28,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Payment method',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _RoomPaymentMethodChoice(
                  label: 'Cash',
                  selected: _selectedPaymentMethod == 'Cash',
                  onTap: () {
                    setState(() {
                      _selectedPaymentMethod = 'Cash';
                    });
                  },
                ),
                const SizedBox(width: 12),
                _RoomPaymentMethodChoice(
                  label: 'Visa',
                  selected: _selectedPaymentMethod == 'Visa',
                  onTap: () {
                    setState(() {
                      _selectedPaymentMethod = 'Visa';
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text(
              'Session Summary',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Session time',
                  style: TextStyle(color: Colors.white70),
                ),
                Text(
                  '${widget.room.calculatedCost.toStringAsFixed(0)} EGP',
                  style: const TextStyle(color: Colors.white),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Orders',
                  style: TextStyle(color: Colors.white70),
                ),
                Text(
                  '${widget.room.ordersTotal.toStringAsFixed(0)} EGP',
                  style: const TextStyle(color: Colors.white),
                ),
              ],
            ),
            const Divider(height: 28, color: Colors.white24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${totalCost.toStringAsFixed(0)} EGP',
                  style: TextStyle(
                    color: AppColors.yellowColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Center(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.blueColor,
                  foregroundColor: Colors.white,
                  side: BorderSide(color: AppColors.yellowColor, width: 3),
                  shape: ContinuousRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 26,
                    vertical: 12,
                  ),
                ),
                onPressed: () {
                  Navigator.pop(context, _selectedPaymentMethod);
                },
                child: const Text('Submit'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoomPaymentMethodChoice extends StatelessWidget {
  const _RoomPaymentMethodChoice({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.yellowColor : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? AppColors.yellowColor : Colors.white30,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? AppColors.blueColor : Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
