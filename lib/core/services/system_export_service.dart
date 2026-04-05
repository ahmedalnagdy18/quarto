import 'dart:io';

import 'package:excel/excel.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' hide Border, BorderStyle;
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:quarto/features/cafe/data/model/cafe_outcomes_model.dart';
import 'package:quarto/features/cafe/data/model/cafe_tabels_model.dart';
import 'package:quarto/features/cafe/data/model/order_model.dart';
import 'package:quarto/features/cafe/domain/repository/cafe_repository.dart';
import 'package:quarto/features/cafe/presentation/utils/cafe_order_utils.dart';
import 'package:quarto/features/dashboard/data/model/external_orders_model.dart';
import 'package:quarto/features/dashboard/data/model/room_model.dart';
import 'package:quarto/features/dashboard/data/model/room_outcomes_model.dart';
import 'package:quarto/features/dashboard/data/model/session_history_model.dart';
import 'package:quarto/features/dashboard/domain/repository/dashboard_repository.dart';
import 'package:quarto/injection_container.dart';
import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SystemExportService {
  SystemExportService._();

  static final DashboardRepository _dashboardRepository =
      sl<DashboardRepository>();
  static final CafeRepository _cafeRepository = sl<CafeRepository>();

  static bool get _isMobileDevice =>
      !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  static String _timestamp() {
    final now = DateTime.now();
    return '${now.year}_${now.month.toString().padLeft(2, '0')}_${now.day.toString().padLeft(2, '0')}_${now.hour.toString().padLeft(2, '0')}_${now.minute.toString().padLeft(2, '0')}';
  }

  static Future<void> exportRoomsReport(
    BuildContext context, {
    Room? room,
  }) async {
    try {
      final filePath = await _exportRoomsReportFile(room: room);
      if (filePath == null) {
        throw Exception('Failed to generate export file.');
      }

      if (!context.mounted) {
        return;
      }

      await _deliverFile(
        context,
        filePath: filePath,
        successMessage: room == null
            ? 'Rooms export saved successfully.'
            : '${room.name} export saved successfully.',
      );
    } catch (error) {
      if (!context.mounted) {
        return;
      }
      _showSnackBar(
        context,
        error.toString().replaceFirst('Exception: ', ''),
        isError: true,
      );
    }
  }

  static Future<void> exportCafeReport(
    BuildContext context, {
    CafeTableModel? table,
  }) async {
    try {
      final filePath = await _exportCafeReportFile(table: table);
      if (filePath == null) {
        throw Exception('Failed to generate export file.');
      }

      if (!context.mounted) {
        return;
      }

      await _deliverFile(
        context,
        filePath: filePath,
        successMessage: table == null
            ? 'Cafe export saved successfully.'
            : '${table.tableName} export saved successfully.',
      );
    } catch (error) {
      if (!context.mounted) {
        return;
      }
      _showSnackBar(
        context,
        error.toString().replaceFirst('Exception: ', ''),
        isError: true,
      );
    }
  }

  static Future<List<String>> exportFullSystemBackup() async {
    final roomPath = await _exportRoomsReportFile();
    final cafePath = await _exportCafeReportFile();

    return [
      if (roomPath != null) roomPath,
      if (cafePath != null) cafePath,
    ];
  }

  static Future<String?> _exportRoomsReportFile({Room? room}) async {
    final rooms = room == null
        ? await _dashboardRepository.getAllRooms()
        : [room];
    final historiesByRoom = <String, List<SessionHistory>>{};

    for (final currentRoom in rooms) {
      historiesByRoom[currentRoom.id] = await _dashboardRepository
          .getRoomHistory(currentRoom.id);
    }

    final report = _RoomsReportData(
      rooms: rooms,
      historiesByRoom: historiesByRoom,
      roomOutcomes: room == null
          ? await _dashboardRepository.getRoomOutcomesItems()
          : const <RoomOutcomesModel>[],
      externalOrders: room == null
          ? await _safeGetExternalOrders()
          : const <ExternalOrdersModel>[],
      selectedRoom: room,
    );

    if (_isMobileDevice) {
      final bytes = await _buildRoomsPdf(report);
      return _saveBytes(bytes, report.fileName, 'pdf');
    }

    final bytes = _buildRoomsExcel(report);
    return _saveBytes(bytes, report.fileName, 'xlsx');
  }

  static Future<String?> _exportCafeReportFile({CafeTableModel? table}) async {
    final allTables = await _cafeRepository.getTables();
    final tables = table == null
        ? allTables
        : allTables.where((item) => item.id == table.id).toList();
    final orders = table == null
        ? await _cafeRepository.getOrders()
        : await _cafeRepository.getOrdersByTable(table.id);

    final report = _CafeReportData(
      tables: tables,
      allTables: allTables,
      orders: orders,
      cafeOutcomes: table == null
          ? await _cafeRepository.getCafeOutcomesItems()
          : const <CafeOutcomesModel>[],
      selectedTable: table,
    );

    if (_isMobileDevice) {
      final bytes = await _buildCafePdf(report);
      return _saveBytes(bytes, report.fileName, 'pdf');
    }

    final bytes = _buildCafeExcel(report);
    return _saveBytes(bytes, report.fileName, 'xlsx');
  }

  static Uint8List _buildRoomsExcel(_RoomsReportData report) {
    final excel = Excel.createExcel();
    final summarySheet = excel['Summary'];
    _writeReportHeader(
      summarySheet,
      title: report.title,
      subtitle: 'Rooms summary and daily snapshot',
      columnsCount: 4,
    );
    _setColumnWidths(summarySheet, [24, 18, 18, 18]);
    _writeKeyValueTable(
      summarySheet,
      startRow: 3,
      rows: _buildRoomsSummaryRows(report),
    );

    final roomsSheet = excel['Rooms'];
    _writeReportHeader(
      roomsSheet,
      title: '${report.title} - Rooms',
      subtitle: 'Current rooms status overview',
      columnsCount: 7,
    );
    _setColumnWidths(roomsSheet, [22, 14, 12, 14, 14, 16, 16]);
    _writeTableSection(
      roomsSheet,
      startRow: 3,
      sectionTitle: 'Rooms Snapshot',
      headers: const [
        'Room',
        'Status',
        'Rate',
        'PS Type',
        'Mode',
        'Current Orders',
        'Current Cost',
      ],
      rows: report.rooms
          .map(
            (room) => [
              room.name,
              room.isOccupied ? 'Occupied' : 'Free',
              _money(room.hourlyRate),
              room.psTypeDisplay ?? '--',
              room.sessionTypeDisplay ?? '--',
              _money(room.ordersTotal),
              _money(room.calculatedCost),
            ],
          )
          .toList(),
    );

    final sessionsSheet = excel['Sessions'];
    _writeReportHeader(
      sessionsSheet,
      title: '${report.title} - Sessions',
      subtitle: 'Detailed room session history',
      columnsCount: 10,
    );
    _setColumnWidths(sessionsSheet, [18, 20, 20, 14, 14, 14, 14, 16, 30, 42]);
    final sessionRows = <List<dynamic>>[];
    for (final entry in report.historiesByRoom.entries) {
      final roomName = report.roomNameById(entry.key);
      for (final session in entry.value) {
        sessionRows.add([
          roomName,
          _formatDateTime(session.startTime),
          session.endTime == null
              ? 'Running'
              : _formatDateTime(session.endTime!),
          session.formattedDuration,
          _money(_sessionFee(session)),
          _money(session.ordersTotal),
          _money(session.totalCost),
          session.sessionTypeInfo.isEmpty ? '--' : session.sessionTypeInfo,
          _sessionComments(session),
          _roomOrdersDetails(session),
        ]);
      }
    }
    _writeTableSection(
      sessionsSheet,
      startRow: 3,
      sectionTitle: 'Sessions History',
      headers: const [
        'Room',
        'Start',
        'End',
        'Duration',
        'Session Fee',
        'Orders Fee',
        'Total',
        'Type',
        'Comments',
        'Orders Details',
      ],
      rows: sessionRows,
    );

    if (report.roomOutcomes.isNotEmpty) {
      final outcomesSheet = excel['Room Outcomes'];
      _writeReportHeader(
        outcomesSheet,
        title: '${report.title} - Room Outcomes',
        subtitle: 'Expenses and materials used',
        columnsCount: 5,
      );
      _setColumnWidths(outcomesSheet, [28, 12, 14, 14, 18]);
      _writeTableSection(
        outcomesSheet,
        startRow: 3,
        sectionTitle: 'Room Outcomes',
        headers: const ['Material', 'Quantity', 'Unit Price', 'Total', 'Date'],
        rows: report.roomOutcomes
            .map(
              (item) => [
                item.material,
                item.quantity.toString(),
                _money(item.price),
                _money(item.price * item.quantity),
                item.date ?? '--',
              ],
            )
            .toList(),
      );
    }

    if (report.externalOrders.isNotEmpty) {
      final externalSheet = excel['External Orders'];
      _writeReportHeader(
        externalSheet,
        title: '${report.title} - External Orders',
        subtitle: 'External orders summary',
        columnsCount: 5,
      );
      _setColumnWidths(externalSheet, [14, 18, 42, 14, 12]);
      _writeTableSection(
        externalSheet,
        startRow: 3,
        sectionTitle: 'External Orders',
        headers: const ['Order ID', 'Label', 'Items', 'Total', 'Paid'],
        rows: report.externalOrders
            .map(
              (order) => [
                order.id,
                order.table,
                order.order.map((item) => item.name).join(', '),
                _money(_externalOrderTotal(order)),
                order.payment ? 'Yes' : 'No',
              ],
            )
            .toList(),
      );
    }

    final bytes = excel.encode();
    return Uint8List.fromList(bytes ?? <int>[]);
  }

  static Uint8List _buildCafeExcel(_CafeReportData report) {
    final excel = Excel.createExcel();
    final summarySheet = excel['Summary'];
    _writeReportHeader(
      summarySheet,
      title: report.title,
      subtitle: 'Cafe summary and orders overview',
      columnsCount: 4,
    );
    _setColumnWidths(summarySheet, [24, 18, 18, 18]);
    _writeKeyValueTable(
      summarySheet,
      startRow: 3,
      rows: report.summaryRows,
    );

    final tablesSheet = excel['Tables'];
    _writeReportHeader(
      tablesSheet,
      title: '${report.title} - Tables',
      subtitle: 'Current cafe tables status',
      columnsCount: 4,
    );
    _setColumnWidths(tablesSheet, [22, 14, 16, 16]);
    final tableRows = <List<dynamic>>[];
    for (final table in report.tables) {
      final latestOrder = latestOrderForTable(table.id, report.orders);
      tableRows.add([
        table.tableName,
        table.isOccupied ? 'Occupied' : 'Free',
        latestOrder?.id ?? '--',
        latestOrder == null ? '0.00' : _money(calculateOrderTotal(latestOrder)),
      ]);
    }
    _writeTableSection(
      tablesSheet,
      startRow: 3,
      sectionTitle: 'Tables Snapshot',
      headers: const ['Table', 'Status', 'Latest Order', 'Latest Total'],
      rows: tableRows,
    );

    final ordersSheet = excel['Orders'];
    _writeReportHeader(
      ordersSheet,
      title: '${report.title} - Orders',
      subtitle: 'Detailed orders history',
      columnsCount: 8,
    );
    _setColumnWidths(ordersSheet, [14, 14, 18, 20, 20, 20, 14, 14]);
    final orderRows = <List<dynamic>>[];
    for (final order in report.orders) {
      orderRows.add([
        order.id,
        order.orderType,
        report.tableNameById(order.tableId) ?? '--',
        order.customerName ?? '--',
        order.staffName ?? '--',
        _formatOrderDateTime(order.orderTime),
        order.items.length.toString(),
        _money(calculateOrderTotal(order)),
      ]);
    }
    _writeTableSection(
      ordersSheet,
      startRow: 3,
      sectionTitle: 'Orders',
      headers: const [
        'Order ID',
        'Type',
        'Table',
        'Customer',
        'Staff',
        'Time',
        'Items Count',
        'Total',
      ],
      rows: orderRows,
    );

    final itemsSheet = excel['Order Items'];
    _writeReportHeader(
      itemsSheet,
      title: '${report.title} - Order Items',
      subtitle: 'All sold items grouped by order',
      columnsCount: 5,
    );
    _setColumnWidths(itemsSheet, [14, 28, 12, 14, 14]);
    final itemRows = <List<dynamic>>[];
    for (final order in report.orders) {
      for (final item in order.items) {
        itemRows.add([
          order.id,
          item.itemName,
          item.quantity.toString(),
          _money(item.price),
          _money(item.price * item.quantity),
        ]);
      }
    }
    _writeTableSection(
      itemsSheet,
      startRow: 3,
      sectionTitle: 'Order Items',
      headers: const [
        'Order ID',
        'Item',
        'Quantity',
        'Unit Price',
        'Line Total',
      ],
      rows: itemRows,
    );

    if (report.cafeOutcomes.isNotEmpty) {
      final outcomesSheet = excel['Cafe Outcomes'];
      _writeReportHeader(
        outcomesSheet,
        title: '${report.title} - Cafe Outcomes',
        subtitle: 'Cafe expenses summary',
        columnsCount: 5,
      );
      _setColumnWidths(outcomesSheet, [28, 12, 14, 14, 18]);
      _writeTableSection(
        outcomesSheet,
        startRow: 3,
        sectionTitle: 'Cafe Outcomes',
        headers: const ['Material', 'Quantity', 'Unit Price', 'Total', 'Date'],
        rows: report.cafeOutcomes
            .map(
              (item) => [
                item.material,
                item.quantity.toString(),
                _money(item.price),
                _money(item.price * item.quantity),
                item.date ?? '--',
              ],
            )
            .toList(),
      );
    }

    final bytes = excel.encode();
    return Uint8List.fromList(bytes ?? <int>[]);
  }

  static Future<Uint8List> _buildRoomsPdf(_RoomsReportData report) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        build: (context) => [
          pw.Header(level: 0, child: pw.Text(report.title)),
          pw.TableHelper.fromTextArray(data: _buildRoomsSummaryRows(report)),
          pw.SizedBox(height: 18),
          pw.Text(
            'Rooms Snapshot',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),
          pw.TableHelper.fromTextArray(
            headers: const [
              'Room',
              'Status',
              'Rate',
              'PS Type',
              'Mode',
              'Current Orders',
              'Current Cost',
            ],
            data: report.rooms
                .map(
                  (room) => [
                    room.name,
                    room.isOccupied ? 'Occupied' : 'Free',
                    _money(room.hourlyRate),
                    room.psTypeDisplay ?? '--',
                    room.sessionTypeDisplay ?? '--',
                    _money(room.ordersTotal),
                    _money(room.calculatedCost),
                  ],
                )
                .toList(),
          ),
          pw.SizedBox(height: 18),
          pw.Text(
            'Sessions',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),
          pw.TableHelper.fromTextArray(
            headers: const [
              'Room',
              'Start',
              'End',
              'Duration',
              'Session',
              'Orders',
              'Total',
            ],
            data: report.allSessions
                .map(
                  (session) => [
                    report.roomNameById(session.roomId),
                    _formatDateTime(session.startTime),
                    session.endTime == null
                        ? 'Running'
                        : _formatDateTime(session.endTime!),
                    session.formattedDuration,
                    _money(_sessionFee(session)),
                    _money(session.ordersTotal),
                    _money(session.totalCost),
                  ],
                )
                .toList(),
          ),
          if (report.roomOutcomes.isNotEmpty) ...[
            pw.SizedBox(height: 18),
            pw.Text(
              'Room Outcomes',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
            pw.TableHelper.fromTextArray(
              headers: const ['Material', 'Qty', 'Unit Price', 'Total'],
              data: report.roomOutcomes
                  .map(
                    (item) => [
                      item.material,
                      item.quantity.toString(),
                      _money(item.price),
                      _money(item.price * item.quantity),
                    ],
                  )
                  .toList(),
            ),
          ],
          if (report.externalOrders.isNotEmpty) ...[
            pw.SizedBox(height: 18),
            pw.Text(
              'External Orders',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
            pw.TableHelper.fromTextArray(
              headers: const ['ID', 'Label', 'Items', 'Total', 'Paid'],
              data: report.externalOrders
                  .map(
                    (order) => [
                      order.id,
                      order.table,
                      order.order.map((item) => item.name).join(', '),
                      _money(_externalOrderTotal(order)),
                      order.payment ? 'Yes' : 'No',
                    ],
                  )
                  .toList(),
            ),
          ],
        ],
      ),
    );

    return Uint8List.fromList(await pdf.save());
  }

  static Future<Uint8List> _buildCafePdf(_CafeReportData report) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        build: (context) => [
          pw.Header(level: 0, child: pw.Text(report.title)),
          pw.TableHelper.fromTextArray(data: report.summaryRows),
          pw.SizedBox(height: 18),
          pw.Text(
            'Tables Snapshot',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),
          pw.TableHelper.fromTextArray(
            headers: const ['Table', 'Status', 'Latest Order', 'Latest Total'],
            data: report.tables.map((table) {
              final latestOrder = latestOrderForTable(table.id, report.orders);
              return [
                table.tableName,
                table.isOccupied ? 'Occupied' : 'Free',
                latestOrder?.id ?? '--',
                latestOrder == null
                    ? '0.00'
                    : _money(calculateOrderTotal(latestOrder)),
              ];
            }).toList(),
          ),
          pw.SizedBox(height: 18),
          pw.Text(
            'Orders',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),
          pw.TableHelper.fromTextArray(
            headers: const ['ID', 'Type', 'Table', 'Time', 'Items', 'Total'],
            data: report.orders
                .map(
                  (order) => [
                    order.id,
                    order.orderType,
                    report.tableNameById(order.tableId) ?? '--',
                    _formatOrderDateTime(order.orderTime),
                    order.items.length.toString(),
                    _money(calculateOrderTotal(order)),
                  ],
                )
                .toList(),
          ),
          if (report.cafeOutcomes.isNotEmpty) ...[
            pw.SizedBox(height: 18),
            pw.Text(
              'Cafe Outcomes',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
            pw.TableHelper.fromTextArray(
              headers: const ['Material', 'Qty', 'Unit Price', 'Total'],
              data: report.cafeOutcomes
                  .map(
                    (item) => [
                      item.material,
                      item.quantity.toString(),
                      _money(item.price),
                      _money(item.price * item.quantity),
                    ],
                  )
                  .toList(),
            ),
          ],
        ],
      ),
    );

    return Uint8List.fromList(await pdf.save());
  }

  static Future<String?> _saveBytes(
    Uint8List bytes,
    String fileName,
    String extension,
  ) async {
    final directory = await _resolveExportDirectory();
    final file = File('${directory.path}/$fileName.$extension');
    await file.writeAsBytes(bytes, flush: true);
    return file.path;
  }

  static Future<Directory> _resolveExportDirectory() async {
    if (_isMobileDevice) {
      return getTemporaryDirectory();
    }

    final downloadsDirectory = await getDownloadsDirectory();
    if (downloadsDirectory != null) {
      return downloadsDirectory;
    }

    return getApplicationDocumentsDirectory();
  }

  static Future<void> _deliverFile(
    BuildContext context, {
    required String filePath,
    required String successMessage,
  }) async {
    if (_isMobileDevice) {
      await Share.shareXFiles([XFile(filePath)], text: successMessage);
      return;
    }

    _showSnackBar(context, '$successMessage\n$filePath');
  }

  static void _showSnackBar(
    BuildContext context,
    String message, {
    bool isError = false,
  }) {
    if (!context.mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? Colors.red : Colors.green,
        ),
      );
  }

  static List<List<String>> _buildRoomsSummaryRows(_RoomsReportData report) {
    final sessions = report.allSessions;
    final totalRevenue = sessions.fold<double>(
      0,
      (sum, session) => sum + session.totalCost,
    );
    final ordersRevenue = sessions.fold<double>(
      0,
      (sum, session) => sum + session.ordersTotal,
    );
    final sessionRevenue = totalRevenue - ordersRevenue;
    final expenses = report.roomOutcomes.fold<double>(
      0,
      (sum, item) => sum + (item.price * item.quantity),
    );

    return [
      ['Report', report.title],
      ['Generated At', DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())],
      ['Rooms Count', report.rooms.length.toString()],
      ['Sessions Count', sessions.length.toString()],
      ['Session Revenue', _money(sessionRevenue)],
      ['Orders Revenue', _money(ordersRevenue)],
      ['Total Revenue', _money(totalRevenue)],
      ['Expenses', _money(expenses)],
      ['Net Profit', _money(totalRevenue - expenses)],
    ];
  }

  static void _writeReportHeader(
    Sheet sheet, {
    required String title,
    required String subtitle,
    required int columnsCount,
  }) {
    sheet.appendRow(List<dynamic>.filled(columnsCount, ''));
    final titleCell = sheet.cell(
      CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0),
    );
    titleCell.value = title;
    titleCell.cellStyle = _titleCellStyle();

    if (columnsCount > 1) {
      sheet.merge(
        CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0),
        CellIndex.indexByColumnRow(columnIndex: columnsCount - 1, rowIndex: 0),
      );
    }

    sheet.appendRow(List<dynamic>.filled(columnsCount, ''));
    final subtitleCell = sheet.cell(
      CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 1),
    );
    subtitleCell.value = subtitle;
    subtitleCell.cellStyle = _subtitleCellStyle();

    if (columnsCount > 1) {
      sheet.merge(
        CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 1),
        CellIndex.indexByColumnRow(columnIndex: columnsCount - 1, rowIndex: 1),
      );
    }
  }

  static int _writeKeyValueTable(
    Sheet sheet, {
    required int startRow,
    required List<List<String>> rows,
  }) {
    _ensureRowPosition(sheet, startRow);
    var currentRow = startRow;
    for (final row in rows) {
      sheet.appendRow([row[0], row[1], '', '']);
      _styleRange(
        sheet,
        rowIndex: currentRow,
        fromColumn: 0,
        toColumn: 3,
        style: _bodyCellStyle(),
      );
      _styleCell(
        sheet,
        rowIndex: currentRow,
        columnIndex: 0,
        style: _summaryLabelStyle(),
      );
      _styleCell(
        sheet,
        rowIndex: currentRow,
        columnIndex: 1,
        style: _summaryValueStyle(),
      );
      currentRow++;
    }
    return currentRow;
  }

  static int _writeTableSection(
    Sheet sheet, {
    required int startRow,
    required String sectionTitle,
    required List<String> headers,
    required List<List<dynamic>> rows,
  }) {
    _ensureRowPosition(sheet, startRow);
    var currentRow = startRow;
    sheet.appendRow(List<dynamic>.filled(headers.length, ''));
    final titleCell = sheet.cell(
      CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow),
    );
    titleCell.value = sectionTitle;
    titleCell.cellStyle = _sectionTitleStyle();
    if (headers.length > 1) {
      sheet.merge(
        CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow),
        CellIndex.indexByColumnRow(
          columnIndex: headers.length - 1,
          rowIndex: currentRow,
        ),
      );
    }
    currentRow++;

    sheet.appendRow(headers);
    _styleRange(
      sheet,
      rowIndex: currentRow,
      fromColumn: 0,
      toColumn: headers.length - 1,
      style: _tableHeaderStyle(),
    );
    currentRow++;

    if (rows.isEmpty) {
      sheet.appendRow([
        'No data available',
        ...List.filled(headers.length - 1, ''),
      ]);
      _styleRange(
        sheet,
        rowIndex: currentRow,
        fromColumn: 0,
        toColumn: headers.length - 1,
        style: _emptyStateStyle(),
      );
      currentRow++;
      return currentRow;
    }

    for (final row in rows) {
      sheet.appendRow(row);
      _styleRange(
        sheet,
        rowIndex: currentRow,
        fromColumn: 0,
        toColumn: headers.length - 1,
        style: _bodyCellStyle(),
      );
      currentRow++;
    }

    return currentRow;
  }

  static void _setColumnWidths(Sheet sheet, List<double> widths) {
    for (var index = 0; index < widths.length; index++) {
      sheet.setColWidth(index, widths[index]);
    }
  }

  static void _ensureRowPosition(Sheet sheet, int startRow) {
    while (sheet.maxRows < startRow) {
      sheet.appendRow(['']);
    }
  }

  static void _styleRange(
    Sheet sheet, {
    required int rowIndex,
    required int fromColumn,
    required int toColumn,
    required CellStyle style,
  }) {
    for (var column = fromColumn; column <= toColumn; column++) {
      _styleCell(
        sheet,
        rowIndex: rowIndex,
        columnIndex: column,
        style: style,
      );
    }
  }

  static void _styleCell(
    Sheet sheet, {
    required int rowIndex,
    required int columnIndex,
    required CellStyle style,
  }) {
    sheet
            .cell(
              CellIndex.indexByColumnRow(
                columnIndex: columnIndex,
                rowIndex: rowIndex,
              ),
            )
            .cellStyle =
        style;
  }

  static Border _thinBorder([String color = 'FF2B2F66']) => Border(
    borderStyle: BorderStyle.Thin,
    borderColorHex: color,
  );

  static CellStyle _titleCellStyle() => CellStyle(
    bold: true,
    fontSize: 16,
    fontColorHex: 'FFFFFFFF',
    backgroundColorHex: 'FF11133E',
    horizontalAlign: HorizontalAlign.Center,
    verticalAlign: VerticalAlign.Center,
  );

  static CellStyle _subtitleCellStyle() => CellStyle(
    italic: true,
    fontColorHex: 'FFB9C0FF',
    backgroundColorHex: 'FF1A1E54',
    horizontalAlign: HorizontalAlign.Center,
    verticalAlign: VerticalAlign.Center,
  );

  static CellStyle _sectionTitleStyle() => CellStyle(
    bold: true,
    fontSize: 12,
    fontColorHex: 'FF11133E',
    backgroundColorHex: 'FFF7C600',
    horizontalAlign: HorizontalAlign.Left,
    verticalAlign: VerticalAlign.Center,
  );

  static CellStyle _tableHeaderStyle() => CellStyle(
    bold: true,
    fontColorHex: 'FFFFFFFF',
    backgroundColorHex: 'FF28306D',
    horizontalAlign: HorizontalAlign.Center,
    verticalAlign: VerticalAlign.Center,
    textWrapping: TextWrapping.WrapText,
    leftBorder: _thinBorder(),
    rightBorder: _thinBorder(),
    topBorder: _thinBorder(),
    bottomBorder: _thinBorder(),
  );

  static CellStyle _bodyCellStyle() => CellStyle(
    fontColorHex: 'FF111111',
    backgroundColorHex: 'FFF8F9FF',
    horizontalAlign: HorizontalAlign.Left,
    verticalAlign: VerticalAlign.Center,
    textWrapping: TextWrapping.WrapText,
    leftBorder: _thinBorder('FFD7DCF5'),
    rightBorder: _thinBorder('FFD7DCF5'),
    topBorder: _thinBorder('FFD7DCF5'),
    bottomBorder: _thinBorder('FFD7DCF5'),
  );

  static CellStyle _summaryLabelStyle() => CellStyle(
    bold: true,
    fontColorHex: 'FF11133E',
    backgroundColorHex: 'FFE9ECFF',
    leftBorder: _thinBorder('FFD7DCF5'),
    rightBorder: _thinBorder('FFD7DCF5'),
    topBorder: _thinBorder('FFD7DCF5'),
    bottomBorder: _thinBorder('FFD7DCF5'),
  );

  static CellStyle _summaryValueStyle() => CellStyle(
    bold: true,
    fontColorHex: 'FF0C6B3F',
    backgroundColorHex: 'FFF2FFF7',
    leftBorder: _thinBorder('FFD7DCF5'),
    rightBorder: _thinBorder('FFD7DCF5'),
    topBorder: _thinBorder('FFD7DCF5'),
    bottomBorder: _thinBorder('FFD7DCF5'),
  );

  static CellStyle _emptyStateStyle() => CellStyle(
    italic: true,
    fontColorHex: 'FF666666',
    backgroundColorHex: 'FFF4F4F4',
    horizontalAlign: HorizontalAlign.Center,
    verticalAlign: VerticalAlign.Center,
    leftBorder: _thinBorder('FFD7DCF5'),
    rightBorder: _thinBorder('FFD7DCF5'),
    topBorder: _thinBorder('FFD7DCF5'),
    bottomBorder: _thinBorder('FFD7DCF5'),
  );

  static String _formatDateTime(DateTime value) =>
      DateFormat('yyyy-MM-dd HH:mm').format(value);

  static String _formatOrderDateTime(String value) {
    final parsed = DateTime.tryParse(value)?.toLocal();
    if (parsed == null) {
      return '--';
    }
    return _formatDateTime(parsed);
  }

  static String _money(double value) => value.toStringAsFixed(2);

  static double _sessionFee(SessionHistory session) {
    final fee = session.totalCost - session.ordersTotal;
    return fee < 0 ? 0.0 : fee;
  }

  static String _sessionComments(SessionHistory session) {
    if (session.comments == null || session.comments!.isEmpty) {
      return '--';
    }
    return session.comments!.map((item) => item.toString()).join(' | ');
  }

  static String _roomOrdersDetails(SessionHistory session) {
    if (session.ordersList.isEmpty) {
      return '--';
    }

    return session.ordersList
        .map((item) => '${item.name} (${_money(item.price)})')
        .join(', ');
  }

  static double _externalOrderTotal(ExternalOrdersModel order) {
    return order.order.fold<double>(0, (sum, item) => sum + item.price);
  }

  static Future<List<ExternalOrdersModel>> _safeGetExternalOrders() async {
    try {
      return await _dashboardRepository.getExternalOrders();
    } on PostgrestException catch (error) {
      if (_isMissingExternalOrdersTable(error)) {
        return const <ExternalOrdersModel>[];
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

class _RoomsReportData {
  _RoomsReportData({
    required this.rooms,
    required this.historiesByRoom,
    required this.roomOutcomes,
    required this.externalOrders,
    required this.selectedRoom,
  });

  final List<Room> rooms;
  final Map<String, List<SessionHistory>> historiesByRoom;
  final List<RoomOutcomesModel> roomOutcomes;
  final List<ExternalOrdersModel> externalOrders;
  final Room? selectedRoom;

  String get title => selectedRoom == null
      ? 'Rooms Daily Backup'
      : '${selectedRoom!.name} Backup';

  String get fileName => selectedRoom == null
      ? 'rooms_backup_${SystemExportService._timestamp()}'
      : '${selectedRoom!.name.replaceAll(' ', '_').toLowerCase()}_backup_${SystemExportService._timestamp()}';

  List<SessionHistory> get allSessions =>
      historiesByRoom.values.expand((items) => items).toList();

  String roomNameById(String roomId) {
    for (final room in rooms) {
      if (room.id == roomId) {
        return room.name;
      }
    }
    return selectedRoom?.name ?? roomId;
  }
}

class _CafeReportData {
  _CafeReportData({
    required this.tables,
    required this.allTables,
    required this.orders,
    required this.cafeOutcomes,
    required this.selectedTable,
  });

  final List<CafeTableModel> tables;
  final List<CafeTableModel> allTables;
  final List<OrderModel> orders;
  final List<CafeOutcomesModel> cafeOutcomes;
  final CafeTableModel? selectedTable;

  String get title => selectedTable == null
      ? 'Cafe Daily Backup'
      : '${selectedTable!.tableName} Backup';

  String get fileName => selectedTable == null
      ? 'cafe_backup_${SystemExportService._timestamp()}'
      : '${selectedTable!.tableName.replaceAll(' ', '_').toLowerCase()}_backup_${SystemExportService._timestamp()}';

  List<List<String>> get summaryRows {
    final ordersTotal = orders.fold<double>(
      0,
      (sum, order) => sum + calculateOrderTotal(order),
    );
    final expenses = cafeOutcomes.fold<double>(
      0,
      (sum, item) => sum + (item.price * item.quantity),
    );

    return [
      ['Report', title],
      ['Generated At', DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())],
      ['Tables Count', tables.length.toString()],
      ['Orders Count', orders.length.toString()],
      ['Orders Revenue', SystemExportService._money(ordersTotal)],
      ['Expenses', SystemExportService._money(expenses)],
      ['Net Profit', SystemExportService._money(ordersTotal - expenses)],
    ];
  }

  String? tableNameById(String? tableId) {
    if (tableId == null) {
      return null;
    }

    for (final table in allTables) {
      if (table.id == tableId) {
        return table.tableName;
      }
    }

    return null;
  }
}
