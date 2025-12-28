import 'dart:io';

import 'package:excel/excel.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:quarto/core/colors/app_colors.dart';
import 'package:quarto/features/dashboard/presentation/cubits/rooms/rooms_cubit.dart';
import 'package:quarto/features/dashboard/presentation/cubits/session_history/session_history_cubit.dart';
import 'package:share_plus/share_plus.dart';

class ExportSessionsButton extends StatelessWidget {
  const ExportSessionsButton({super.key});

  String getSafeTimestamp() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}_${now.hour.toString().padLeft(2, '0')}-${now.minute.toString().padLeft(2, '0')}-${now.second.toString().padLeft(2, '0')}';
  }

  bool get isMobile => !kIsWeb && (Platform.isAndroid || Platform.isIOS);

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

          // ⭐⭐ Header مع التحديثات ⭐⭐
          sheet.appendRow([
            'Room Name',
            'Hourly Rate',
            'PS Type',
            'Session Start',
            'Session End',
            'Duration',
            'Session Cost', // ⭐ تكلفة الجلسة بدون أوردرات
            'Orders Cost', // ⭐ تكلفة الأوردرات
            'Total Cost', // ⭐ الإجمالي (الجلسة + الأوردرات)
            'Orders Count', // ⭐ عدد الأوردرات
            'Orders Details', // ⭐ تفاصيل الأوردرات
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
                // حساب تكلفة الجلسة بدون أوردرات
                double sessionCost = 0.0;
                if (session.endTime != null) {
                  final duration = session.endTime!.difference(
                    session.startTime,
                  );
                  final hours = duration.inMinutes / 60.0;
                  sessionCost = hours * session.hourlyRate;
                }

                // حساب تكلفة الأوردرات
                final ordersCost = session.ordersTotal;
                final totalCost = sessionCost + ordersCost;

                // عد الأوردرات
                final ordersCount = session.ordersList.length;

                // تجميع إحصائيات الغرفة
                roomSessionCost += sessionCost;
                roomOrdersCost += ordersCost;
                roomTotalCost += totalCost;
                roomOrdersCount += ordersCount;

                // جمع الأسماء والأسعار للأوردرات
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
                  sessionCost.toStringAsFixed(2), // تكلفة الجلسة
                  ordersCost.toStringAsFixed(2), // تكلفة الأوردرات
                  totalCost.toStringAsFixed(2), // الإجمالي
                  ordersCount.toString(), // عدد الأوردرات
                  ordersDetails, // تفاصيل الأوردرات
                ]);
              }

              // Add summary row for this room
              sheet.appendRow([
                '',
                '',
                '',
                '',
                '',
                '',
                'Room Total Session Cost',
                'Room Total Orders Cost',
                'Room Total Cost',
                'Room Total Orders',
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

              // تحديث الإجماليات العامة
              totalSessionCostAllRooms += roomSessionCost;
              totalOrdersCostAllRooms += roomOrdersCost;
              grandTotalAllRooms += roomTotalCost;
              totalOrdersCount += roomOrdersCount;

              sheet.appendRow([]);
            }
          }

          // Add grand totals for all rooms
          sheet.appendRow([]);
          sheet.appendRow([
            '',
            '',
            '',
            '',
            '',
            '',
            'GRAND TOTAL SESSION COST',
            'GRAND TOTAL ORDERS COST',
            'GRAND TOTAL COST',
            'TOTAL ORDERS COUNT',
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

          // Add percentage breakdown
          sheet.appendRow([]);
          if (grandTotalAllRooms > 0) {
            final sessionPercentage = (totalSessionCostAllRooms /
                    grandTotalAllRooms *
                    100)
                .toStringAsFixed(1);
            final ordersPercentage = (totalOrdersCostAllRooms /
                    grandTotalAllRooms *
                    100)
                .toStringAsFixed(1);

            sheet.appendRow([
              '',
              '',
              '',
              '',
              '',
              '',
              'Percentage Breakdown',
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

          // Save file with safe filename
          final fileBytes = excel.encode();
          if (fileBytes == null) return;

          if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
            // 🖥 Desktop → Save directly
            final directory = await getApplicationDocumentsDirectory();
            final filePath = p.join(
              directory.path,
              'rooms_history_${getSafeTimestamp()}.xlsx',
            );

            final file = File(filePath);
            await file.writeAsBytes(fileBytes);

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Backup saved at $filePath")),
            );
          } else {
            // 📱 Mobile → Share Excel file
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
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error exporting: $e")),
          );
        }
      },
    );
  }
}
