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
      margin: EdgeInsets.symmetric(horizontal: 2),
      clipBehavior: Clip.antiAlias,
      constraints: BoxConstraints(
        minWidth: 150,
      ),
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      decoration: BoxDecoration(
        boxShadow: [
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
          SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class NewRoomCardWidget extends StatefulWidget {
  const NewRoomCardWidget({
    super.key,
    required this.room,
  });
  final Room room;
  @override
  State<NewRoomCardWidget> createState() => _NewRoomCardWidgetState();
}

class _NewRoomCardWidgetState extends State<NewRoomCardWidget> {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 2),
      clipBehavior: Clip.antiAlias,
      width: 270,
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      decoration: BoxDecoration(
        boxShadow: [
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
              Icon(
                Icons.door_back_door_outlined,
                color: Colors.white,
              ),
              SizedBox(width: 6),
              Text(
                widget.room.name,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Spacer(),
              widget.room.isVip
                  ? VipWidget()
                  : StandardWidget(
                      data: widget.room.roomTypeDescription,
                    ),
            ],
          ),
          SizedBox(height: 30),
          BlocBuilder<RoomsCubit, RoomsState>(
            builder: (context, state) {
              if (state is RoomsLoaded) {
                final room = state.rooms.firstWhere(
                  (r) => r.id == widget.room.id,
                );
                return Center(
                  child: ElevatedButton.icon(
                    style: ButtonStyle(
                      backgroundColor: WidgetStatePropertyAll(
                        room.isOccupied == false
                            ? AppColors.blueColor
                            : Colors.red,
                      ),
                      side: WidgetStatePropertyAll(
                        BorderSide(
                          width: 3,
                          color: room.isOccupied == false
                              ? AppColors.yellowColor
                              : Colors.red,
                        ),
                      ),
                    ),
                    onPressed: () {
                      if (room.isOccupied == false) {
                        showDialog(
                          context: context,
                          builder: (context) {
                            return BlocProvider.value(
                              value: context.read<RoomsCubit>(),
                              child: SessionCardDailog(
                                roomId: room.id,
                                isRoom8: room.name == 'room8',
                                isVip: room.isVip,
                              ),
                            );
                          },
                        );
                      }
                      if (room.isOccupied == true) {
                        context.read<RoomsCubit>().endSession(
                          room.id,
                        );
                      }
                    },
                    icon: Icon(
                      room.isOccupied == false ? Icons.play_arrow : Icons.pause,
                      color: Colors.white,
                    ),
                    label: Text(
                      room.isOccupied == false
                          ? 'Start Session'
                          : 'End Session',
                      style: TextStyle(
                        color: Colors.white,
                      ),
                    ),
                  ),
                );
              }
              return SizedBox();
            },
          ),
        ],
      ),
    );
  }
}
