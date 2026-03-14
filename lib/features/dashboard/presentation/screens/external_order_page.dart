import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quarto/core/colors/app_colors.dart';
import 'package:quarto/core/fonts/app_text.dart';
import 'package:quarto/features/dashboard/data/model/external_orders_model.dart';
import 'package:quarto/features/dashboard/presentation/cubits/external_order/external_orders_cubit.dart';
import 'package:quarto/features/dashboard/presentation/screens/orders_invoice_page.dart';
import 'package:quarto/features/dashboard/presentation/widgets/button_widget.dart';
import 'package:quarto/features/dashboard/presentation/widgets/export_order_widget.dart';
import 'package:quarto/features/dashboard/presentation/widgets/external_order_dailog_widget.dart';

class ExternalOrderPage extends StatefulWidget {
  const ExternalOrderPage({super.key});

  @override
  State<ExternalOrderPage> createState() => _ExternalOrderPageState();
}

class _ExternalOrderPageState extends State<ExternalOrderPage> {
  // Helper method to calculate total
  double _calculateOrderTotal(List<ExternalOrderItem> orderItems) {
    return orderItems.fold(0, (sum, item) => sum + item.price);
  }

  double _calculateAllOrdersTotal(List<ExternalOrdersModel> orders) {
    return orders.fold(
      0,
      (sum, order) =>
          sum + order.order.fold(0, (subSum, item) => subSum + item.price),
    );
  }

  @override
  void initState() {
    context.read<ExternalOrdersCubit>().getExternalOrders();
    super.initState();
  }

