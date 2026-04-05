import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quarto/core/colors/app_colors.dart';
import 'package:quarto/core/services/system_export_service.dart';
import 'package:quarto/core/common/cafe_order_dailoge_widget.dart';
import 'package:quarto/core/common/vip_widget.dart';
import 'package:quarto/core/fonts/app_text.dart';
import 'package:quarto/features/cafe/data/model/cafe_tabels_model.dart';
import 'package:quarto/features/cafe/data/model/order_model.dart';
import 'package:quarto/features/cafe/domain/repository/cafe_repository.dart';
import 'package:quarto/features/cafe/presentation/cubits/tabels_cubit/cafe_tables_cubit.dart';
import 'package:quarto/features/cafe/presentation/utils/cafe_order_utils.dart';
import 'package:quarto/features/dashboard/presentation/widgets/button_widget.dart';
import 'package:quarto/injection_container.dart';

class TabelDetailsPage extends StatefulWidget {
  const TabelDetailsPage({super.key, required this.cafeTable});

  final CafeTableModel cafeTable;

  @override
  State<TabelDetailsPage> createState() => _TabelDetailsPageState();
}

class _TabelDetailsPageState extends State<TabelDetailsPage> {
  final CafeRepository _cafeRepository = sl<CafeRepository>();
  List<OrderModel> _tableOrders = const [];
  bool _isLoading = true;

  CafeTableModel get _currentTable {
    final state = context.read<CafeTablesCubit>().state;
    if (state is SuccessGetTables) {
      return state.tables.firstWhere(
        (table) => table.id == widget.cafeTable.id,
        orElse: () => widget.cafeTable,
      );
    }
    return widget.cafeTable;
  }

  OrderModel? get _activeOrder {
    if (!_currentTable.isOccupied) {
      return null;
    }
    return latestOrderForTable(widget.cafeTable.id, _tableOrders);
  }

  OrderModel? get _displayOrder {
    return _activeOrder ??
        (_tableOrders.isNotEmpty ? _tableOrders.first : null);
  }

  @override
  void initState() {
    super.initState();
    _loadTableData();
  }

  Future<void> _loadTableData() async {
    setState(() {
      _isLoading = true;
    });

    await context.read<CafeTablesCubit>().getTables();
    final orders = await _cafeRepository.getOrdersByTable(widget.cafeTable.id);

    if (mounted) {
      setState(() {
        _tableOrders = orders;
        _isLoading = false;
      });
    }
  }

  Future<void> _handleAddOrder() async {
    final changed = await showDialog<bool>(
      context: context,
      builder: (context) => CafeOrderDailogeWidget(
        orderType: 'Table',
        tableId: widget.cafeTable.id,
        existingOrderId: _activeOrder?.id,
      ),
    );

    if (changed == true) {
      await _loadTableData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final horizontalPadding = 60.0;
    final availableWidth = screenWidth - horizontalPadding;
    final cardWidth = (availableWidth - 40) / 3;
    final order = _displayOrder;
    final orderTotal = order == null ? 0.0 : calculateOrderTotal(order);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          SizedBox(
            width: double.infinity,
            height: double.infinity,
            child: Image.asset('images/bg.png', fit: BoxFit.cover),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30),
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
                        title: 'Export history',
                        icon: Icons.download,
                        onPressed: () => SystemExportService.exportCafeReport(
                          context,
                          table: widget.cafeTable,
                        ),
                      ),
                      const SizedBox(width: 20),
                      Container(
                        margin: const EdgeInsets.only(right: 10),
                        child: AddButton(
                          title: 'Add order',
                          onPressed: _handleAddOrder,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      InkWell(
                        onTap: () => Navigator.pop(context),
                        child: const Icon(
                          Icons.arrow_back,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '${_currentTable.tableName} - Overview',
                        style: const TextStyle(
                          fontSize: 20,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: activeTableCard(
                          icon: Icons.shopify_outlined,
                          title: 'Order ID',
                          data: order?.id ?? '--',
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: activeTableCard(
                          icon: Icons.date_range_outlined,
                          title: 'Date',
                          data: order == null
                              ? '--'
                              : formatOrderDate(order.orderTime),
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: activeTableCard(
                          icon: Icons.payments_outlined,
                          title: 'Payment Method',
                          widget: VipWidget(
                            title: normalizePaymentMethod(order?.paymentMethod),
                          ),
                          data: '',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  activeTableCard(
                    width: cardWidth,
                    icon: Icons.payments_outlined,
                    title: 'Total',
                    data: '${orderTotal.toStringAsFixed(0)} \$',
                    backgroundColor: AppColors.yellowColor,
                    textColor: AppColors.blueColor,
                  ),
                  const SizedBox(height: 30),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: tabelorderWidget(
                          color: AppColors.blueColor,
                          orderHistory: false,
                          order: order,
                          isLoading: _isLoading,
                          title: _currentTable.isOccupied
                              ? 'Current order'
                              : 'Last order',
                        ),
                      ),
                      const SizedBox(width: 20),
                      const Expanded(child: SizedBox()),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Widget activeTableCard({
  required IconData icon,
  required String title,
  required String data,
  double? width,
  Widget? widget,
  Color? backgroundColor,
  Color? textColor,
}) {
  return Container(
    width: width,
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      boxShadow: const [
        BoxShadow(
          blurRadius: 1,
          color: Colors.white10,
          spreadRadius: 0,
          offset: Offset(0, 0),
        ),
      ],
      borderRadius: BorderRadius.circular(12),
      color: backgroundColor ?? Colors.transparent,
      border: Border.all(color: backgroundColor ?? Colors.white10),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(icon, color: textColor ?? Colors.white),
        const SizedBox(width: 8),
        Text(title, style: TextStyle(color: textColor ?? Colors.white)),
        const Spacer(),
        widget ??
            Text(
              data,
              style: TextStyle(
                color: textColor ?? Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
      ],
    ),
  );
}

Widget tabelorderWidget({
  required Color color,
  required bool orderHistory,
  required OrderModel? order,
  required bool isLoading,
  required String title,
}) {
  return Container(
    padding: const EdgeInsets.all(12),
    constraints: const BoxConstraints(minHeight: 100),
    decoration: BoxDecoration(
      boxShadow: orderHistory
          ? const [
              BoxShadow(
                blurRadius: 1,
                color: Colors.white10,
                spreadRadius: 0,
                offset: Offset(0, 0),
              ),
            ]
          : null,
      border: Border.all(
        color: orderHistory ? Colors.white12 : color,
        width: 1,
      ),
      borderRadius: BorderRadius.circular(12),
      color: color,
    ),
    child: isLoading
        ? const Center(child: CircularProgressIndicator(color: Colors.white))
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.add_to_drive_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(title, style: AppTexts.meduimBody),
                ],
              ),
              const SizedBox(height: 12),
              if (order == null)
                Text(
                  'No order yet',
                  style: AppTexts.smallBody,
                )
              else ...[
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: order.items.length,
                  itemBuilder: (context, index) {
                    final item = order.items[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${item.itemName} x${item.quantity}',
                            style: AppTexts.smallBody,
                          ),
                          Text(
                            (item.price * item.quantity).toStringAsFixed(0),
                            style: AppTexts.smallBody,
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 4),
                const Divider(),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total',
                      style: AppTexts.meduimBody.copyWith(
                        color: AppColors.yellowColor,
                      ),
                    ),
                    Text(
                      calculateOrderTotal(order).toStringAsFixed(0),
                      style: AppTexts.meduimBody.copyWith(
                        color: AppColors.yellowColor,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
  );
}
