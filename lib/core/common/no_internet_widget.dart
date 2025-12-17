import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:quarto/core/fonts/app_text.dart';

class NoInternetWidget extends StatelessWidget {
  const NoInternetWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            constraints: BoxConstraints(
              maxHeight: 300,
              minWidth: double.infinity,
            ),
            child: SvgPicture.asset("images/no_internet.svg"),
          ),
          SizedBox(height: 12),
          Text(
            "No Internet Connection",
            style: AppTexts.meduimHeading,
          ),
          SizedBox(height: 8),
          Text(
            "Please Check Your Internet",
            style: AppTexts.regularBody,
          ),
        ],
      ),
    );
  }
}
