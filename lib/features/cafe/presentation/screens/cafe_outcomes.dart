// ignore_for_file: deprecated_member_use

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quarto/core/colors/app_colors.dart';
import 'package:quarto/core/common/add_material_dailoge.dart';
import 'package:quarto/core/common/app_button.dart';
import 'package:quarto/core/fonts/app_text.dart';
import 'package:quarto/features/cafe/presentation/cubits/cafe_outcomes_cubit/cafe_outcomes_cubit.dart';
import 'package:quarto/features/cafe/presentation/utils/cafe_order_utils.dart';
import 'package:quarto/features/dashboard/presentation/widgets/button_widget.dart';
import 'package:quarto/features/dashboard/presentation/widgets/card_widget.dart';

class CafeOutcomes extends StatefulWidget {
  const CafeOutcomes({super.key, required this.totalRevenue});
  final double totalRevenue;

  @override
  State<CafeOutcomes> createState() => _CafeOutcomesState();
}

class _CafeOutcomesState extends State<CafeOutcomes> {
  int currentPage = 1;
  final int itemsPerPage = 5;

  @override
  void initState() {
    context.read<CafeOutcomesCubit>().getCafeOutcomes();
    super.initState();
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
          BlocConsumer<CafeOutcomesCubit, CafeOutcomesState>(
            listener: (context, state) {
              if (state is SuccessAddCafeOutcomes) {
                Navigator.pop(context);
                context.read<CafeOutcomesCubit>().getCafeOutcomes();
              }
            },
            builder: (context, state) {
              if (state is LoadingAddCafeOutcomes ||
                  state is LoadingGetCafeOutcomes) {
                return Center(
                  child: CircularProgressIndicator(
                    color: AppColors.yellowColor,
                  ),
                );
              }
              if (state is SuccessGetCafeOutcomes) {
                final totalExpenses = state.data.fold<double>(
                  0,
                  (sum, item) => sum + (item.price * item.quantity),
                );
                final netProfit = widget.totalRevenue - totalExpenses;

                /// 🔹 Pagination logic
                final startIndex = (currentPage - 1) * itemsPerPage;
                final endIndex = startIndex + itemsPerPage;

                final paginatedData = state.data.sublist(
                  startIndex,
                  endIndex > state.data.length ? state.data.length : endIndex,
                );

                final totalPages = (state.data.length / itemsPerPage).ceil();

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 30),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        /// 🔹 Header
                        Row(
                          children: [
                            Image.asset('images/quarto_logo.png', scale: 4),
                            const Spacer(),
                            ExportButtonsWidget(
                              title: 'Export Report',
                              icon: Icons.download_outlined,
                              onPressed: () {},
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        Row(
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
                              'Cafe Outcomes',
                              style: TextStyle(
                                fontSize: 20,
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const Spacer(),
                            AppButton(
                              buttonTitle: 'Add material',
                              icon: Icons.add_circle_outlined,
                              buttonColor: AppColors.yellowColor,
                              borderColor: AppColors.yellowColor,
                              textColor: AppColors.blueColor,
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (context) => AddMaterialDailoge(
                                    isRoom: false,
                                  ),
                                );
                              },
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),
                        Padding(
                          padding: const EdgeInsets.only(left: 38),
                          child: Text(
                            'Track your revenue, expenses, and net performance in real time',
                            style: AppTexts.smallBody,
                          ),
                        ),

                        const SizedBox(height: 20),

                        /// 🔹 Cards
                        Row(
                          children: [
                            Expanded(
                              child: CardWidget(
                                data:
                                    '${widget.totalRevenue.toStringAsFixed(0)}\$',
                                title: 'Total Revenue',
                              ),
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              child: CardWidget(
                                data: '${totalExpenses.toStringAsFixed(0)}\$',
                                title: 'Expenses',
                              ),
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              child: CardWidget(
                                data: '${netProfit.toStringAsFixed(0)}\$',
                                title: 'Net Profit',
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        const Text(
                          'Recent Transactions',
                          style: TextStyle(
                            fontSize: 20,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),

                        const SizedBox(height: 20),

                        /// 🔥 TABLE (FIXED)
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white12),
                          ),
                          child: Column(
                            children: [
                              /// 🔹 HEADER
                              Container(
                                decoration: BoxDecoration(
                                  border: Border(
                                    bottom: BorderSide(
                                      color: Colors.white12,
                                    ),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    _cell(
                                      child: Text('#', style: _headerStyle),
                                    ),
                                    _cell(
                                      child: Text(
                                        'Material',
                                        style: _headerStyle,
                                      ),
                                      flex: 3,
                                    ),
                                    _cell(
                                      child: Text(
                                        'Quantity',
                                        style: _headerStyle,
                                      ),
                                      flex: 2,
                                    ),
                                    _cell(
                                      child: Text(
                                        'Date',
                                        style: _headerStyle,
                                      ),
                                      flex: 4,
                                    ),
                                    _cell(
                                      child: Text(
                                        'Total cost',
                                        style: _headerStyle,
                                      ),
                                      flex: 2,
                                      showRightBorder: false,
                                    ),
                                  ],
                                ),
                              ),

                              /// 🔹 ROWS (NO SCROLL)
                              ...List.generate(itemsPerPage, (index) {
                                if (index >= paginatedData.length) {
                                  /// empty row
                                  return Container(
                                    height: 48,
                                    decoration: BoxDecoration(
                                      border: Border(
                                        bottom: BorderSide(
                                          color: Colors.white10,
                                        ),
                                      ),
                                    ),
                                  );
                                }

                                final item = paginatedData[index];

                                return Container(
                                  decoration: BoxDecoration(
                                    border: Border(
                                      bottom: BorderSide(
                                        color: Colors.white10,
                                      ),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      _cell(
                                        child: Text(
                                          '${startIndex + index + 1}',
                                          style: _rowStyle,
                                        ),
                                      ),
                                      _cell(
                                        child: Text(
                                          item.material,
                                          style: _rowStyle,
                                        ),
                                        flex: 3,
                                      ),
                                      _cell(
                                        child: Text(
                                          '${item.quantity}',
                                          style: _rowStyle,
                                        ),
                                        flex: 2,
                                      ),
                                      _cell(
                                        child: Text(
                                          '${formatOrderDate(item.date!)} - ${formatOrderTime(item.date!)}',
                                          style: _rowStyle,
                                        ),
                                        flex: 4,
                                      ),
                                      _cell(
                                        child: Text(
                                          '${(item.price * item.quantity).toStringAsFixed(0)} EGP',
                                          style: _rowStyle,
                                        ),
                                        flex: 2,
                                        showRightBorder: false,
                                      ),
                                    ],
                                  ),
                                );
                              }),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        /// 🔥 PAGINATION OUTSIDE TABLE
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            IconButton(
                              onPressed: currentPage > 1
                                  ? () => setState(() => currentPage--)
                                  : null,
                              icon: const Icon(
                                Icons.arrow_back,
                                color: Colors.white,
                              ),
                            ),

                            ...List.generate(totalPages, (index) {
                              final page = index + 1;
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                ),
                                child: GestureDetector(
                                  onTap: () =>
                                      setState(() => currentPage = page),
                                  child: _pageItem(
                                    '$page',
                                    isActive: currentPage == page,
                                  ),
                                ),
                              );
                            }),

                            IconButton(
                              onPressed: currentPage < totalPages
                                  ? () => setState(() => currentPage++)
                                  : null,
                              icon: const Icon(
                                Icons.arrow_forward,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 40),
                      ],
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
        ],
      ),
    );
  }
}

const _headerStyle = TextStyle(
  color: Colors.white70,
  fontWeight: FontWeight.w600,
  fontSize: 14,
);

const _rowStyle = TextStyle(
  color: Colors.white,
  fontSize: 14,
);

Widget _pageItem(String text, {bool isActive = false}) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: isActive ? AppColors.yellowColor : Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: Colors.white24),
    ),
    child: Text(
      text,
      style: TextStyle(
        color: isActive ? Colors.black : Colors.white,
        fontWeight: FontWeight.w500,
      ),
    ),
  );
}

Widget _cell({
  required Widget child,
  int flex = 1,
  bool showRightBorder = true,
}) {
  return Expanded(
    flex: flex,
    child: Container(
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: showRightBorder
            ? Border(right: BorderSide(color: Colors.white12))
            : null,
      ),
      child: child,
    ),
  );
}
