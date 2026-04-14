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

class MobileAnalyticsPage extends StatefulWidget {
  const MobileAnalyticsPage({super.key});

  @override
  State<MobileAnalyticsPage> createState() => _MobileAnalyticsPageState();
}

class _MobileAnalyticsPageState extends State<MobileAnalyticsPage> {
  final DashboardRepository _dashboardRepository = sl<DashboardRepository>();
  final CafeRepository _cafeRepository = sl<CafeRepository>();
  late Future<_MobileAnalyticsSnapshot> _snapshotFuture;

  @override
  void initState() {
    super.initState();
    _snapshotFuture = _loadSnapshot();
  }

  Future<_MobileAnalyticsSnapshot> _loadSnapshot() async {
    final rooms = await _dashboardRepository.getAllRooms();
    final roomHistories = <SessionHistory>[];
    for (final room in rooms) {
      roomHistories.addAll(await _dashboardRepository.getRoomHistory(room.id));
    }

    final roomOutcomes = await _dashboardRepository.getRoomOutcomesItems();
    final cafeOrders = await _cafeRepository.getOrders();
    final cafeTables = await _cafeRepository.getTables();
    final cafeOutcomes = await _cafeRepository.getCafeOutcomesItems();

    return _MobileAnalyticsSnapshot.fromData(
      rooms: rooms,
      roomHistories: roomHistories,
      roomOutcomes: roomOutcomes,
      cafeOrders: cafeOrders,
      cafeTables: cafeTables,
      cafeOutcomes: cafeOutcomes,
    );
  }

