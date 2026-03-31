import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quarto/features/cafe/data/model/order_model.dart';
import 'package:quarto/features/cafe/presentation/cubits/orders_cubit/orders_cubit.dart';
import 'package:quarto/features/dashboard/presentation/widgets/button_widget.dart';

class OrdersDetailsPage extends StatefulWidget {
  const OrdersDetailsPage({super.key});

  @override
  State<OrdersDetailsPage> createState() => _OrdersDetailsPageState();
}

class _OrdersDetailsPageState extends State<OrdersDetailsPage> {
  @override
  void initState() {
    context.read<OrdersCubit>().getOrders();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Bg image
          SizedBox(
            width: double.infinity,
            height: double.infinity,
            child: Image.asset(
              "images/bg.png",
              fit: BoxFit.cover,
            ),
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
                      Image.asset(
                        'images/quarto_logo.png',
                        scale: 4,
                      ),
                      Spacer(),
                      ExportButtonsWidget(
                        title: 'Export history',
                        icon: Icons.download,
                        onPressed: () {},
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      InkWell(
                        onTap: () => Navigator.pop(context),
                        child: Icon(
                          Icons.arrow_back,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(width: 12),
                      Text(
                        'Recent Café Orders',
                        style: TextStyle(
                          fontSize: 20,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 30),
                  BlocBuilder<OrdersCubit, OrdersState>(
                    builder: (context, state) {
                      if (state is SuccessGetOrders) {
                        return _buildOrdersTable(state.orders, context);
                      }
                      return SizedBox();
                    },
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

Widget _buildOrdersTable(
  List<OrderModel> orders,
  BuildContext context,
) {
  return SizedBox(
    width: double.infinity,
    child: DataTable(
      border: TableBorder.all(color: Colors.white10),
      dataTextStyle: const TextStyle(color: Colors.white),
      headingTextStyle: const TextStyle(color: Colors.white),
      columns: const [
        DataColumn(label: Text("#")),
        DataColumn(label: Text("Date")),
        DataColumn(label: Text("Table")),
        DataColumn(label: Text("Table")),
        DataColumn(label: Text("Payment Method")),
        DataColumn(label: Text("Total")),
        DataColumn(label: Text("Details")),
      ],
      rows: orders.asMap().entries.map((entry) {
        final index = entry.key;
        final order = entry.value;

        return DataRow(
          cells: [
            DataCell(Text("${index + 1}")),

            /// نوع الأوردر
            DataCell(Text(order.orderType)),

            /// رقم الترابيزة (لو موجود)
            DataCell(Text(order.tableId?.toString() ?? "-")),

            /// اسم العميل أو الموظف
            DataCell(
              Text(order.customerName ?? order.staffName ?? "-"),
            ),

            /// الوقت
            DataCell(Text("order.formattedTime")),

            /// عدد المنتجات
            DataCell(Text("${order.items.length}")),

            /// إجمالي السعر
            // DataCell(Text("${"order.totalPrice"} EGP")),

            /// زر التفاصيل
            DataCell(
              ElevatedButton(
                onPressed: () {
                  // Navigator.push(
                  //   context,
                  //   MaterialPageRoute(
                  //     builder: (_) => OrderDetailsPage(order: order),
                  //   ),
                  // );
                },
                child: const Text("View"),
              ),
            ),
          ],
        );
      }).toList(),
    ),
  );
}
