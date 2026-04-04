// ignore_for_file: deprecated_member_use

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quarto/core/colors/app_colors.dart';
import 'package:quarto/core/common/app_button.dart';
import 'package:quarto/core/fonts/app_text.dart';
import 'package:quarto/features/cafe/data/model/cafe_outcomes_model.dart';
import 'package:quarto/features/cafe/presentation/cubits/cafe_outcomes_cubit/cafe_outcomes_cubit.dart';
import 'package:quarto/features/dashboard/data/model/room_outcomes_model.dart';
import 'package:quarto/features/dashboard/presentation/cubits/outcomes/outcomes_cubit.dart';

class AddMaterialDailoge extends StatefulWidget {
  const AddMaterialDailoge({super.key, required this.isRoom});
  final bool isRoom;
  @override
  State<AddMaterialDailoge> createState() => _AddMaterialDailogeState();
}

class _AddMaterialDailogeState extends State<AddMaterialDailoge> {
  final TextEditingController typeController = TextEditingController();
  final TextEditingController quantityController = TextEditingController();
  final TextEditingController priceController = TextEditingController();

  double totalPrice = 0;

  void calculateTotal() {
    final quantity = int.tryParse(quantityController.text) ?? 0;
    final price = double.tryParse(priceController.text) ?? 0;

    setState(() {
      totalPrice = quantity * price;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      alignment: AlignmentGeometry.center,
      backgroundColor: Colors.transparent,
      content: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: 15,
            sigmaY: 15,
          ),
          child: Container(
            constraints: BoxConstraints(
              minWidth: 400,
            ),
            padding: EdgeInsets.symmetric(
              vertical: 20,
              horizontal: 20,
            ),
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  blurRadius: 30,
                  spreadRadius: -5,
                  color: Colors.black.withOpacity(0.3),
                ),
              ],
              color: Colors.white.withOpacity(
                0.05,
              ),

              border: Border.all(
                color: Colors.white.withOpacity(
                  0.2,
                ),
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Add material',
                      style: AppTexts.meduimHeading,
                    ),
                    InkWell(
                      onTap: () {
                        Navigator.pop(context);
                      },
                      child: Icon(
                        Icons.close,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 30),
                Text(
                  'Type',
                  style: AppTexts.smallHeading,
                ),
                SizedBox(height: 12),
                TextField(
                  style: AppTexts.meduimBody,
                  controller: typeController,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: Colors.white,
                      ),
                    ),
                    filled: true,
                    fillColor: Colors.transparent,
                  ),
                ),
                SizedBox(height: 20),
                Text(
                  'Quantity',
                  style: AppTexts.smallHeading,
                ),
                SizedBox(height: 12),
                TextField(
                  style: AppTexts.meduimBody,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  controller: quantityController,
                  keyboardType: TextInputType.number,
                  onChanged: (_) => calculateTotal(),
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.white),
                    ),
                    filled: true,
                    fillColor: Colors.transparent,
                  ),
                ),
                SizedBox(height: 20),
                Text(
                  'Price per unit',
                  style: AppTexts.smallHeading,
                ),
                SizedBox(height: 12),
                TextField(
                  style: AppTexts.meduimBody,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  controller: priceController,
                  keyboardType: TextInputType.number,
                  onChanged: (_) => calculateTotal(),
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.white),
                    ),
                    filled: true,
                    fillColor: Colors.transparent,
                  ),
                ),
                SizedBox(height: 20),
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Total Price :',
                        style: AppTexts.meduimHeading.copyWith(
                          color: AppColors.yellowColor,
                        ),
                      ),
                      Text(
                        ' \$${totalPrice.toStringAsFixed(0)}',
                        style: AppTexts.meduimHeading,
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 20),
                Align(
                  alignment: AlignmentGeometry.center,
                  child: AppButton(
                    buttonTitle: 'Add material',
                    icon: Icons.add_circle_outlined,
                    buttonColor: AppColors.yellowColor,
                    borderColor: AppColors.yellowColor,
                    textColor: AppColors.blueColor,
                    onPressed: () {
                      if (typeController.text.isEmpty ||
                          quantityController.text.isEmpty ||
                          priceController.text.isEmpty) {
                        return;
                      }
                      final quantity =
                          int.tryParse(quantityController.text) ?? 0;
                      final price = double.tryParse(priceController.text) ?? 0;

                      widget.isRoom == false
                          ? context
                                .read<CafeOutcomesCubit>()
                                .addOutCafecomesFunc(
                                  items: CafeOutcomesModel(
                                    material: typeController.text,
                                    quantity: quantity,
                                    price: price,
                                  ),
                                )
                          : context
                                .read<RoomOutcomesCubit>()
                                .addRoomOutcomesFunc(
                                  items: RoomOutcomesModel(
                                    material: typeController.text,
                                    quantity: quantity,
                                    price: price,
                                  ),
                                );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
