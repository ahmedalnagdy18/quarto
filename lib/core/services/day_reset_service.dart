import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:quarto/core/services/system_export_service.dart';
import 'package:quarto/features/dashboard/domain/repository/dashboard_repository.dart';
import 'package:quarto/injection_container.dart';
import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DayResetService {
  DayResetService._();

  static final DashboardRepository _dashboardRepository =
      sl<DashboardRepository>();
  static final SupabaseClient _supabase = sl<SupabaseClient>();

  static bool get _isMobileDevice =>
      !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  static Future<void> startNewDay(BuildContext context) async {
    try {
      final backupFiles = await SystemExportService.exportFullSystemBackup();
      if (backupFiles.isEmpty) {
        throw Exception('Backup failed. Day reset was cancelled.');
      }

      await _dashboardRepository.startNewDay();
      await _clearExternalOrdersIfExists();
      await _clearRoomOutcomes();
      await _clearCafeData();

      if (_isMobileDevice) {
        await Share.shareXFiles(
          backupFiles.map(XFile.new).toList(),
          text: 'New day backup files',
        );
      }

      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              _isMobileDevice
                  ? 'Backup created and a new day started successfully.'
                  : 'Backup created and all data cleared for the new day.',
            ),
            backgroundColor: Colors.green,
          ),
        );
    } catch (error) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(error.toString().replaceFirst('Exception: ', '')),
            backgroundColor: Colors.red,
          ),
        );
      rethrow;
    }
  }

  static Future<void> _clearRoomOutcomes() async {
    await _supabase.from('room_outcomes').delete().not('id', 'is', null);
  }

  static Future<void> _clearCafeData() async {
    await _supabase.from('order_items').delete().not('id', 'is', null);
    await _supabase.from('orders').delete().not('id', 'is', null);
    await _supabase.from('cafe_outcomes').delete().not('id', 'is', null);
    await _supabase
        .from('cafe_tables')
        .update({'is_occupied': false})
        .not('id', 'is', null);
  }

  static Future<void> _clearExternalOrdersIfExists() async {
    try {
      await _dashboardRepository.clearAllExternalOrders();
    } on PostgrestException catch (error) {
      if (_isMissingExternalOrdersTable(error)) {
        return;
      }
      rethrow;
    }
  }

  static bool _isMissingExternalOrdersTable(PostgrestException error) {
    final message = error.message.toLowerCase();
    return message.contains('external_orders') &&
        (message.contains('could not find the table') ||
            message.contains('schema cache'));
  }
}
