import 'dart:io';
import 'package:flutter/material.dart';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:quarto/core/colors/app_colors.dart';

import 'package:quarto/features/dashboard/presentation/cubits/rooms/rooms_cubit.dart';
import 'package:quarto/features/dashboard/presentation/cubits/session_history/session_history_cubit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ExportSessionsButton extends StatelessWidget {
  const ExportSessionsButton({super.key});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      icon: const Icon(Icons.download),
      label: const Text("Export Rooms & History"),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      ),
      onPressed: () async {
        try {
          final roomsState = context.read<RoomsCubit>().state;
          final historyCubit = context.read<SessionHistoryCubit>();

          if (roomsState is! RoomsLoaded) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Rooms not loaded yet")),
            );
            return;
          }

          final rooms = roomsState.rooms;

          final excel = Excel.createExcel();
          final Sheet sheet = excel['Rooms & History'];

          // Header
          sheet.appendRow([
            'Room Name',
            'Hourly Rate',
            'PS Type',
            'Session Start',
            'Session End',
            'Duration',
            'Cost',
          ]);

          double totalCostAllRooms = 0.0; // ← مجموع كل الرومات

          // Loop through rooms
          for (var room in rooms) {
            // Load history for each room
            final history = await historyCubit.getRoomHistoryUsecase(
              roomId: room.id,
            );

            double totalCost = 0.0;

            if (history.isEmpty) {
              sheet.appendRow([
                room.name,
                room.hourlyRate.toStringAsFixed(2),
                room.psType ?? '',
                '',
                '',
                '',
                '',
              ]);
            } else {
              for (var session in history) {
                totalCost += session.totalCost;
                sheet.appendRow([
                  room.name,
                  room.hourlyRate.toStringAsFixed(2),
                  room.psType ?? '',
                  session.startTimeShort,
                  session.endTime != null ? session.endTimeShort : 'Running',
                  session.formattedDuration,
                  session.totalCost.toStringAsFixed(2),
                ]);
              }
              // Add total row for this room
              sheet.appendRow([
                '',
                '',
                '',
                '',
                '',
                '',
                'Total Cost',
                totalCost.toStringAsFixed(2),
              ]);
            }

            totalCostAllRooms += totalCost; // ← تحديث مجموع الكل

            // Empty row to separate rooms
            sheet.appendRow([]);
          }

          // Add grand total for all rooms at the end
          sheet.appendRow([]);
          sheet.appendRow([
            '',
            '',
            '',
            '',
            '',
            '',
            'Grand Total Cost',
            totalCostAllRooms.toStringAsFixed(2),
          ]);

          // Save file
          final directory = await getApplicationDocumentsDirectory();
          final filePath =
              '${directory.path}/rooms_history_${DateTime.now().toIso8601String()}.xlsx';
          final fileBytes = excel.encode();
          if (fileBytes != null) {
            final file = File(filePath);
            await file.writeAsBytes(fileBytes);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Backup saved at $filePath")),
            );
          }
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error exporting: $e")),
          );
        }
      },
    );
  }
}