  List<DropdownMenuItem<bool>> items = [
    DropdownMenuItem(value: true, child: Text('Yes')),
    DropdownMenuItem(value: false, child: Text('No')),
  ];
  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ExternalOrdersCubit, ExternalOrdersState>(
      listener: (context, state) {
        if (state is ErrorGetExternalOrders) {
          print(state.message);
        }
        if (state is SuccessDeleteExternalOrder ||
            state is SuccessEditExternalOrders) {
          context.read<ExternalOrdersCubit>().getExternalOrders();
        }
      },
      builder: (context, state) {
        return Scaffold(
          backgroundColor: AppColors.bgCard,
          appBar: AppBar(
            backgroundColor: AppColors.bgDark,
            iconTheme: const IconThemeData(color: Colors.white),
            title: Text("Orders", style: AppTexts.smallHeading),
            centerTitle: true,
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 20),
                child: IconButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) {
                        return ExternalOrderDialogWidget();
                      },
                    );
                  },
                  icon: const Icon(Icons.add),
                ),
              ),
            ],
          ),
          body:
              state is LoadingGetExternalOrders ||
                  state is LoadingEditExternalOrders
              ? Center(child: CircularProgressIndicator())
              : Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 100,
                    vertical: 20,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),
                      // export & clear orders buttons
                      (state is SuccessGetExternalOrders &&
                              state.data.isNotEmpty)
                          ? Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                ButtonWidget(
                                  onPressed: () {
                                    ExportOrdersHelper.exportToExcel(
                                      context,
                                      state.data,
                                    );
                                  },
                                  title: 'Export Orders',
                                ),
                                ButtonWidget(
                                  onPressed: () async {
                                    final bool?
                                    confirm = await showDialog<bool>(
                                      context: context,
                                      builder: (context) {
                                        return AlertDialog(
                                          backgroundColor: AppColors.bgDark,
                                          title: const Text(
                                            "Confirm Reset",
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          content: const Text(
                                            "Are you sure you want to reset all orders? This action cannot be undone.",
                                            style: TextStyle(
                                              color: Colors.grey,
                                              fontSize: 14,
                                            ),
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () {
                                                Navigator.of(
                                                  context,
                                                ).pop(false); // User pressed No
                                              },
                                              child: const Text(
                                                "Cancel",
                                                style: TextStyle(
                                                  color: Colors.grey,
                                                ),
                                              ),
                                            ),
                                            ElevatedButton(
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.red,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                              ),
                                              onPressed: () {
                                                ExportOrdersHelper.exportToExcel(
                                                  context,
                                                  state.data,
                                                );
                                                Navigator.of(
                                                  context,
                                                ).pop(true); // User pressed Yes
                                              },
                                              child: const Text(
                                                "Yes, Reset",
                                                style: TextStyle(
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                          ],
                                        );
                                      },
                                    );

                                    if (confirm == true) {
                                      context
                                          .read<ExternalOrdersCubit>()
                                          .clearAllExternalOrders();
                                    }
                                  },
                                  title: 'Reset All',
                                ),
                              ],
                            )
                          : Center(
                              child: Padding(
                                padding: const EdgeInsets.only(top: 100),
                                child: Text(
                                  "No orders found",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                      const SizedBox(height: 20),
                      // ADDED: Total price display
                      if (state is SuccessGetExternalOrders &&
                          state.data.isNotEmpty) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          margin: const EdgeInsets.only(bottom: 20),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: AppColors.primaryBlue,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,

                            children: [
                              Text(
                                "Total:",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                "${_calculateAllOrdersTotal(state.data).toStringAsFixed(0)} L.E",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      if (state is SuccessGetExternalOrders) ...[
                        Expanded(
                          child: ListView.separated(
                            scrollDirection: Axis.vertical,
                            itemBuilder: (context, index) {
                              return Row(
                                children: [
                                  Expanded(
                                    child: Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(20),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(
                                          12,
                                        ),
                                        color: AppColors.bgDark,
                                      ),
                                      child: InkWell(
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  OrdersInvoicePage(
                                                    orderId:
                                                        '${state.data.length - index}',
                                                    orderItems:
                                                        state.data[index].order,
                                                  ),
                                            ),
                                          );
                                        },
                                        child: Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceEvenly,
                                          children: [
                                            Expanded(
                                              child: Text(
                                                "Order #${state.data.length - index}",
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ),

                                            Expanded(
                                              child: Text(
                                                state.data[index].order
                                                    .map((e) => e.name)
                                                    .join(", "),
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ),
                                            Text(
                                              "${_calculateOrderTotal(state.data[index].order).toStringAsFixed(0)} L.E",
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            SizedBox(width: 12),
                                            Icon(
                                              state.data[index].payment == true
                                                  ? Icons.verified
                                                  : Icons.close,
                                              color:
                                                  state.data[index].payment ==
                                                      true
                                                  ? Colors.green
                                                  : Colors.red,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 20),
                                  InkWell(
                                    onTap: () {
                                      context
                                          .read<ExternalOrdersCubit>()
                                          .deleteOrderFunc(
                                            state.data[index].id,
                                          );
                                    },
                                    child: Icon(
                                      Icons.delete,
                                      color: Colors.white,
                                    ),
                                  ),
                                  DropdownButton(
                                    items: items,
                                    onChanged: (value) async {
                                      if (value != state.data[index].payment) {
                                        await context
                                            .read<ExternalOrdersCubit>()
                                            .editExternalOrderFunc(
                                              externalOrdersModel:
                                                  ExternalOrdersModel(
                                                    id: state.data[index].id,
                                                    table: 'table1',
                                                    order:
                                                        state.data[index].order,
                                                    payment: !state
                                                        .data[index]
                                                        .payment,
                                                  ),
                                            );
                                      }
                                    },
                                    icon: Icon(Icons.more_horiz),
                                    underline: SizedBox(),
                                    value: state.data[index].payment,
                                    disabledHint: SizedBox(),
                                    hint: SizedBox(),
                                    focusColor: Colors.transparent,
                                  ),
                                ],
                              );
                            },
                            separatorBuilder: (context, index) =>
                                const SizedBox(height: 20),
                            itemCount: state.data.length,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
        );
      },
    );
  }
}
