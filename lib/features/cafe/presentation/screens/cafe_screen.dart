import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quarto/core/colors/app_colors.dart';
import 'package:quarto/core/common/app_button.dart';
import 'package:quarto/core/common/cafe_order_dailoge_widget.dart';
import 'package:quarto/core/fonts/app_text.dart';
import 'package:quarto/features/cafe/data/model/cafe_tabels_model.dart';
import 'package:quarto/features/cafe/data/model/order_model.dart';
import 'package:quarto/features/cafe/domain/repository/cafe_repository.dart';
import 'package:quarto/features/cafe/presentation/cubits/tabels_cubit/cafe_tables_cubit.dart';
import 'package:quarto/features/cafe/presentation/screens/cafe_outcomes.dart';
import 'package:quarto/features/cafe/presentation/screens/orders_details_page.dart';
import 'package:quarto/features/cafe/presentation/screens/tabel_details_page.dart';
import 'package:quarto/features/cafe/presentation/utils/cafe_order_utils.dart';
import 'package:quarto/features/cafe/presentation/widgets/table_card_widget.dart';
import 'package:quarto/features/dashboard/presentation/widgets/button_widget.dart';
import 'package:quarto/features/dashboard/presentation/widgets/card_widget.dart';
import 'package:quarto/injection_container.dart';

class CafeScreen extends StatefulWidget {
  const CafeScreen({super.key});

  @override
  State<CafeScreen> createState() => _CafeScreenState();
}

class _CafeScreenState extends State<CafeScreen> {
  final CafeRepository _cafeRepository = sl<CafeRepository>();
  List<OrderModel> _orders = const [];
  bool _isLoadingOrders = true;

  @override
  void initState() {
    super.initState();
    _loadCafeData();
  }

  Future<void> _loadCafeData() async {
    if (mounted) {
      setState(() {
        _isLoadingOrders = true;
      });
    }

    await context.read<CafeTablesCubit>().getTables();

    try {
      final orders = await _cafeRepository.getOrders();
      if (mounted) {
        setState(() {
          _orders = orders;
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingOrders = false;
        });
      }
    }
  }

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _openGeneralOrderDialog(String orderType) async {
    final changed = await showDialog<bool>(
      context: context,
      builder: (context) => CafeOrderDailogeWidget(orderType: orderType),
    );

    if (changed == true) {
      await _loadCafeData();
    }
  }

  Future<void> _openTableDetails(String tableId) async {
    final tableState = context.read<CafeTablesCubit>().state;
    if (tableState is! SuccessGetTables) {
      return;
    }

    final table = tableState.tables.firstWhere((table) => table.id == tableId);
    await Navigator.push(
      context,
      CupertinoPageRoute(
        builder: (context) => TabelDetailsPage(cafeTable: table),
      ),
    );
    await _loadCafeData();
  }

  Future<void> _openTableOrderDialog(String tableId) async {
    final changed = await showDialog<bool>(
      context: context,
      builder: (context) => CafeOrderDailogeWidget(
        orderType: 'Table',
        tableId: tableId,
      ),
    );

    if (changed == true) {
      await _loadCafeData();
    }
  }

  Future<void> _endTableOrder(String tableId) async {
    await context.read<CafeTablesCubit>().updateTableStatus(tableId, false);
    await _loadCafeData();
  }

  Future<void> _moveTableOrder(CafeTableModel sourceTable) async {
    final tableState = context.read<CafeTablesCubit>().state;
    if (tableState is! SuccessGetTables) {
      return;
    }

    final activeOrder = latestOrderForTable(sourceTable.id, _orders);
    if (activeOrder == null) {
      _showMessage('No active order found for this table.');
      return;
    }

    final availableTables = tableState.tables
        .where((table) => !table.isOccupied && table.id != sourceTable.id)
        .toList();

    if (availableTables.isEmpty) {
      _showMessage('No available tables to move this session.');
      return;
    }

    final targetTable = await showDialog<CafeTableModel>(
      context: context,
      barrierDismissible: true,
      builder: (context) => _MoveTableDialog(
        sourceTable: sourceTable,
        availableTables: availableTables,
      ),
    );

    if (targetTable == null) {
      return;
    }

    try {
      await _cafeRepository.moveTableOrder(
        orderId: activeOrder.id,
        fromTableId: sourceTable.id,
        toTableId: targetTable.id,
      );
      await _loadCafeData();
      _showMessage(
        '${sourceTable.tableName} moved to ${targetTable.tableName}.',
      );
    } catch (error) {
      _showMessage(error.toString().replaceFirst('Exception: ', ''));
    }
  }

