import 'package:flutter/material.dart';
import 'package:quarto/core/colors/app_colors.dart';
import 'package:quarto/core/common/cafe_order_dailoge_widget.dart';
import 'package:quarto/core/common/vip_widget.dart';
import 'package:quarto/core/fonts/app_text.dart';
import 'package:quarto/features/cafe/data/model/cafe_tabels_model.dart';
import 'package:quarto/features/dashboard/presentation/widgets/button_widget.dart';

class TabelDetailsPage extends StatefulWidget {
  const TabelDetailsPage({super.key, required this.cafeTable});
  final CafeTableModel cafeTable;
  @override
  State<TabelDetailsPage> createState() => _TabelDetailsPageState();
}

class _TabelDetailsPageState extends State<TabelDetailsPage> {
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final horizontalPadding = 60.0;
    final availableWidth = screenWidth - horizontalPadding;
    final cardWidth = (availableWidth - 40) / 3;
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
                      SizedBox(width: 20),
                      Container(
                        margin: EdgeInsets.only(right: 10),
                        child: AddButton(
                          title: "Add order",
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (context) => CafeOrderDailogeWidget(
                                orderType: "Table",
                                tableId: widget.cafeTable.id,
                              ),
                            );
                          },
                        ),
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
                        '${widget.cafeTable.tableName} - Overview',
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
                          data: "--",
                        ),
                      ),
                      SizedBox(width: 20),
                      Expanded(
                        child: activeTableCard(
                          icon: Icons.date_range_outlined,
                          title: 'Date',
                          data: "Single",
                        ),
                      ),
                      SizedBox(width: 20),
                      Expanded(
                        child: activeTableCard(
                          icon: Icons.payments_outlined,
                          title: 'Payment Method',
                          widget: VipWidget(
                            title: 'Visa',
                          ),
                          data: "",
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
                  activeTableCard(
                    width: cardWidth,
                    icon: Icons.payments_outlined,
                    title: 'Total',
                    data: "0 \$",
                    backgroundColor: AppColors.yellowColor,
                    textColor: AppColors.blueColor,
                  ),
                  SizedBox(height: 30),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: tabelorderWidget(
                          color: AppColors.blueColor,
                          orderHistory: false,
                        ),
                      ),
                      SizedBox(width: 20),
                      Expanded(
                        child: SizedBox(),
                        // tabelorderWidget(
                        //   color: Colors.transparent,
                        //   orderHistory: true,
                        // ),
                      ),
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
    padding: EdgeInsets.all(12),
    decoration: BoxDecoration(
      boxShadow: [
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
        SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            color: textColor ?? Colors.white,
          ),
        ),
        Spacer(),
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
}) {
  return Container(
    padding: EdgeInsets.all(12),
    constraints: BoxConstraints(
      minHeight: 100,
    ),
    decoration: BoxDecoration(
      boxShadow: orderHistory == true
          ? [
              BoxShadow(
                blurRadius: 1,
                color: Colors.white10,
                spreadRadius: 0,
                offset: Offset(0, 0),
              ),
            ]
          : null,
      border: Border.all(
        color: orderHistory == true ? Colors.white12 : color,
        width: 1,
      ),
      borderRadius: BorderRadius.circular(12),
      color: color,
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.add_to_drive_rounded,
              color: Colors.white,
              size: 18,
            ),
            SizedBox(width: 8),
            Text(
              'data',
              style: AppTexts.meduimBody,
            ),
          ],
        ),
        SizedBox(height: 12),
        ListView.builder(
          shrinkWrap: true,
          itemCount: 3,
          itemBuilder: (context, index) {
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'data',
                  style: AppTexts.smallBody,
                ),
                Text(
                  'data',
                  style: AppTexts.smallBody,
                ),
              ],
            );
          },
        ),
        SizedBox(height: 4),
        Divider(),
        SizedBox(height: 4),
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
              '150',
              style: AppTexts.meduimBody.copyWith(
                color: AppColors.yellowColor,
              ),
            ),
          ],
        ),
      ],
    ),
  );
}
