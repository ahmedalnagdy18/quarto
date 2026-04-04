import 'package:flutter/material.dart';
import 'package:quarto/core/colors/app_colors.dart';
import 'package:quarto/core/common/app_button.dart';
import 'package:quarto/features/cafe/data/model/cafe_tabels_model.dart';

class TableCardWidget extends StatelessWidget {
  const TableCardWidget({
    super.key,
    required this.table,
    required this.onAddOrder,
    required this.onManage,
    required this.onMove,
    required this.onEnd,
  });

  final CafeTableModel table;
  final VoidCallback onAddOrder;
  final VoidCallback onManage;
  final VoidCallback onMove;
  final VoidCallback onEnd;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      clipBehavior: Clip.antiAlias,
      width: 270,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      decoration: BoxDecoration(
        boxShadow: const [
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
              const Icon(
                Icons.table_bar_outlined,
                color: Colors.white,
              ),
              const SizedBox(width: 6),
              Text(
                table.tableName,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 30),
          table.isOccupied
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    AppButton(
                      buttonColor: Colors.red,
                      borderColor: Colors.red,
                      buttonTitle: 'End',
                      icon: Icons.close,
                      width: 1,
                      onPressed: onEnd,
                    ),
                    AppButton(
                      buttonColor: AppColors.yellowColor,
                      borderColor: AppColors.yellowColor,
                      buttonTitle: 'Manage',
                      icon: Icons.add_circle,
                      width: 1,
                      textColor: AppColors.blueColor,
                      onPressed: onManage,
                    ),
                    AppButton(
                      buttonColor: Colors.transparent,
                      borderColor: Colors.white,
                      buttonTitle: 'Move',
                      icon: Icons.move_down_outlined,
                      width: 1,
                      onPressed: onMove,
                    ),
                  ],
                )
              : Center(
                  child: AppButton(
                    buttonColor: AppColors.blueColor,
                    borderColor: AppColors.yellowColor,
                    buttonTitle: 'Add order',
                    icon: Icons.add_circle,
                    onPressed: onAddOrder,
                  ),
                ),
        ],
      ),
    );
  }
}