  double? totalRevenue;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Padding(
        padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 30),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Image.asset('images/quarto_logo.png', scale: 4),
                  const Spacer(),
                  ExportButtonsWidget(
                    title: 'Export rooms',
                    icon: Icons.download,
                    onPressed: () {},
                  ),
                  const SizedBox(width: 20),
                  ExportButtonsWidget(
                    title: 'Orders',
                    icon: Icons.list,
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        CupertinoPageRoute(
                          builder: (context) => const OrdersDetailsPage(),
                        ),
                      );
                      await _loadCafeData();
                    },
                  ),
                  const SizedBox(width: 20),
                  ExportButtonsWidget(
                    title: 'Outcomes',
                    icon: Icons.wallet,
                    onPressed: () {
                      Navigator.push(
                        context,
                        CupertinoPageRoute(
                          builder: (context) => CafeOutcomes(
                            totalRevenue: totalRevenue ?? 0,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Text(
                'Cafe Orders Management',
                style: TextStyle(
                  fontSize: 20,
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Track and manage orders placed by customers seated at cafe .',
                style: TextStyle(fontSize: 14, color: Colors.white),
              ),
              const SizedBox(height: 26),
              BlocBuilder<CafeTablesCubit, CafeTablesState>(
                builder: (context, state) {
                  int freeTables = 0;
                  int occupiedTables = 0;
                  double todayIncome = 0.0;

                  if (state is SuccessGetTables) {
                    freeTables = state.tables
                        .where((t) => !t.isOccupied)
                        .length;
                    occupiedTables = state.tables
                        .where((t) => t.isOccupied)
                        .length;
                    todayIncome = finalizedCafeOrders(_orders, state.tables)
                        .fold<double>(
                          0,
                          (total, order) => total + calculateOrderTotal(order),
                        );
                    totalRevenue = todayIncome;
                  }

                  return Row(
                    children: [
                      Expanded(
                        child: CardWidget(
                          data: '$freeTables',
                          title: 'Free tabels',
                          cafeState: state,
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: CardWidget(
                          data: '$occupiedTables',
                          title: 'Occupied tabels',
                          cafeState: state,
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: CardWidget(
                          data: _isLoadingOrders
                              ? '0\$'
                              : '${todayIncome.toStringAsFixed(0)}\$',
                          title: 'income',
                          cafeState: state,
                        ),
                      ),
                      const SizedBox(width: 20),
                      const Expanded(
                        child: CardWidget(
                          data: '20\$',
                          title: 'Outcomes',
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 30),
              const Text(
                'Cafe orders',
                style: TextStyle(
                  fontSize: 20,
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Track and manage orders placed by customers seated at cafe .',
                style: TextStyle(fontSize: 14, color: Colors.white),
              ),
              const SizedBox(height: 26),
              Row(
                children: [
                  Expanded(
                    child: addOrderWidget(
                      icon: Icons.people_alt_outlined,
                      title: 'Staff Order',
                      subTitle: 'order placed by staff',
                      onPressed: () => _openGeneralOrderDialog('Staff'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: addOrderWidget(
                      icon: Icons.shopping_cart_outlined,
                      title: 'Takeaway Order',
                      subTitle: 'Create a new order for pickup or walk-in',
                      onPressed: () => _openGeneralOrderDialog('takeaway'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),
              const Text(
                'Cafe Tabels',
                style: TextStyle(
                  fontSize: 20,
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Track and manage orders placed by customers seated at cafe .',
                style: TextStyle(fontSize: 14, color: Colors.white),
              ),
              const SizedBox(height: 26),
              BlocBuilder<CafeTablesCubit, CafeTablesState>(
                builder: (context, state) {
                  if (state is SuccessGetTables) {
                    return Wrap(
                      spacing: 15,
                      runSpacing: 15,
                      children: List.generate(
                        state.tables.length,
                        (index) => TableCardWidget(
                          table: state.tables[index],
                          onAddOrder: () =>
                              _openTableOrderDialog(state.tables[index].id),
                          onManage: () =>
                              _openTableDetails(state.tables[index].id),
                          onMove: () => _moveTableOrder(state.tables[index]),
                          onEnd: () => _endTableOrder(state.tables[index].id),
                        ),
                      ),
                    );
                  }
                  return Center(
                    child: CircularProgressIndicator(
                      color: AppColors.yellowColor,
                    ),
                  );
                },
              ),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }
}

class _MoveTableDialog extends StatefulWidget {
  const _MoveTableDialog({
    required this.sourceTable,
    required this.availableTables,
  });

  final CafeTableModel sourceTable;
  final List<CafeTableModel> availableTables;

  @override
  State<_MoveTableDialog> createState() => _MoveTableDialogState();
}

class _MoveTableDialogState extends State<_MoveTableDialog> {
  String? _selectedTableId;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 120, vertical: 60),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 840),
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: const Color(0xFF11133E),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white30),
          boxShadow: [
            BoxShadow(
              color: AppColors.blueColor.withValues(alpha: 0.18),
              blurRadius: 40,
              spreadRadius: 8,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Move Session',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Transfer the current session from ${widget.sourceTable.tableName} to a different table.',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: Colors.white),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text(
              'Choose between available tables',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            if (widget.availableTables.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white24),
                ),
                child: const Text(
                  'There are no free tables available right now.',
                  style: TextStyle(color: Colors.white70),
                ),
              )
            else
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: widget.availableTables.map((table) {
                  final isSelected = _selectedTableId == table.id;
                  return InkWell(
                    onTap: () {
                      setState(() {
                        _selectedTableId = table.id;
                      });
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: 226,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.blueColor.withValues(alpha: 0.28)
                            : Colors.white.withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.yellowColor
                              : Colors.white24,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.table_restaurant_outlined,
                            color: isSelected
                                ? AppColors.yellowColor
                                : Colors.white70,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              table.tableName,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: isSelected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            const SizedBox(height: 28),
            Center(
              child: ElevatedButton.icon(
                onPressed: _selectedTableId == null
                    ? null
                    : () {
                        final selectedTable = widget.availableTables.firstWhere(
                          (table) => table.id == _selectedTableId,
                        );
                        Navigator.pop(context, selectedTable);
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.blueColor,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.white12,
                  disabledForegroundColor: Colors.white38,
                  side: BorderSide(color: AppColors.yellowColor, width: 3),
                  shape: ContinuousRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 12,
                  ),
                ),
                icon: const Icon(Icons.move_down_outlined, size: 18),
                label: const Text(
                  'Move',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Widget addOrderWidget({
  required String title,
  required String subTitle,
  required IconData icon,
  required void Function() onPressed,
}) {
  return Container(
    padding: const EdgeInsets.all(8),
    decoration: BoxDecoration(
      color: AppColors.blueColor,
      borderRadius: BorderRadius.circular(12),
    ),
    child: ListTile(
      leading: Icon(icon, color: Colors.white),
      title: Text(title, style: AppTexts.meduimBody),
      subtitle: Text(
        subTitle,
        style: AppTexts.smallBody.copyWith(
          color: Colors.white54,
          fontSize: 10,
        ),
      ),
      trailing: AppButton(
        buttonColor: AppColors.blueColor,
        borderColor: AppColors.yellowColor,
        buttonTitle: 'Add order',
        icon: Icons.add_circle,
        onPressed: onPressed,
      ),
    ),
  );
}
