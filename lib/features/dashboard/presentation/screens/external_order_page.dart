import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quarto/core/colors/app_colors.dart';
import 'package:quarto/core/fonts/app_text.dart';
import 'package:quarto/features/dashboard/presentation/cubits/external_order/external_orders_cubit.dart';
import 'package:quarto/features/dashboard/presentation/screens/orders_invoice_page.dart';
import 'package:quarto/features/dashboard/presentation/widgets/external_order_dailog_widget.dart';

class ExternalOrderPage extends StatefulWidget {
  const ExternalOrderPage({super.key});

  @override
  State<ExternalOrderPage> createState() => _ExternalOrderPageState();
}

class _ExternalOrderPageState extends State<ExternalOrderPage> {
  // Helper method to calculate total
  int _calculateTotal(List<int> prices) {
    return prices.fold(0, (sum, price) => sum + price);
  }

  @override
  void initState() {
    context.read<ExternalOrdersCubit>().getExternalOrders();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ExternalOrdersCubit, ExternalOrdersState>(
      listener: (context, state) {
        if (state is ErrorGetExternalOrders) {
          print(state.message);
        }
        if (state is SuccessDeleteExternalOrder) {
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
          body: state is LoadingGetExternalOrders
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
                                "\$${_calculateTotal(state.data.map((e) => e.price).toList())}",
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
                                                    orderId: '${index + 1}',
                                                    orderItems:
                                                        state.data[index].order,
                                                    totalPrice:
                                                        state.data[index].price,
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
                                                "Order #${index + 1}",
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ),

                                            Expanded(
                                              child: Text(
                                                state.data[index].order,
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ),
                                            Text(
                                              "${state.data[index].price.toString()} L.E",
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.w500,
                                              ),
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
