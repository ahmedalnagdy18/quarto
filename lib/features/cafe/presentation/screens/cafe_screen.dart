import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quarto/core/colors/app_colors.dart';
import 'package:quarto/core/common/app_button.dart';
import 'package:quarto/core/common/cafe_order_dailoge_widget.dart';
import 'package:quarto/core/fonts/app_text.dart';
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
