// ignore_for_file: deprecated_member_use

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quarto/core/colors/app_colors.dart';
import 'package:quarto/features/dashboard/presentation/cubits/rooms/rooms_cubit.dart';

class SessionCardDailog extends StatefulWidget {
  const SessionCardDailog({
    super.key,
    required this.roomId,
    required this.isVip,
    required this.isRoom8,
  });
  final String roomId;
  final bool isVip;
  final bool isRoom8;
  @override
  State<SessionCardDailog> createState() => _SessionCardDailogState();
}

class _SessionCardDailogState extends State<SessionCardDailog> {
  String? consoleType;
  String? gameMode;

  double _calculatePrice() {
    if (consoleType == null || gameMode == null) return 0.0;

    final type = consoleType!.toLowerCase();

    if (widget.isRoom8) {
      if (type == 'ps4') {
        return gameMode == 'Multi' ? 100.0 : 60.0;
      } else {
        return gameMode == 'Multi' ? 130.0 : 90.0;
      }
    } else if (widget.isVip) {
      if (type == 'ps4') {
        return gameMode == 'Multi' ? 110.0 : 80.0;
      } else {
        return gameMode == 'Multi' ? 140.0 : 120.0;
      }
    } else {
      if (type == 'ps4') {
        return gameMode == 'Multi' ? 80.0 : 50.0;
      } else {
        return gameMode == 'Multi' ? 100.0 : 70.0;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RoomsCubit, RoomsState>(
      builder: (context, state) {
        return AlertDialog(
          alignment: AlignmentGeometry.center,
          backgroundColor: Colors.transparent,
          content: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
              child: Container(
                constraints: BoxConstraints(
                  minWidth: 400,
                ),
                padding: EdgeInsets.symmetric(vertical: 30, horizontal: 20),
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      blurRadius: 30,
                      spreadRadius: -5,
                      color: Colors.black.withOpacity(0.3),
                    ),
                  ],
                  color: Colors.white.withOpacity(0.05),

                  border: Border.all(color: Colors.white.withOpacity(0.2)),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Gaming Stations',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Icon(
                            Icons.close,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    Text(
                      'Configure the session before starting.',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                    SizedBox(height: 30),
                    Text(
                      'Console Type',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 12),
                    Row(
                      children: [
                        buttomWidget(
                          isSelected: consoleType == 'PS4' ? true : false,
                          label: 'PS 4',
                          onPressed: () {
                            setState(() {
                              consoleType = 'PS4';
                            });
                          },
                        ),
                        SizedBox(width: 20),
                        buttomWidget(
                          isSelected: consoleType == 'PS5' ? true : false,
                          label: 'PS 5',
                          onPressed: () {
                            setState(() {
                              consoleType = 'PS5';
                            });
                          },
                        ),
                      ],
                    ),
                    SizedBox(height: 30),
                    Text(
                      'Game Mode',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 12),
                    Row(
                      children: [
                        buttomWidget(
                          isSelected: gameMode == 'Single' ? true : false,
                          label: 'Single',
                          onPressed: () {
                            setState(() {
                              gameMode = 'Single';
                            });
                          },
                        ),
                        SizedBox(width: 20),
                        buttomWidget(
                          isSelected: gameMode == 'Multi' ? true : false,
                          label: 'Multi',
                          onPressed: () {
                            setState(() {
                              gameMode = 'Multi';
                            });
                          },
                        ),
                      ],
                    ),
                    SizedBox(height: 40),
                    Center(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Total Cost :',
                            style: TextStyle(
                              color: AppColors.yellowColor,
                              fontSize: 22,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(width: 12),
                          Text(
                            '${_calculatePrice()}',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 30),
                    Center(
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
                          context.read<RoomsCubit>().startSession(
                            widget.roomId,
                            isMulti: gameMode == 'Multi' ? true : false,
                            psType: consoleType,
                            hourlyRate: _calculatePrice(),
                          );
                          Navigator.pop(context);
                        },
                        icon: Icon(
                          Icons.play_arrow,
                          color: Colors.white,
                        ),
                        label: Text(
                          'Start Session',
                          style: TextStyle(
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

Widget buttomWidget({
  required String label,
  required bool isSelected,
  required void Function()? onPressed,
}) {
  return ElevatedButton.icon(
    style: ButtonStyle(
      backgroundColor: WidgetStatePropertyAll(
        isSelected == true ? AppColors.yellowColor : Colors.transparent,
      ),
      side: WidgetStatePropertyAll(
        BorderSide(
          color: isSelected == true ? AppColors.yellowColor : Colors.white,
        ),
      ),
    ),
    onPressed: onPressed,
    icon: Icon(
      Icons.sports_esports_outlined,
      color: isSelected == true ? AppColors.blueColor : Colors.white,
    ),
    label: Text(
      label,
      style: TextStyle(
        color: isSelected == true ? AppColors.blueColor : Colors.white,
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}
