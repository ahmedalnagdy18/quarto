import 'package:flutter/material.dart';
import 'package:quarto/core/colors/app_colors.dart';
import 'package:quarto/core/common/vip_widget.dart';
import 'package:quarto/core/extentions/app_extentions.dart';
import 'package:quarto/core/fonts/app_text.dart';
import 'package:quarto/features/cafe/data/model/order_model.dart';
import 'package:quarto/features/cafe/presentation/screens/tabel_details_page.dart';
import 'package:quarto/features/cafe/presentation/utils/cafe_order_utils.dart';
import 'package:quarto/features/dashboard/presentation/widgets/button_widget.dart';

class OrdersItemDetails extends StatefulWidget {
  const OrdersItemDetails({super.key, required this.order});
  final OrderModel order;
  @override
  State<OrdersItemDetails> createState() => _OrdersItemDetailsState();
}

class _OrdersItemDetailsState extends State<OrdersItemDetails> {
  @override
  Widget build(BuildContext context) {
    final orderTotal = calculateOrderTotal(widget.order);
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
                        title: 'Export Order history',
                        icon: Icons.download_outlined,
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
                        'Transaction Overview',
                        style: TextStyle(
                          fontSize: 20,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 30),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: activeTableCard(
                          icon: Icons.shopify_outlined,
                          title: 'Order ID',
                          data: formatOrderId(widget.order.id),
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: activeTableCard(
                          icon: Icons.date_range_outlined,
                          title: 'Date',
                          data: formatOrderDate(widget.order.orderTime),
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: activeTableCard(
                          icon: Icons.filter_list_outlined,
                          title: 'Type',
                          data: widget.order.orderType,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: activeTableCard(
                          icon: Icons.payments_outlined,
                          title: 'Payment Method',
                          widget: const VipWidget(title: 'Cash'),
                          data: '',
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: activeTableCard(
                          icon: Icons.history,
                          title: 'Status',
                          widget: Container(
                            padding: EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.green,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.verified_outlined,
                                  color: Colors.white,
                                  size: 16,
                                ),
                                SizedBox(width: 8),
                                Text('Delivered', style: AppTexts.smallBody),
                              ],
                            ),
                          ),
                          data: '',
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: activeTableCard(
                          icon: Icons.payments_outlined,
                          title: 'Total',
                          data: '${orderTotal.toStringAsFixed(0)} \$',
                          backgroundColor: AppColors.yellowColor,
                          textColor: AppColors.blueColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: _orderItemWidget(
                          color: AppColors.blueColor,
                          order: widget.order,
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

Widget _orderItemWidget({
  required Color color,
  required OrderModel? order,
}) {
  return Container(
    padding: const EdgeInsets.all(12),
    constraints: const BoxConstraints(minHeight: 100),
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
      color: Colors.transparent,
      border: Border.all(color: Colors.white10),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.list,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 8),
            Text('Orders Summary', style: AppTexts.meduimBody),
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
