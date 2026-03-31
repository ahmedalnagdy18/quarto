import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quarto/core/colors/app_colors.dart';
import 'package:quarto/core/common/app_button.dart';
import 'package:quarto/features/cafe/data/model/cafe_tabels_model.dart';
import 'package:quarto/features/cafe/presentation/cubits/tabels_cubit/cafe_tables_cubit.dart';

class TableCardWidget extends StatefulWidget {
  const TableCardWidget({super.key, required this.table});
  final CafeTableModel table;
  @override
  State<TableCardWidget> createState() => _TableCardWidgetState();
}

class _TableCardWidgetState extends State<TableCardWidget> {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 2),
      clipBehavior: Clip.antiAlias,
      width: 270,
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            blurRadius: 1,
            color: Colors.white10,
            spreadRadius: 1,
            offset: Offset(0, 0),
          ),
        ],
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white24, strokeAlign: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.table_bar_outlined,
                color: Colors.white,
              ),
              SizedBox(width: 6),
              Text(
                widget.table.tableName,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          SizedBox(height: 30),
          BlocBuilder<CafeTablesCubit, CafeTablesState>(
            builder: (context, state) {
              if (state is SuccessGetTables) {
                final table = state.tables.firstWhere(
                  (r) => r.id == widget.table.id,
                );
                return table.isOccupied == true
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          AppButton(
                            buttonColor: Colors.red,
                            borderColor: Colors.red,
                            buttonTitle: 'End',
                            icon: Icons.close,
                            width: 1,
                            onPressed: () {},
                          ),
                          AppButton(
                            buttonColor: AppColors.yellowColor,
                            borderColor: AppColors.yellowColor,
                            buttonTitle: 'Manage',
                            icon: Icons.add_circle,
                            width: 1,
                            textColor: AppColors.blueColor,
                            onPressed: () {},
                          ),
                          AppButton(
                            buttonColor: Colors.transparent,
                            borderColor: Colors.white,
                            buttonTitle: 'Move',
                            icon: Icons.move_down_outlined,
                            width: 1,
                            onPressed: () {},
                          ),
                        ],
                      )
                    : Center(
                        child: AppButton(
                          buttonColor: AppColors.blueColor,
                          borderColor: AppColors.yellowColor,
                          buttonTitle: 'Add order',
                          icon: Icons.add_circle,
                          onPressed: () {},
                        ),
                      );
              }
              return SizedBox();
            },
          ),
        ],
      ),
    );
  }
}
