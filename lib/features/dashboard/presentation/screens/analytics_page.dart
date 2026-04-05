import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:quarto/core/colors/app_colors.dart';
import 'package:quarto/features/cafe/data/model/cafe_outcomes_model.dart';
import 'package:quarto/features/cafe/data/model/cafe_tabels_model.dart';
import 'package:quarto/features/cafe/data/model/order_model.dart';
import 'package:quarto/features/cafe/domain/repository/cafe_repository.dart';
import 'package:quarto/features/cafe/presentation/utils/cafe_order_utils.dart';
import 'package:quarto/features/dashboard/data/model/room_model.dart';
import 'package:quarto/features/dashboard/data/model/room_outcomes_model.dart';
import 'package:quarto/features/dashboard/data/model/session_history_model.dart';
import 'package:quarto/features/dashboard/domain/repository/dashboard_repository.dart';
import 'package:quarto/injection_container.dart';

class AnalyticsPage extends StatefulWidget {
  const AnalyticsPage({super.key});

  @override
  State<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage> {
  final DashboardRepository _dashboardRepository = sl<DashboardRepository>();
  final CafeRepository _cafeRepository = sl<CafeRepository>();
  late Future<_AnalyticsSnapshot> _analyticsFuture;

  @override
  void initState() {
    super.initState();
    _analyticsFuture = _loadAnalytics();
  }

  Future<_AnalyticsSnapshot> _loadAnalytics() async {
    final rooms = await _dashboardRepository.getAllRooms();
    final roomHistories = <SessionHistory>[];
    for (final room in rooms) {
      roomHistories.addAll(await _dashboardRepository.getRoomHistory(room.id));
    }

    final roomOutcomes = await _dashboardRepository.getRoomOutcomesItems();
    final cafeOrders = await _cafeRepository.getOrders();
    final cafeTables = await _cafeRepository.getTables();
    final cafeOutcomes = await _cafeRepository.getCafeOutcomesItems();

    return _AnalyticsSnapshot.fromData(
      rooms: rooms,
      roomHistories: roomHistories,
      roomOutcomes: roomOutcomes,
      cafeOrders: cafeOrders,
      cafeTables: cafeTables,
      cafeOutcomes: cafeOutcomes,
    );
  }

  Future<void> _refresh() async {
    final future = _loadAnalytics();
    if (mounted) {
      setState(() => _analyticsFuture = future);
    }
    await future;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 30),
        child: FutureBuilder<_AnalyticsSnapshot>(
          future: _analyticsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return Center(
                child: CircularProgressIndicator(color: AppColors.yellowColor),
              );
            }

            if (snapshot.hasError || !snapshot.hasData) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Failed to load analytics',
                      style: TextStyle(color: Colors.white, fontSize: 18),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: _refresh,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }

