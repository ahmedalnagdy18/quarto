import 'package:flutter/material.dart';
import 'package:quarto/core/colors/app_colors.dart';
import 'package:quarto/features/dashboard/presentation/screens/dashboard_page.dart';

class StartNewDayWidget extends StatelessWidget {
  const StartNewDayWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(
        '🎯 Start New Day',
        style: TextStyle(color: Colors.white),
      ),
      backgroundColor: AppColors.bgDark,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'This action will:',
            style: TextStyle(color: Colors.grey, fontSize: 14),
          ),
          const SizedBox(height: 8),
          _buildActionItem('1. End all active sessions'),
          _buildActionItem('2. Reset all rooms to free'),
          _buildActionItem('3. Clear today\'s history'),
          _buildActionItem('4. Reset today\'s income to 0'),
          const SizedBox(height: 16),
          const Text(
            '⚠️ This cannot be undone!',
            style: TextStyle(color: Colors.orange, fontSize: 14),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(
            'Cancel',
            style: TextStyle(color: Colors.grey),
          ),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          onPressed: () {
            // Close the confirmation dialog
            Navigator.pop(context);

            // Show the processing dialog
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) => StartNewDayDialog(parentContext: context),
            );
          },
          child: const Text(
            'Start New Day',
            style: TextStyle(color: Colors.white),
          ),
        ),
      ],
    );
  }
}

Widget _buildActionItem(String text) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      children: [
        const Icon(Icons.check_circle, color: Colors.green, size: 16),
        const SizedBox(width: 8),
        Text(
          text,
          style: const TextStyle(color: Colors.white70, fontSize: 14),
        ),
      ],
    ),
  );
}