  Future<void> _refresh() async {
    final future = _loadSnapshot();
    if (mounted) {
      setState(() {
        _snapshotFuture = future;
      });
    }
    await future;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF05071C),
      body: SafeArea(
        child: FutureBuilder<_MobileAnalyticsSnapshot>(
          future: _snapshotFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return Center(
                child: CircularProgressIndicator(color: AppColors.yellowColor),
              );
            }

            if (snapshot.hasError || !snapshot.hasData) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Failed to load mobile analytics',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        snapshot.error.toString(),
                        style: const TextStyle(color: Colors.white70),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _refresh,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              );
            }

            final data = snapshot.data!;
            return RefreshIndicator(
              onRefresh: _refresh,
              color: AppColors.yellowColor,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 28),
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Image.asset('images/quarto_logo.png', scale: 5),
                            const SizedBox(height: 18),
                            const Text(
                              'Mobile Analytics',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              data.dayLabel,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: _refresh,
                        icon: const Icon(Icons.refresh, color: Colors.white),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _HeroRevenueCard(data: data),
                  const SizedBox(height: 18),
                  const _MobileSectionTitle('Overview'),
                  const SizedBox(height: 12),
                  _MetricGrid(
                    items: [
                      _MetricItem(
                        title: 'Total Revenue',
                        value: _currency(data.totalRevenue),
                        accent: AppColors.yellowColor,
                        subtitle: 'Rooms + room orders + cafe',
                      ),
                      _MetricItem(
                        title: 'Net Profit',
                        value: _currency(data.netProfit),
                        accent: const Color(0xFF57E389),
                        subtitle: 'After outcomes',
                      ),
                      _MetricItem(
                        title: 'Expenses',
                        value: _currency(data.totalExpenses),
                        accent: const Color(0xFFFF8A65),
                        subtitle: 'All outcomes',
                      ),
                      _MetricItem(
                        title: 'Utilization',
                        value: '${data.utilizationRate.toStringAsFixed(0)}%',
                        accent: const Color(0xFF34D1BF),
                        subtitle:
                            '${data.activeUnits}/${data.totalUnits} active',
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  const _MobileSectionTitle('Cafe Snapshot'),
                  const SizedBox(height: 12),
                  _MetricGrid(
                    items: [
                      _MetricItem(
                        title: 'Orders Revenue',
                        value: _currency(data.cafeRevenue),
                        accent: AppColors.yellowColor,
                        subtitle: '${data.cafeOrdersCount} orders',
                      ),
                      _MetricItem(
                        title: 'Cafe Profit',
                        value: _currency(data.cafeNetProfit),
                        accent: const Color(0xFF57E389),
                        subtitle: 'Revenue - expenses',
                      ),
                      _MetricItem(
                        title: 'Cafe Outcomes',
                        value: _currency(data.cafeExpenses),
                        accent: const Color(0xFFFF8A65),
                        subtitle: '${data.cafeOutcomesCount} records',
                      ),
                      _MetricItem(
                        title: 'Occupied Tables',
                        value: '${data.occupiedTables}',
                        accent: const Color(0xFF4B7BFF),
                        subtitle: '${data.freeTables} free',
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _MetricGrid(
                    items: [
                      _MetricItem(
                        title: 'Cash Total',
                        value: _currency(data.cafeCashRevenue),
                        accent: const Color(0xFF4B7BFF),
                        subtitle: 'Paid in cash',
                      ),
                      _MetricItem(
                        title: 'Visa Total',
                        value: _currency(data.cafeVisaRevenue),
                        accent: const Color(0xFF34D1BF),
                        subtitle: 'Paid by card',
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _InfoPanel(
                    title: 'Cafe Order Sources',
                    child: Column(
                      children: [
                        _ProgressRow(
                          label: 'Table',
                          value: data.cafeOrderDistribution['table'] ?? 0,
                          total: math.max(1, data.cafeOrdersCount.toDouble()),
                          color: AppColors.yellowColor,
                        ),
                        _ProgressRow(
                          label: 'Takeaway',
                          value: data.cafeOrderDistribution['takeaway'] ?? 0,
                          total: math.max(1, data.cafeOrdersCount.toDouble()),
                          color: const Color(0xFFFF7B00),
                        ),
                        _ProgressRow(
                          label: 'Staff',
                          value: data.cafeOrderDistribution['staff'] ?? 0,
                          total: math.max(1, data.cafeOrdersCount.toDouble()),
                          color: const Color(0xFF2F37FF),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  _InfoPanel(
                    title: 'Top Cafe Items',
                    child: _RankingList(
                      items: data.topCafeItems,
                      suffix: 'orders',
                    ),
                  ),
                  const SizedBox(height: 14),
                  _InfoPanel(
                    title: 'Tables Status',
                    child: Column(
                      children: [
                        _StatusGroup(
                          title: 'Occupied Tables',
                          names: data.occupiedTableNames,
                          color: const Color(0xFF4B7BFF),
                        ),
                        const SizedBox(height: 14),
                        _StatusGroup(
                          title: 'Free Tables',
                          names: data.freeTableNames,
                          color: const Color(0xFF57E389),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  const _MobileSectionTitle('Rooms Snapshot'),
                  const SizedBox(height: 12),
                  _MetricGrid(
                    items: [
                      _MetricItem(
                        title: 'Rooms Income',
                        value: _currency(data.playStationRevenue),
                        accent: AppColors.yellowColor,
                        subtitle: 'Sessions + room orders',
                      ),
                      _MetricItem(
                        title: 'Room Orders',
                        value: _currency(data.roomOrdersRevenue),
                        accent: const Color(0xFF2F37FF),
                        subtitle: 'Orders inside rooms',
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _MetricGrid(
                    items: [
                      _MetricItem(
                        title: 'Rooms Profit',
                        value: _currency(data.playStationNetProfit),
                        accent: const Color(0xFF57E389),
                        subtitle: 'After outcomes',
                      ),
                      _MetricItem(
                        title: 'Room Outcomes',
                        value: _currency(data.roomExpenses),
                        accent: const Color(0xFFFF8A65),
                        subtitle: '${data.roomOutcomesCount} records',
                      ),
                      _MetricItem(
                        title: 'Occupied Rooms',
                        value: '${data.occupiedRooms}',
                        accent: const Color(0xFF4B7BFF),
                        subtitle: '${data.freeRooms} free',
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _MetricGrid(
                    items: [
                      _MetricItem(
                        title: 'Room Cash',
                        value: _currency(data.roomCashRevenue),
                        accent: const Color(0xFF4B7BFF),
                        subtitle: 'Ended sessions paid in cash',
                      ),
                      _MetricItem(
                        title: 'Room Visa',
                        value: _currency(data.roomVisaRevenue),
                        accent: const Color(0xFF34D1BF),
                        subtitle: 'Ended sessions paid by card',
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _InfoPanel(
                    title: 'Top Rooms',
                    child: _RankingList(
                      items: data.topRooms,
                      suffix: 'EGP',
                    ),
                  ),
                  const SizedBox(height: 14),
                  _InfoPanel(
                    title: 'Console Revenue Mix',
                    child: Column(
                      children: [
                        _ProgressRow(
                          label: 'PS5',
                          value: data.consoleTypeRevenue['ps5'] ?? 0,
                          total: math.max(1, data.playStationRevenue),
                          color: const Color(0xFF2F37FF),
                        ),
                        _ProgressRow(
                          label: 'PS4',
                          value: data.consoleTypeRevenue['ps4'] ?? 0,
                          total: math.max(1, data.playStationRevenue),
                          color: AppColors.yellowColor,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  _InfoPanel(
                    title: 'Rooms Status',
                    child: Column(
                      children: [
                        _StatusGroup(
                          title: 'Occupied Rooms',
                          names: data.occupiedRoomNames,
                          color: const Color(0xFF4B7BFF),
                        ),
                        const SizedBox(height: 14),
                        _StatusGroup(
                          title: 'Free Rooms',
                          names: data.freeRoomNames,
                          color: const Color(0xFF57E389),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _MobileAnalyticsSnapshot {
  const _MobileAnalyticsSnapshot({
    required this.dayLabel,
    required this.totalRevenue,
    required this.totalExpenses,
    required this.netProfit,
    required this.utilizationRate,
    required this.activeUnits,
    required this.totalUnits,
    required this.playStationRevenue,
    required this.roomOrdersRevenue,
    required this.playStationNetProfit,
    required this.roomExpenses,
    required this.roomCashRevenue,
    required this.roomVisaRevenue,
    required this.cafeRevenue,
    required this.cafeNetProfit,
    required this.cafeExpenses,
    required this.cafeCashRevenue,
    required this.cafeVisaRevenue,
    required this.cafeOrderDistribution,
    required this.topCafeItems,
    required this.topRooms,
    required this.consoleTypeRevenue,
    required this.cafeOrdersCount,
    required this.cafeOutcomesCount,
    required this.roomOutcomesCount,
    required this.occupiedTables,
    required this.freeTables,
    required this.occupiedTableNames,
    required this.freeTableNames,
    required this.occupiedRooms,
    required this.freeRooms,
    required this.occupiedRoomNames,
    required this.freeRoomNames,
  });

  final String dayLabel;
  final double totalRevenue;
  final double totalExpenses;
  final double netProfit;
  final double utilizationRate;
  final int activeUnits;
  final int totalUnits;
  final double playStationRevenue;
  final double roomOrdersRevenue;
  final double playStationNetProfit;
  final double roomExpenses;
  final double roomCashRevenue;
  final double roomVisaRevenue;
  final double cafeRevenue;
  final double cafeNetProfit;
  final double cafeExpenses;
  final double cafeCashRevenue;
  final double cafeVisaRevenue;
  final Map<String, double> cafeOrderDistribution;
  final List<_RankedValue> topCafeItems;
  final List<_RankedValue> topRooms;
  final Map<String, double> consoleTypeRevenue;
  final int cafeOrdersCount;
  final int cafeOutcomesCount;
  final int roomOutcomesCount;
  final int occupiedTables;
  final int freeTables;
  final List<String> occupiedTableNames;
  final List<String> freeTableNames;
  final int occupiedRooms;
  final int freeRooms;
  final List<String> occupiedRoomNames;
  final List<String> freeRoomNames;

  factory _MobileAnalyticsSnapshot.fromData({
    required List<Room> rooms,
    required List<SessionHistory> roomHistories,
    required List<RoomOutcomesModel> roomOutcomes,
    required List<OrderModel> cafeOrders,
    required List<CafeTableModel> cafeTables,
    required List<CafeOutcomesModel> cafeOutcomes,
  }) {
    final now = DateTime.now();
    final endedSessions = roomHistories.where(
      (session) => session.endTime != null,
    );

    final roomRevenueById = <String, double>{};
    final consoleTypeRevenue = <String, double>{'ps4': 0, 'ps5': 0};

    var endedPlayStationRevenue = 0.0;
    var endedRoomOrdersRevenue = 0.0;
    var roomCashRevenue = 0.0;
    var roomVisaRevenue = 0.0;
    for (final session in endedSessions) {
      final ordersRevenue = session.ordersTotal.clamp(0.0, session.totalCost);
      endedPlayStationRevenue += session.totalCost;
      endedRoomOrdersRevenue += ordersRevenue;
      roomRevenueById.update(
        session.roomId,
        (value) => value + session.totalCost,
        ifAbsent: () => session.totalCost,
      );
      final paymentMethod = _normalizeRoomPaymentMethod(session.paymentMethod);
      if (paymentMethod == 'Cash') {
        roomCashRevenue += session.totalCost;
      } else if (paymentMethod == 'Visa') {
        roomVisaRevenue += session.totalCost;
      }
      final key = (session.psType ?? '').toLowerCase();
      if (consoleTypeRevenue.containsKey(key)) {
        consoleTypeRevenue[key] =
            (consoleTypeRevenue[key] ?? 0) + session.totalCost;
      }
    }

    var activePlayStationRevenue = 0.0;
    var activeRoomOrdersRevenue = 0.0;
    for (final room in rooms.where((room) => room.isOccupied)) {
      final activeRevenue = room.calculatedCost + room.ordersTotal;
      activePlayStationRevenue += activeRevenue;
      activeRoomOrdersRevenue += room.ordersTotal;
      roomRevenueById.update(
        room.id,
        (value) => value + activeRevenue,
        ifAbsent: () => activeRevenue,
      );
      final key = (room.psType ?? '').toLowerCase();
      if (consoleTypeRevenue.containsKey(key)) {
        consoleTypeRevenue[key] =
            (consoleTypeRevenue[key] ?? 0) + activeRevenue;
      }
    }

    final playStationRevenue =
        endedPlayStationRevenue + activePlayStationRevenue;
    final roomOrdersRevenue = endedRoomOrdersRevenue + activeRoomOrdersRevenue;
    final roomExpenses = roomOutcomes.fold<double>(
      0,
      (sum, item) => sum + (item.price * item.quantity),
    );
    final playStationNetProfit = playStationRevenue - roomExpenses;

    final finalizedCafe = finalizedCafeOrders(cafeOrders, cafeTables);
    final cafeRevenue = finalizedCafe.fold<double>(
      0,
      (sum, order) => sum + calculateOrderTotal(order),
    );
    final cafeCashRevenue = finalizedCafe
        .where((order) => normalizePaymentMethod(order.paymentMethod) == 'Cash')
        .fold<double>(
          0,
          (sum, order) => sum + calculateOrderTotal(order),
        );
    final cafeVisaRevenue = finalizedCafe
        .where((order) => normalizePaymentMethod(order.paymentMethod) == 'Visa')
        .fold<double>(
          0,
          (sum, order) => sum + calculateOrderTotal(order),
        );
    final cafeExpenses = cafeOutcomes.fold<double>(
      0,
      (sum, item) => sum + (item.price * item.quantity),
    );
    final cafeNetProfit = cafeRevenue - cafeExpenses;

    final cafeOrderDistribution = <String, double>{
      'table': 0,
      'takeaway': 0,
      'staff': 0,
    };
    final topCafeItemsMap = <String, double>{};
    for (final order in finalizedCafe) {
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

    final totalRevenue = playStationRevenue + cafeRevenue;
    final totalExpenses = roomExpenses + cafeExpenses;
    final totalUnits = rooms.length + cafeTables.length;
    final activeUnits =
        rooms.where((room) => room.isOccupied).length +
        cafeTables.where((table) => table.isOccupied).length;
    final utilizationRate = totalUnits == 0
        ? 0.0
        : (activeUnits / totalUnits) * 100;

    return _MobileAnalyticsSnapshot(
      dayLabel:
          'Current day - ${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}',
      totalRevenue: totalRevenue,
      totalExpenses: totalExpenses,
      netProfit: totalRevenue - totalExpenses,
      utilizationRate: utilizationRate,
      activeUnits: activeUnits,
      totalUnits: totalUnits,
      playStationRevenue: playStationRevenue,
      roomOrdersRevenue: roomOrdersRevenue,
      playStationNetProfit: playStationNetProfit,
      roomExpenses: roomExpenses,
      roomCashRevenue: roomCashRevenue,
      roomVisaRevenue: roomVisaRevenue,
      cafeRevenue: cafeRevenue,
      cafeNetProfit: cafeNetProfit,
      cafeExpenses: cafeExpenses,
      cafeCashRevenue: cafeCashRevenue,
      cafeVisaRevenue: cafeVisaRevenue,
      cafeOrderDistribution: cafeOrderDistribution,
      topCafeItems: topCafeItems.take(5).toList(),
      topRooms: topRooms.take(5).toList(),
      consoleTypeRevenue: consoleTypeRevenue,
      cafeOrdersCount: finalizedCafe.length,
      cafeOutcomesCount: cafeOutcomes.length,
      roomOutcomesCount: roomOutcomes.length,
      occupiedTables: cafeTables.where((table) => table.isOccupied).length,
      freeTables: cafeTables.where((table) => !table.isOccupied).length,
      occupiedTableNames: cafeTables
          .where((table) => table.isOccupied)
          .map((table) => table.tableName)
          .toList(),
      freeTableNames: cafeTables
          .where((table) => !table.isOccupied)
          .map((table) => table.tableName)
          .toList(),
      occupiedRooms: rooms.where((room) => room.isOccupied).length,
      freeRooms: rooms.where((room) => !room.isOccupied).length,
      occupiedRoomNames: rooms
          .where((room) => room.isOccupied)
          .map((room) => room.name)
          .toList(),
      freeRoomNames: rooms
          .where((room) => !room.isOccupied)
          .map((room) => room.name)
          .toList(),
    );
  }
}

class _HeroRevenueCard extends StatelessWidget {
  const _HeroRevenueCard({required this.data});

  final _MobileAnalyticsSnapshot data;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [Color(0xFF151A57), Color(0xFF10132F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: Colors.white24),
        boxShadow: [
          BoxShadow(
            color: AppColors.yellowColor.withValues(alpha: 0.14),
            blurRadius: 24,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Today at a glance',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            _currency(data.totalRevenue),
            style: TextStyle(
              color: AppColors.yellowColor,
              fontSize: 34,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Combined revenue from rooms and cafe for the current operating day.',
            style: TextStyle(
              color: Colors.white,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _CompactStatPill(
                  label: 'Rooms',
                  value: _currency(data.playStationRevenue),
                  color: const Color(0xFF2F37FF),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _CompactStatPill(
                  label: 'Cafe',
                  value: _currency(data.cafeRevenue),
                  color: AppColors.yellowColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CompactStatPill extends StatelessWidget {
  const _CompactStatPill({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 11),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricGrid extends StatelessWidget {
  const _MetricGrid({required this.items});

  final List<_MetricItem> items;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      itemCount: items.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.06,
      ),
      itemBuilder: (context, index) => _MetricTile(item: items[index]),
    );
  }
}

class _MetricItem {
  const _MetricItem({
    required this.title,
    required this.value,
    required this.accent,
    required this.subtitle,
  });

  final String title;
  final String value;
  final Color accent;
  final String subtitle;
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({required this.item});

  final _MetricItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: Colors.white.withValues(alpha: 0.05),
        border: Border.all(color: item.accent.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.title,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          Text(
            item.value,
            style: TextStyle(
              color: item.accent,
              fontSize: 21,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            item.subtitle,
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 11,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoPanel extends StatelessWidget {
  const _InfoPanel({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
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
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _ProgressRow extends StatelessWidget {
  const _ProgressRow({
    required this.label,
    required this.value,
    required this.total,
    required this.color,
  });

  final String label;
  final double value;
  final double total;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final progress = total == 0 ? 0.0 : (value / total).clamp(0.0, 1.0);
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ),
              Text(
                value.toStringAsFixed(0),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor: Colors.white12,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }
}

class _RankingList extends StatelessWidget {
  const _RankingList({required this.items, required this.suffix});

  final List<_RankedValue> items;
  final String suffix;

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
        final widthFactor = maxValue == 0 ? 0.0 : item.value / maxValue;
        return Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Row(
            children: [
              Expanded(
                flex: 5,
                child: Text(
                  item.label,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ),
              Expanded(
                flex: 7,
                child: Stack(
                  children: [
                    Container(
                      height: 10,
                      decoration: BoxDecoration(
                        color: Colors.white12,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    FractionallySizedBox(
                      widthFactor: widthFactor.clamp(0.0, 1.0),
                      child: Container(
                        height: 10,
                        decoration: BoxDecoration(
                          color: AppColors.yellowColor,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${item.value.toStringAsFixed(0)} $suffix',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _StatusGroup extends StatelessWidget {
  const _StatusGroup({
    required this.title,
    required this.names,
    required this.color,
  });

  final String title;
  final List<String> names;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final safeNames = names.isEmpty ? const ['None'] : names;

    return Column(
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
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: safeNames
              .map(
                (name) => Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: color.withValues(alpha: 0.45)),
                  ),
                  child: Text(
                    name,
                    style: TextStyle(
                      color: color,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}

class _RankedValue {
  const _RankedValue({required this.label, required this.value});

  final String label;
  final double value;
}

class _MobileSectionTitle extends StatelessWidget {
  const _MobileSectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 18,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

String _currency(double value) => '${value.toStringAsFixed(0)} EGP';

String _normalizeRoomPaymentMethod(String? value) {
  switch ((value ?? '').trim().toLowerCase()) {
    case 'visa':
      return 'Visa';
    case 'cash':
      return 'Cash';
    default:
      return '--';
  }
}
