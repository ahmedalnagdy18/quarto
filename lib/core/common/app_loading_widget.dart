import 'package:flutter/material.dart';
import 'package:quarto/core/colors/app_colors.dart';

class AppLoadingWidget extends StatelessWidget {
  const AppLoadingWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: CircularProgressIndicator(
        color: AppColors.primaryBlue,
      ),
    );
  }
}
