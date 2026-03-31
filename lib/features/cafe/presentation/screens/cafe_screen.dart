import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quarto/core/colors/app_colors.dart';
import 'package:quarto/core/common/app_button.dart';
import 'package:quarto/core/fonts/app_text.dart';
import 'package:quarto/features/cafe/presentation/cubits/tabels_cubit/cafe_tables_cubit.dart';
import 'package:quarto/features/cafe/presentation/screens/orders_details_page.dart';
import 'package:quarto/features/cafe/presentation/screens/tabel_details_page.dart';
import 'package:quarto/features/cafe/presentation/widgets/table_card_widget.dart';
import 'package:quarto/features/dashboard/presentation/cubits/rooms/rooms_cubit.dart';
import 'package:quarto/features/dashboard/presentation/widgets/button_widget.dart';
import 'package:quarto/features/dashboard/presentation/widgets/card_widget.dart';

class CafeScreen extends StatefulWidget {
  const CafeScreen({super.key});

  @override
  State<CafeScreen> createState() => _CafeScreenState();
}

class _CafeScreenState extends State<CafeScreen> {
  @override
  void initState() {
    context.read<CafeTablesCubit>().getTables();
    super.initState();
  }

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
                  Image.asset(
                    'images/quarto_logo.png',
                    scale: 4,
                  ),
                  Spacer(),
                  ExportButtonsWidget(
                    title: 'Export rooms',
                    icon: Icons.download,
                    onPressed: () {},
                  ),
                  SizedBox(width: 20),
                  ExportButtonsWidget(
                    title: 'Orders',
                    icon: Icons.list,
                    onPressed: () {
                      Navigator.push(
                        context,
                        CupertinoPageRoute(
                          builder: (context) => OrdersDetailsPage(),
                        ),
                      );
                    },
                  ),
                  SizedBox(width: 20),
                  ExportButtonsWidget(
                    title: 'Outcomes',
                    icon: Icons.wallet,
                    onPressed: () {},
                  ),
                ],
              ),
              SizedBox(height: 20),
              Text(
                'Cafe Orders Management',
                style: TextStyle(
                  fontSize: 20,
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 12),
              Text(
                'Track and manage orders placed by customers seated at cafe .',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 26),
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
                  }
                  return Row(
                    children: [
                      Expanded(
                        child: CardWidget(
                          data: "$freeTables",
                          title: 'Free tabels',
                          cafeState: state,
                        ),
                      ),
                      SizedBox(width: 20),
                      Expanded(
                        child: CardWidget(
                          data: "$occupiedTables",
                          title: 'Occupied tabels',
                          cafeState: state,
                        ),
                      ),
                      SizedBox(width: 20),
                      Expanded(
                        child: CardWidget(
                          data: '${todayIncome.toStringAsFixed(0)}\$',
                          title: 'income',
                          cafeState: state,
                        ),
                      ),
                      SizedBox(width: 20),
                      Expanded(
                        child: CardWidget(
                          data: "20\$",
                          title: 'Outcomes',
                        ),
                      ),
                    ],
                  );
                },
              ),
              SizedBox(height: 30),
              Text(
                'Cafe orders',
                style: TextStyle(
                  fontSize: 20,
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 12),
              Text(
                'Track and manage orders placed by customers seated at cafe .',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 26),
              Row(
                children: [
                  Expanded(
                    child: addOrderWidget(
                      icon: Icons.people_alt_outlined,
                      title: 'Staff Order',
                      subTitle: 'order placed by staff',
                      onPressed: () {},
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: addOrderWidget(
                      icon: Icons.shopping_cart_outlined,
                      title: 'Takeaway Order',
                      subTitle: 'Create a new order for pickup or walk-in',
                      onPressed: () {},
                    ),
                  ),
                ],
              ),
              SizedBox(height: 30),
              Text(
                'Cafe Tabels',
                style: TextStyle(
                  fontSize: 20,
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 12),
              Text(
                'Track and manage orders placed by customers seated at cafe .',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 26),
              BlocListener<RoomsCubit, RoomsState>(
                listener: (context, state) {
                  if (state is SuccessGetTables) {
                    // context.read<DashboardCubit>().loadDashboardStats();
                    //todo: add ==============
                  }
                },
                child: BlocBuilder<CafeTablesCubit, CafeTablesState>(
                  builder: (context, state) {
                    if (state is SuccessGetTables) {
                      return Wrap(
                        spacing: 15,
                        runSpacing: 15,
                        children: List.generate(
                          state.tables.length,
                          (index) => GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                CupertinoPageRoute(
                                  builder: (context) => TabelDetailsPage(
                                    cafeTable: state.tables[index],
                                  ),
                                ),
                              );
                            },
                            child: TableCardWidget(
                              table: state.tables[index],
                            ),
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
              ),
              SizedBox(height: 100),
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
    padding: EdgeInsets.all(8),
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
