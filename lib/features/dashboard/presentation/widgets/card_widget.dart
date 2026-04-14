import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quarto/core/colors/app_colors.dart';
import 'package:quarto/core/common/vip_widget.dart';
import 'package:quarto/features/cafe/presentation/cubits/tabels_cubit/cafe_tables_cubit.dart';
import 'package:quarto/features/dashboard/data/model/room_model.dart';
import 'package:quarto/features/dashboard/presentation/cubits/dashboard/dashboard_cubit.dart';
import 'package:quarto/features/dashboard/presentation/cubits/rooms/rooms_cubit.dart';
import 'package:quarto/features/dashboard/presentation/widgets/session_card_dailog.dart';

class CardWidget extends StatelessWidget {
  const CardWidget({
    super.key,
    required this.data,
    required this.title,
    this.state,
    this.cafeState,
  });
  final String data;
  final String title;
  final DashboardState? state;
  final CafeTablesState? cafeState;
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      clipBehavior: Clip.antiAlias,
      constraints: const BoxConstraints(
        minWidth: 150,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      decoration: BoxDecoration(
        boxShadow: const [
          BoxShadow(
            blurRadius: 1,
            color: Colors.white10,
            spreadRadius: 1,
            offset: Offset(0, 0),
          ),
        ],
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white24, strokeAlign: 2),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          (state is DashboardLoading || cafeState is LoadingGetTables)
              ? CircularProgressIndicator(
                  color: AppColors.yellowColor,
                )
              : Text(
                  data,
                  style: TextStyle(
                    fontSize: 18,
                    color: AppColors.yellowColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class NewRoomCardWidget extends StatelessWidget {
  const NewRoomCardWidget({
    super.key,
    required this.room,
    this.onMove,
    this.onEnd,
  });
  final Room room;
  final VoidCallback? onMove;
  final VoidCallback? onEnd;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      clipBehavior: Clip.antiAlias,
      width: 270,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      decoration: BoxDecoration(
        boxShadow: const [
          BoxShadow(
            blurRadius: 1,
            color: Colors.white10,
            spreadRadius: 1,
            offset: Offset(0, 0),
          ),
        ],
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white24, strokeAlign: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.door_back_door_outlined,
                color: Colors.white,
              ),
              const SizedBox(width: 6),
              Text(
                room.name,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              room.isVip
                  ? const VipWidget()
                  : StandardWidget(
                      data: room.roomTypeDescription,
                    ),
            ],
          ),
          const SizedBox(height: 30),
          BlocBuilder<RoomsCubit, RoomsState>(
            builder: (context, state) {
              if (state is! RoomsLoaded) {
                return const SizedBox();
              }

              final currentRoom = state.rooms.firstWhere(
                (r) => r.id == room.id,
                orElse: () => room,
              );

              if (!currentRoom.isOccupied) {
                return Center(
                  child: ElevatedButton.icon(
                    style: ButtonStyle(
                      backgroundColor: WidgetStatePropertyAll(
                        AppColors.blueColor,
                      ),
                      side: WidgetStatePropertyAll(
                        BorderSide(
                          width: 3,
                          color: AppColors.yellowColor,
                        ),
                      ),
                    ),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) {
                          return BlocProvider.value(
                            value: context.read<RoomsCubit>(),
                            child: SessionCardDailog(
                              roomId: currentRoom.id,
                              isRoom8: currentRoom.name == 'room8',
                              isVip: currentRoom.isVip,
                            ),
                          );
                        },
                      );
                    },
                    icon: const Icon(
                      Icons.play_arrow,
                      color: Colors.white,
                    ),
                    label: const Text(
                      'Start Session',
                      style: TextStyle(
                        color: Colors.white,
                      ),
                    ),
                  ),
                );
              }

              return Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      style: const ButtonStyle(
                        backgroundColor: WidgetStatePropertyAll(Colors.red),
                        side: WidgetStatePropertyAll(
                          BorderSide(
                            width: 3,
                            color: Colors.red,
                          ),
                        ),
                      ),
                      onPressed: () {
                        onEnd?.call();
                      },
                      icon: const Icon(
                        Icons.stop,
                        color: Colors.white,
                        size: 16,
                      ),
                      label: const FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          'End Session',
                          style: TextStyle(
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ButtonStyle(
                        backgroundColor: const WidgetStatePropertyAll(
                          Colors.transparent,
                        ),
                        side: const WidgetStatePropertyAll(
                          BorderSide(
                            width: 1,
                            color: Colors.white,
                          ),
                        ),
                        shape: WidgetStatePropertyAll(
                          ContinuousRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      onPressed: onMove,
                      icon: const Icon(
                        Icons.move_down_outlined,
                        color: Colors.white,
                        size: 16,
                      ),
                      label: const FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          'Move',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
