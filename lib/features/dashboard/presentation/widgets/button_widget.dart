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

class ExportButtonsWidget extends StatelessWidget {
  const ExportButtonsWidget({
    super.key,
    required this.onPressed,
    required this.icon,
    required this.title,
  });
  final void Function() onPressed;
  final IconData icon;
  final String title;
  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      style: ButtonStyle(
        backgroundColor: WidgetStatePropertyAll(
          Colors.transparent,
        ),
        side: WidgetStatePropertyAll(
          BorderSide(color: Colors.white),
        ),
      ),
      onPressed: onPressed,
      icon: Icon(
        icon,
        color: Colors.white,
      ),
      label: Text(
        title,
        style: TextStyle(
          color: Colors.white,
        ),
      ),
    );
  }
}

class AddButton extends StatelessWidget {
  const AddButton({super.key, required this.title, required this.onPressed});
  final String title;
  final void Function()? onPressed;
  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      style: ButtonStyle(
        backgroundColor: WidgetStatePropertyAll(
          AppColors.blueColor,
        ),
        padding: WidgetStatePropertyAll(
          EdgeInsetsGeometry.symmetric(
            vertical: 16,
            horizontal: 12,
          ),
        ),
        side: WidgetStatePropertyAll(
          BorderSide(
            width: 3,
            color: AppColors.yellowColor,
          ),
        ),
      ),
      onPressed: onPressed,
      icon: Icon(
        Icons.add_circle_outlined,
        color: Colors.white,
        size: 16,
      ),
      label: Text(
        title,
        style: TextStyle(
          color: Colors.white,
        ),
      ),
    );
  }
}
