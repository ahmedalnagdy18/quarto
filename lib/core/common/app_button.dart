import 'package:flutter/material.dart';
import 'package:quarto/core/fonts/app_text.dart';

class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.buttonTitle,
    required this.onPressed,
    required this.icon,
    required this.buttonColor,
    required this.borderColor,
    this.width,
    this.textColor,
  });
  final String buttonTitle;
  final void Function() onPressed;
  final IconData icon;
  final Color buttonColor;
  final Color borderColor;
  final double? width;
  final Color? textColor;
  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      style: ButtonStyle(
        shape: WidgetStatePropertyAll(
          ContinuousRectangleBorder(
            borderRadius: BorderRadiusGeometry.circular(12),
          ),
        ),
        padding: WidgetStatePropertyAll(
          EdgeInsetsGeometry.symmetric(
            horizontal: 12,
            vertical: 8,
          ),
        ),
        backgroundColor: WidgetStatePropertyAll(
          buttonColor,
        ),
        side: WidgetStatePropertyAll(
          BorderSide(
            width: width ?? 3,
            color: borderColor,
          ),
        ),
      ),
      icon: Icon(
        icon,
        color: textColor ?? Colors.white,
        size: 14,
      ),
      label: Text(
        buttonTitle,
        style: AppTexts.smallBody.copyWith(
          color: textColor ?? Colors.white,
        ),
      ),
      onPressed: onPressed,
    );
  }
}
