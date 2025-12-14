import 'package:flutter/material.dart';
import 'package:quarto/core/fonts/app_text.dart';

class VipWidget extends StatelessWidget {
  const VipWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        color: Colors.yellow.withOpacity(0.15),
        border: Border.all(
          color: Colors.yellow.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            "Vip Room",
            style: AppTexts.smallBody.copyWith(
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}