            final data = snapshot.data!;
            return RefreshIndicator(
              onRefresh: _refresh,
              color: AppColors.yellowColor,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Image.asset('images/quarto_logo.png', scale: 4),
                        const Spacer(),
                        _DateChip(label: data.currentDayLabel),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Analytics Overview',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Monitor performance, track utilization, and uncover revenue insights for the current operating day.',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                    const SizedBox(height: 22),
                    const _SectionTitle(title: 'Key Performance Indicators'),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: _MetricCard(
                            title: 'Total Revenue',
                            value: _currency(data.totalRevenue),
                            accent: AppColors.yellowColor,
                            footer: 'PS + Cafe revenue today',
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: _MetricCard(
                            title: 'Net Profit',
                            value: _currency(data.netProfit),
                            accent: const Color(0xFF57E389),
                            footer: 'Revenue after expenses',
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: _MetricCard(
                            title: 'Expenses',
                            value: _currency(data.totalExpenses),
                            accent: const Color(0xFFFF8A65),
                            footer: 'Cafe + room outcomes',
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: _MetricCard(
                            title: 'Venue Utilization',
                            value:
                                '${data.utilizationRate.toStringAsFixed(0)}%',
                            accent: const Color(0xFF34D1BF),
                            footer:
                                '${data.activeUnits}/${data.totalUnits} active units',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _Panel(
                            title: 'Revenue Synergy',
                            subtitle:
                                'PlayStation vs cafe revenue flow across the current day',
                            child: _LineChartCard(
                              psSeries: data.hourlyPlayStationRevenue,
                              cafeSeries: data.hourlyCafeRevenue,
                            ),
                          ),
                        ),
                        const SizedBox(width: 18),
                        Expanded(
                          child: _Panel(
                            title: 'Revenue Composition Analysis',
                            subtitle:
                                'Overall revenue split between PlayStation and cafe',
                            child: _DonutAnalysisCard(
                              entries: [
                                _ChartEntry(
                                  label: 'PlayStation',
                                  value: data.playStationRevenue,
                                  color: const Color(0xFF2F37FF),
                                ),
                                _ChartEntry(
                                  label: 'Cafe',
                                  value: data.cafeRevenue,
                                  color: AppColors.yellowColor,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),
                    const Text(
                      'Cafe Performance Analysis',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Analyze cafe performance for the current operating day.',
                      style: TextStyle(color: Colors.white54, fontSize: 11),
                    ),
                    const SizedBox(height: 18),
                    const _SectionTitle(title: 'Key Performance Indicators'),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: _MetricCard(
                            title: 'Total Revenue',
                            value: _currency(data.cafeRevenue),
                            accent: AppColors.yellowColor,
                            footer: '${data.cafeOrderCount} total cafe orders',
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: _MetricCard(
                            title: 'Net Profit',
                            value: _currency(data.cafeNetProfit),
                            accent: const Color(0xFF57E389),
                            footer: 'After cafe expenses',
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: _MetricCard(
                            title: 'Expenses',
                            value: _currency(data.cafeExpenses),
                            accent: const Color(0xFFFF8A65),
                            footer: '${data.cafeOutcomesCount} expense records',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _Panel(
                            title: 'Orders Distribution',
                            subtitle:
                                'How today\'s cafe orders are split by source',
                            child: _DonutAnalysisCard(
                              entries: [
                                _ChartEntry(
                                  label: 'Table',
                                  value:
                                      data.cafeOrderDistribution['table'] ?? 0,
                                  color: AppColors.yellowColor,
                                ),
                                _ChartEntry(
                                  label: 'Takeaway',
                                  value:
                                      data.cafeOrderDistribution['takeaway'] ??
                                      0,
                                  color: const Color(0xFFFF7B00),
                                ),
                                _ChartEntry(
                                  label: 'Staff',
                                  value:
                                      data.cafeOrderDistribution['staff'] ?? 0,
                                  color: const Color(0xFF2F37FF),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 18),
                        Expanded(
                          child: _Panel(
                            title:
                                'Number Of Daily Orders For Top 5 Best Sellers',
                            subtitle:
                                'Most requested cafe items in the current day',
                            child: _HorizontalRankingCard(
                              items: data.topCafeItems,
                              unitLabel: 'orders',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),
                    const Text(
                      'PlayStation Overview',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Analyze utilization and station-by-station revenue yield for the current operating day.',
                      style: TextStyle(color: Colors.white54, fontSize: 11),
                    ),
                    const SizedBox(height: 18),
                    const _SectionTitle(title: 'Key Performance Indicators'),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: _MetricCard(
                            title: 'Total Revenue',
                            value: _currency(data.playStationRevenue),
                            accent: AppColors.yellowColor,
                            footer: '${data.rooms.length} gaming rooms',
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: _MetricCard(
                            title: 'Net Profit',
                            value: _currency(data.playStationNetProfit),
                            accent: const Color(0xFF57E389),
                            footer: 'After room expenses',
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: _MetricCard(
                            title: 'Expenses',
                            value: _currency(data.roomExpenses),
                            accent: const Color(0xFFFF8A65),
                            footer: '${data.roomOutcomesCount} expense records',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _Panel(
                            title: 'Top Revenue Generating Rooms',
                            subtitle:
                                'Highest performing rooms across ended and active sessions',
                            child: _HorizontalRankingCard(
                              items: data.topRooms,
                              unitLabel: 'EGP',
                            ),
                          ),
                        ),
                        const SizedBox(width: 18),
                        Expanded(
                          child: _Panel(
                            title: 'Rooms Revenue Mix By Console Type',
                            subtitle:
                                'Distribution of PlayStation revenue by PS type',
                            child: _DonutAnalysisCard(
                              entries: [
                                _ChartEntry(
                                  label: 'PS5',
                                  value: data.consoleTypeRevenue['ps5'] ?? 0,
                                  color: const Color(0xFF2F37FF),
                                ),
                                _ChartEntry(
                                  label: 'PS4',
                                  value: data.consoleTypeRevenue['ps4'] ?? 0,
                                  color: AppColors.yellowColor,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _AnalyticsSnapshot {
  _AnalyticsSnapshot({
    required this.currentDayLabel,
    required this.totalRevenue,
    required this.totalExpenses,
    required this.netProfit,
    required this.utilizationRate,
    required this.activeUnits,
    required this.totalUnits,
    required this.playStationRevenue,
    required this.playStationNetProfit,
    required this.roomExpenses,
    required this.cafeRevenue,
    required this.cafeNetProfit,
    required this.cafeExpenses,
    required this.hourlyPlayStationRevenue,
    required this.hourlyCafeRevenue,
    required this.cafeOrderDistribution,
    required this.topCafeItems,
    required this.topRooms,
    required this.consoleTypeRevenue,
    required this.rooms,
    required this.cafeOrderCount,
    required this.roomOutcomesCount,
    required this.cafeOutcomesCount,
  });

  final String currentDayLabel;
  final double totalRevenue;
  final double totalExpenses;
  final double netProfit;
  final double utilizationRate;
  final int activeUnits;
  final int totalUnits;
  final double playStationRevenue;
  final double playStationNetProfit;
  final double roomExpenses;
  final double cafeRevenue;
  final double cafeNetProfit;
  final double cafeExpenses;
  final Map<int, double> hourlyPlayStationRevenue;
  final Map<int, double> hourlyCafeRevenue;
  final Map<String, double> cafeOrderDistribution;
  final List<_RankedValue> topCafeItems;
  final List<_RankedValue> topRooms;
  final Map<String, double> consoleTypeRevenue;
  final List<Room> rooms;
  final int cafeOrderCount;
  final int roomOutcomesCount;
  final int cafeOutcomesCount;

  factory _AnalyticsSnapshot.fromData({
    required List<Room> rooms,
    required List<SessionHistory> roomHistories,
    required List<RoomOutcomesModel> roomOutcomes,
    required List<OrderModel> cafeOrders,
    required List<CafeTableModel> cafeTables,
    required List<CafeOutcomesModel> cafeOutcomes,
  }) {
    final now = DateTime.now();
    final currentDayLabel =
        'Current day - ${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';
    final endedSessions = roomHistories.where(
      (session) => session.endTime != null,
    );
    final roomRevenueById = <String, double>{};
    final consoleTypeRevenue = <String, double>{'ps5': 0, 'ps4': 0};
    final hourlyPlayStationRevenue = <int, double>{};
    double endedPlayStationRevenue = 0.0;

    for (final session in endedSessions) {
      endedPlayStationRevenue += session.totalCost;
      roomRevenueById.update(
        session.roomId,
        (value) => value + session.totalCost,
        ifAbsent: () => session.totalCost,
      );
      final consoleKey = (session.psType ?? '').toLowerCase();
      if (consoleTypeRevenue.containsKey(consoleKey)) {
        consoleTypeRevenue[consoleKey] =
            (consoleTypeRevenue[consoleKey] ?? 0) + session.totalCost;
      }
      final hour = session.endTime!.hour;
      hourlyPlayStationRevenue.update(
        hour,
        (value) => value + session.totalCost,
        ifAbsent: () => session.totalCost,
      );
    }

    double activePlayStationRevenue = 0.0;
    for (final room in rooms.where((room) => room.isOccupied)) {
      final activeRevenue = room.calculatedCost + room.ordersTotal;
      activePlayStationRevenue += activeRevenue;
      roomRevenueById.update(
        room.id,
        (value) => value + activeRevenue,
        ifAbsent: () => activeRevenue,
      );
      final consoleKey = (room.psType ?? '').toLowerCase();
      if (consoleTypeRevenue.containsKey(consoleKey)) {
        consoleTypeRevenue[consoleKey] =
            (consoleTypeRevenue[consoleKey] ?? 0) + activeRevenue;
      }
      hourlyPlayStationRevenue.update(
        now.hour,
        (value) => value + activeRevenue,
        ifAbsent: () => activeRevenue,
      );
    }
    final playStationRevenue =
        endedPlayStationRevenue + activePlayStationRevenue;
    final roomExpenses = roomOutcomes.fold<double>(
      0,
      (sum, item) => sum + (item.price * item.quantity),
    );
    final playStationNetProfit = playStationRevenue - roomExpenses;
    final cafeRevenue = cafeOrders.fold<double>(
      0,
      (sum, order) => sum + calculateOrderTotal(order),
    );
    final cafeExpenses = cafeOutcomes.fold<double>(
      0,
      (sum, item) => sum + (item.price * item.quantity),
    );
    final cafeNetProfit = cafeRevenue - cafeExpenses;
    final totalRevenue = playStationRevenue + cafeRevenue;
    final totalExpenses = roomExpenses + cafeExpenses;
    final netProfit = totalRevenue - totalExpenses;
    final totalUnits = rooms.length + cafeTables.length;
    final activeUnits =
        rooms.where((room) => room.isOccupied).length +
        cafeTables.where((table) => table.isOccupied).length;
    final utilizationRate = totalUnits == 0
        ? 0.0
        : (activeUnits / totalUnits) * 100;

    final hourlyCafeRevenue = <int, double>{};
    final cafeOrderDistribution = <String, double>{
      'table': 0,
      'takeaway': 0,
      'staff': 0,
    };
    final topCafeItemsMap = <String, double>{};

    for (final order in cafeOrders) {
      final orderDate = DateTime.tryParse(order.orderTime)?.toLocal();
      if (orderDate != null) {
        hourlyCafeRevenue.update(
          orderDate.hour,
          (value) => value + calculateOrderTotal(order),
          ifAbsent: () => calculateOrderTotal(order),
        );
      }
      final type = order.orderType.toLowerCase();
      if (cafeOrderDistribution.containsKey(type)) {
        cafeOrderDistribution[type] = (cafeOrderDistribution[type] ?? 0) + 1;
      }
      for (final item in order.items) {
        topCafeItemsMap.update(
          item.itemName,
          (value) => value + item.quantity,
          ifAbsent: () => item.quantity.toDouble(),
        );
      }
    }

    final roomNamesById = {for (final room in rooms) room.id: room.name};
    final topCafeItems =
        topCafeItemsMap.entries
            .map((entry) => _RankedValue(label: entry.key, value: entry.value))
            .toList()
          ..sort((a, b) => b.value.compareTo(a.value));
    final topRooms =
        roomRevenueById.entries
            .map(
              (entry) => _RankedValue(
                label: roomNamesById[entry.key] ?? 'Room ${entry.key}',
                value: entry.value,
              ),
            )
            .toList()
          ..sort((a, b) => b.value.compareTo(a.value));

    return _AnalyticsSnapshot(
      currentDayLabel: currentDayLabel,
      totalRevenue: totalRevenue,
      totalExpenses: totalExpenses,
      netProfit: netProfit,
      utilizationRate: utilizationRate,
      activeUnits: activeUnits,
      totalUnits: totalUnits,
      playStationRevenue: playStationRevenue,
      playStationNetProfit: playStationNetProfit,
      roomExpenses: roomExpenses,
      cafeRevenue: cafeRevenue,
      cafeNetProfit: cafeNetProfit,
      cafeExpenses: cafeExpenses,
      hourlyPlayStationRevenue: hourlyPlayStationRevenue,
      hourlyCafeRevenue: hourlyCafeRevenue,
      cafeOrderDistribution: cafeOrderDistribution,
      topCafeItems: topCafeItems.take(5).toList(),
      topRooms: topRooms.take(5).toList(),
      consoleTypeRevenue: consoleTypeRevenue,
      rooms: rooms,
      cafeOrderCount: cafeOrders.length,
      roomOutcomesCount: roomOutcomes.length,
      cafeOutcomesCount: cafeOutcomes.length,
    );
  }
}

class _RankedValue {
  const _RankedValue({required this.label, required this.value});
  final String label;
  final double value;
}

class _ChartEntry {
  const _ChartEntry({
    required this.label,
    required this.value,
    required this.color,
  });
  final String label;
  final double value;
  final Color color;
}

class _DateChip extends StatelessWidget {
  const _DateChip({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white24),
        color: Colors.black.withValues(alpha: 0.18),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.access_time, color: Colors.white70, size: 14),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.title,
    required this.value,
    required this.accent,
    required this.footer,
  });
  final String title;
  final String value;
  final Color accent;
  final String footer;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white.withValues(alpha: 0.05),
        border: Border.all(color: accent.withValues(alpha: 0.65)),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.12),
            blurRadius: 20,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: accent,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              footer,
              style: TextStyle(
                color: accent,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({
    required this.title,
    required this.subtitle,
    required this.child,
  });
  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: Colors.white.withValues(alpha: 0.05),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: const TextStyle(color: Colors.white54, fontSize: 10),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _LineChartCard extends StatelessWidget {
  const _LineChartCard({required this.psSeries, required this.cafeSeries});
  final Map<int, double> psSeries;
  final Map<int, double> cafeSeries;

  @override
  Widget build(BuildContext context) {
    final hours = {...psSeries.keys, ...cafeSeries.keys}.toList()..sort();
    final visibleHours = hours.isEmpty ? [DateTime.now().hour] : hours;
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: const [
            _LegendDot(color: Color(0xFF2F37FF), label: 'PlayStation'),
            SizedBox(width: 12),
            _LegendDot(color: Color(0xFFFFC300), label: 'Cafe'),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 190,
          child: CustomPaint(
            painter: _LineChartPainter(
              hours: visibleHours,
              psSeries: psSeries,
              cafeSeries: cafeSeries,
            ),
          ),
        ),
      ],
    );
  }
}

class _DonutAnalysisCard extends StatelessWidget {
  const _DonutAnalysisCard({required this.entries});
  final List<_ChartEntry> entries;

  @override
  Widget build(BuildContext context) {
    final total = entries.fold<double>(0, (sum, entry) => sum + entry.value);
    final visibleEntries = entries.where((entry) => entry.value > 0).toList();
    final displayEntries = visibleEntries.isEmpty
        ? [const _ChartEntry(label: 'No data', value: 1, color: Colors.white24)]
        : visibleEntries;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: displayEntries
              .map(
                (entry) => Padding(
                  padding: const EdgeInsets.only(left: 12),
                  child: _LegendDot(color: entry.color, label: entry.label),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 190,
          child: Row(
            children: [
              Expanded(
                child: CustomPaint(
                  painter: _DonutPainter(entries: displayEntries),
                  child: Center(
                    child: Text(
                      total == 0 ? '0%' : '100%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: displayEntries.map((entry) {
                    final percent = total == 0
                        ? 0.0
                        : (entry.value / total) * 100;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: entry.color,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              entry.label,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 11,
                              ),
                            ),
                          ),
                          Text(
                            '${percent.toStringAsFixed(0)}%',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _HorizontalRankingCard extends StatelessWidget {
  const _HorizontalRankingCard({required this.items, required this.unitLabel});
  final List<_RankedValue> items;
  final String unitLabel;

  @override
  Widget build(BuildContext context) {
    final safeItems = items.isEmpty
        ? [const _RankedValue(label: 'No data yet', value: 0)]
        : items;
    final maxValue = safeItems.fold<double>(
      0,
      (max, item) => math.max(max, item.value),
    );
    return Column(
      children: safeItems.map((item) {
        final progress = maxValue == 0 ? 0.0 : item.value / maxValue;
        return Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Row(
            children: [
              Expanded(
                flex: 4,
                child: Text(
                  item.label,
                  style: const TextStyle(color: Colors.white70, fontSize: 11),
                ),
              ),
              Expanded(
                flex: 8,
                child: Container(
                  height: 18,
                  decoration: BoxDecoration(
                    color: Colors.white12,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: progress.clamp(0.0, 1.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.yellowColor,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 58,
                child: Text(
                  item.value.toStringAsFixed(0),
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 10),
        ),
      ],
    );
  }
}

class _LineChartPainter extends CustomPainter {
  _LineChartPainter({
    required this.hours,
    required this.psSeries,
    required this.cafeSeries,
  });
  final List<int> hours;
  final Map<int, double> psSeries;
  final Map<int, double> cafeSeries;

  @override
  void paint(Canvas canvas, Size size) {
    const leftPad = 30.0;
    const bottomPad = 24.0;
    const topPad = 12.0;
    final chartWidth = size.width - leftPad - 8;
    final chartHeight = size.height - bottomPad - topPad;
    final origin = Offset(leftPad, topPad + chartHeight);
    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.08)
      ..strokeWidth = 1;

    for (int i = 0; i < 4; i++) {
      final y = topPad + (chartHeight / 3) * i;
      canvas.drawLine(Offset(leftPad, y), Offset(size.width, y), gridPaint);
    }
    canvas.drawLine(
      Offset(leftPad, topPad),
      Offset(leftPad, origin.dy),
      gridPaint,
    );
    canvas.drawLine(
      Offset(leftPad, origin.dy),
      Offset(size.width, origin.dy),
      gridPaint,
    );

    final maxValue = [
      ...psSeries.values,
      ...cafeSeries.values,
      1.0,
    ].fold<double>(0, (max, value) => math.max(max, value));

    Offset pointFor(int index, double value) {
      final x = hours.length == 1
          ? leftPad + (chartWidth / 2)
          : leftPad + (chartWidth * index / (hours.length - 1));
      final y = origin.dy - (value / maxValue) * chartHeight;
      return Offset(x, y);
    }

    final psPath = Path();
    final cafePath = Path();
    for (int i = 0; i < hours.length; i++) {
      final psPoint = pointFor(i, psSeries[hours[i]] ?? 0);
      final cafePoint = pointFor(i, cafeSeries[hours[i]] ?? 0);
      if (i == 0) {
        psPath.moveTo(psPoint.dx, psPoint.dy);
        cafePath.moveTo(cafePoint.dx, cafePoint.dy);
      } else {
        psPath.lineTo(psPoint.dx, psPoint.dy);
        cafePath.lineTo(cafePoint.dx, cafePoint.dy);
      }
      final labelPainter = TextPainter(
        text: TextSpan(
          text: '${hours[i].toString().padLeft(2, '0')}:00',
          style: const TextStyle(color: Colors.white54, fontSize: 9),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      labelPainter.paint(
        canvas,
        Offset(psPoint.dx - (labelPainter.width / 2), origin.dy + 6),
      );
    }

    canvas.drawPath(
      psPath,
      Paint()
        ..color = const Color(0xFF2F37FF)
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke,
    );
    canvas.drawPath(
      cafePath,
      Paint()
        ..color = AppColors.yellowColor
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(covariant _LineChartPainter oldDelegate) => true;
}

class _DonutPainter extends CustomPainter {
  _DonutPainter({required this.entries});
  final List<_ChartEntry> entries;

  @override
  void paint(Canvas canvas, Size size) {
    final total = entries.fold<double>(0, (sum, entry) => sum + entry.value);
    const strokeWidth = 28.0;
    final rect = Rect.fromCircle(
      center: Offset(size.width / 2, size.height / 2),
      radius: math.min(size.width, size.height) / 2 - strokeWidth,
    );
    double startAngle = -math.pi / 2;
    for (final entry in entries) {
      final sweep = total == 0 ? 0.0 : (entry.value / total) * math.pi * 2;
      final paint = Paint()
        ..color = entry.color
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth;
      canvas.drawArc(rect, startAngle, sweep, false, paint);
      startAngle += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) => true;
}

String _currency(double value) => '${value.toStringAsFixed(0)}\$';
