import 'package:flutter/material.dart';
import 'package:quarto/core/colors/app_colors.dart';

class ButtonWidget extends StatelessWidget {
  const ButtonWidget({super.key, required this.onPressed, required this.title});
  final void Function() onPressed;
  final String title;
  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ButtonStyle(
        backgroundColor: WidgetStatePropertyAll(
          AppColors.primaryBlue,
        ),
        foregroundColor: WidgetStatePropertyAll(
          Colors.white,
        ),
      ),
      onPressed: onPressed,
      child: Text(title),
    );
  }
}
