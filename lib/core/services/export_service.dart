import 'dart:io';

import 'package:excel/excel.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:quarto/features/dashboard/presentation/cubits/rooms/rooms_cubit.dart';
import 'package:quarto/features/dashboard/presentation/cubits/session_history/session_history_cubit.dart';
import 'package:share_plus/share_plus.dart';

class ExportService {
  static String getSafeTimestamp() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}_${now.hour.toString().padLeft(2, '0')}-${now.minute.toString().padLeft(2, '0')}-${now.second.toString().padLeft(2, '0')}';
  }

  static bool get isMobile => !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  static Future<void> exportData(BuildContext context) async {
    try {
      final roomsState = context.read<RoomsCubit>().state;
      final historyCubit = context.read<SessionHistoryCubit>();

      if (roomsState is! RoomsLoaded) {
        throw Exception("Rooms not loaded yet");
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
        'Session Cost',
        'Orders Cost',
        'Total Cost',
        'Orders Count',
        'Orders Details',
      ]);

      double totalSessionCostAllRooms = 0.0;
      double totalOrdersCostAllRooms = 0.0;
      double grandTotalAllRooms = 0.0;
      int totalOrdersCount = 0;

      for (var room in rooms) {
        final history = await historyCubit.getRoomHistoryUsecase(
          roomId: room.id,
        );

        double roomSessionCost = 0.0;
        double roomOrdersCost = 0.0;
        double roomTotalCost = 0.0;
        int roomOrdersCount = 0;

        if (history.isEmpty) {
          sheet.appendRow([
            room.name,
            room.hourlyRate.toStringAsFixed(2),
            room.psType ?? '',
            '',
            '',
            '',
            '',
            '',
            '',
            '',
            '',
          ]);
        } else {
          for (var session in history) {
            double sessionCost = 0.0;
            if (session.endTime != null) {
              final duration = session.endTime!.difference(session.startTime);
              final hours = duration.inMinutes / 60.0;
              sessionCost = hours * session.hourlyRate;
            }

            final ordersCost = session.ordersTotal;
            final totalCost = sessionCost + ordersCost;
            final ordersCount = session.ordersList.length;

            roomSessionCost += sessionCost;
            roomOrdersCost += ordersCost;
            roomTotalCost += totalCost;
            roomOrdersCount += ordersCount;

            String ordersDetails = session.ordersList
                .map((order) => '${order.name}: ${order.price}\$')
                .join(', ');

            sheet.appendRow([
              room.name,
              room.hourlyRate.toStringAsFixed(2),
              room.psType ?? '',
              session.startTimeShort,
              session.endTime != null ? session.endTimeShort : 'Running',
              session.formattedDuration,
              sessionCost.toStringAsFixed(2),
              ordersCost.toStringAsFixed(2),
              totalCost.toStringAsFixed(2),
              ordersCount.toString(),
              ordersDetails,
            ]);
          }

          // Room summary
          sheet.appendRow([
            '',
            '',
            '',
            '',
            '',
            '',
            'Room Total Session',
            'Room Total Orders',
            'Room Total',
            'Room Orders Count',
            '',
          ]);

          sheet.appendRow([
            '',
            '',
            '',
            '',
            '',
            '',
            roomSessionCost.toStringAsFixed(2),
            roomOrdersCost.toStringAsFixed(2),
            roomTotalCost.toStringAsFixed(2),
            roomOrdersCount.toString(),
            '',
          ]);

          totalSessionCostAllRooms += roomSessionCost;
          totalOrdersCostAllRooms += roomOrdersCost;
          grandTotalAllRooms += roomTotalCost;
          totalOrdersCount += roomOrdersCount;

          sheet.appendRow([]);
        }
      }

      // Grand totals
      sheet.appendRow([]);
      sheet.appendRow([
        '',
        '',
        '',
        '',
        '',
        '',
        'GRAND TOTAL SESSION',
        'GRAND TOTAL ORDERS',
        'GRAND TOTAL',
        'TOTAL ORDERS',
        '',
      ]);

      sheet.appendRow([
        '',
        '',
        '',
        '',
        '',
        '',
        totalSessionCostAllRooms.toStringAsFixed(2),
        totalOrdersCostAllRooms.toStringAsFixed(2),
        grandTotalAllRooms.toStringAsFixed(2),
        totalOrdersCount.toString(),
        '',
      ]);

      // Percentage breakdown
      if (grandTotalAllRooms > 0) {
        final sessionPercentage =
            (totalSessionCostAllRooms / grandTotalAllRooms * 100)
                .toStringAsFixed(1);
        final ordersPercentage =
            (totalOrdersCostAllRooms / grandTotalAllRooms * 100)
                .toStringAsFixed(1);

        sheet.appendRow([]);
        sheet.appendRow([
          '',
          '',
          '',
          '',
          '',
          '',
          'Breakdown',
          '',
          '',
          '',
          '',
        ]);

        sheet.appendRow([
          '',
          '',
          '',
          '',
          '',
          '',
          'Session: ${sessionPercentage}%',
          'Orders: ${ordersPercentage}%',
          'Total: 100%',
          '',
          '',
        ]);
      }

      // Save file
      final fileBytes = excel.encode();
      if (fileBytes == null) return;

      if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
        // Desktop
        final directory = await getApplicationDocumentsDirectory();
        final filePath = p.join(
          directory.path,
          'rooms_history_${getSafeTimestamp()}.xlsx',
        );

        final file = File(filePath);
        await file.writeAsBytes(fileBytes);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Backup saved at $filePath")),
          );
        }
      } else {
        // Mobile
        final tempDir = await getTemporaryDirectory();
        final filePath = p.join(
          tempDir.path,
          'rooms_history_${getSafeTimestamp()}.xlsx',
        );

        final file = File(filePath);
        await file.writeAsBytes(fileBytes);

        await Share.shareXFiles(
          [XFile(filePath)],
          text: 'Rooms & Sessions Export',
        );
      }
    } catch (e) {
      rethrow;
    }
  }
}
