import 'dart:async';
import 'package:flutter/material.dart';
import 'package:quarto/core/colors/app_colors.dart';
import 'package:quarto/core/extentions/app_extentions.dart';
import 'package:quarto/core/fonts/app_text.dart';
import 'package:quarto/features/dashboard/data/model/room_model.dart';
import 'package:quarto/features/dashboard/presentation/widgets/session_type_dialog.dart';

class RoomCardWidget extends StatefulWidget {
  final Room room;
  final bool isSelected;
  final VoidCallback onTap;
  final Function({
    String? psType,
    bool? isMulti,
    double? hourlyRate,
  })?
  onStartSession;
  final VoidCallback onEndSession;

  const RoomCardWidget({
    super.key,
    required this.room,
    required this.isSelected,
    required this.onTap,
    this.onStartSession,
    required this.onEndSession,
  });

  @override
  State<RoomCardWidget> createState() => _RoomCardWidgetState();
}

class _RoomCardWidgetState extends State<RoomCardWidget> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
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
        setState(() {});
      }
    });
  }

  @override
  void didUpdateWidget(RoomCardWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.room.isOccupied != widget.room.isOccupied) {
      if (widget.room.isOccupied) {
        _startTimer();
      } else {
        _timer?.cancel();
        _timer = null;
      }
    }
  }

  Future<void> _showSessionTypeDialog(BuildContext context) async {
    final room = widget.room;
    final isRoom8 =
        room.name.toLowerCase().contains('room 8') ||
        room.name.toLowerCase().contains('room8');

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder:
          (context) => SessionTypeDialog(
            roomName: room.name,
            isVip: room.isVip,
            isRoom8: isRoom8,
          ),
    );

    if (result != null && mounted && widget.onStartSession != null) {
      await widget.onStartSession!(
        psType: result['psType'],
        isMulti: result['isMulti'],
        hourlyRate: result['hourlyRate'],
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        width: 180,
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color:
              widget.isSelected
                  ? AppColors.primaryBlue.withOpacity(0.15)
                  : AppColors.bgCardLight,
          border: Border.all(
            color:
                widget.isSelected
                    ? AppColors.primaryBlue
                    : AppColors.borderLight.withOpacity(0.3),
            width: widget.isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Room name and status badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.room.name.toUpperCase(),
                  style: AppTexts.smallHeading.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color:
                        widget.room.isOccupied
                            ? Colors.red.withOpacity(0.15)
                            : Colors.green.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color:
                          widget.room.isOccupied
                              ? Colors.red.withOpacity(0.5)
                              : Colors.green.withOpacity(0.5),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    widget.room.isOccupied ? "Occupied" : "Free",
                    style: AppTexts.smallBody.copyWith(
                      fontSize: 10,
                      color: widget.room.isOccupied ? Colors.red : Colors.green,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Room details section - Show session info if occupied
            if (widget.room.isOccupied)
              StreamBuilder<int>(
                stream: Stream.periodic(const Duration(seconds: 1), (i) => i),
                builder: (context, snapshot) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Show PS type if available
                      if (widget.room.psTypeDisplay != null)
                        _buildDetailRow(
                          icon:
                              widget.room.psType == 'ps5'
                                  ? Icons.videogame_asset
                                  : Icons.games,
                          label: "Console",
                          value: widget.room.psTypeDisplay!,
                        ),

                      // Show session type if available
                      if (widget.room.sessionTypeDisplay != null)
                        _buildDetailRow(
                          icon: Icons.group,
                          label: "Type",
                          value: widget.room.sessionTypeDisplay!,
                        ),

                      // Start time
                      _buildDetailRow(
                        icon: Icons.access_time,
                        label: "Start",
                        value: _formatTime(widget.room.sessionStart),
                      ),
                      const SizedBox(height: 8),

                      // Live duration
                      _buildDetailRow(
                        icon: Icons.timer_outlined,
                        label: "Live Duration",
                        value: widget.room.liveDuration,
                      ),
                      const SizedBox(height: 8),

                      // Current cost
                      _buildDetailRow(
                        icon: Icons.attach_money,
                        label: "Current Cost",
                        value:
                            "${widget.room.calculatedCost.toStringAsFixed(0)} \$",
                        valueStyle: AppTexts.smallBody.copyWith(
                          color: AppColors.primaryBlue,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  );
                },
              )
            else
              // Empty state for free rooms
              Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 20),
                  Icon(
                    Icons.meeting_room_outlined,
                    size: 40,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.room.roomTypeDescription,
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),

            const SizedBox(height: 16),

            // Action button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      widget.room.isOccupied
                          ? Colors.red
                          : AppColors.primaryBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                  shadowColor: Colors.transparent,
                ),
                onPressed: () {
                  if (widget.room.isOccupied) {
                    widget.onEndSession();
                  } else {
                    _showSessionTypeDialog(context);
                  }
                },
                child: Text(
                  widget.room.isOccupied ? "End Session" : "Start Session",
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    TextStyle? valueStyle,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 14,
            color: Colors.grey,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 10,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style:
                      valueStyle ??
                      const TextStyle(
                        fontSize: 12,
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime? time) {
    return TimeFormatter.formatTo12Hour(time);
  }
}
