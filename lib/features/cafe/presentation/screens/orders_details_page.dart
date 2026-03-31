import 'package:flutter/material.dart';
import 'package:quarto/features/cafe/data/model/order_model.dart';
import 'package:quarto/features/cafe/domain/repository/cafe_repository.dart';
import 'package:quarto/features/cafe/presentation/utils/cafe_order_utils.dart';
import 'package:quarto/features/dashboard/presentation/widgets/button_widget.dart';
import 'package:quarto/injection_container.dart';

class OrdersDetailsPage extends StatefulWidget {
  const OrdersDetailsPage({super.key});

  @override
  State<OrdersDetailsPage> createState() => _OrdersDetailsPageState();
}

class _OrdersDetailsPageState extends State<OrdersDetailsPage> {
  final CafeRepository _cafeRepository = sl<CafeRepository>();
  List<OrderModel> _orders = const [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    setState(() {
      _isLoading = true;
    });

    final orders = await _cafeRepository.getOrders();
    final tables = await _cafeRepository.getTables();

    if (mounted) {
      setState(() {
        _orders = finalizedCafeOrders(orders, tables);
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
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
                        onPressed: () {},
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
                      const Text(
                        'Recent Cafe Orders',
                        style: TextStyle(
                          fontSize: 20,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                  if (_isLoading)
                    const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    )
                  else
                    _buildOrdersTable(_orders),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Widget _buildOrdersTable(List<OrderModel> orders) {
  return SizedBox(
    width: double.infinity,
    child: DataTable(
      border: TableBorder.all(color: Colors.white10),
      dataTextStyle: const TextStyle(color: Colors.white),
      headingTextStyle: const TextStyle(color: Colors.white),
      columns: const [
        DataColumn(label: Text('#')),
        DataColumn(label: Text('Type')),
        DataColumn(label: Text('Table')),
        DataColumn(label: Text('Name')),
        DataColumn(label: Text('Time')),
        DataColumn(label: Text('Total')),
        DataColumn(label: Text('Details')),
      ],
      rows: orders.asMap().entries.map((entry) {
        final index = entry.key;
        final order = entry.value;

        return DataRow(
          cells: [
            DataCell(Text('${index + 1}')),
            DataCell(Text(order.orderType)),
            DataCell(Text(order.tableId ?? '-')),
            DataCell(Text(order.customerName ?? order.staffName ?? '-')),
            DataCell(
              Text(
                '${formatOrderDate(order.orderTime)} ${formatOrderTime(order.orderTime)}',
              ),
            ),
            DataCell(
              Text('${calculateOrderTotal(order).toStringAsFixed(0)} EGP'),
            ),
            DataCell(
              Text(
                '${order.items.length} items',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      }).toList(),
    ),
  );
}
