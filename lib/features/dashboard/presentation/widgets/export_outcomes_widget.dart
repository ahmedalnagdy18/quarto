import 'package:flutter/material.dart';
import 'package:quarto/core/colors/app_colors.dart';
import 'package:quarto/core/services/outcomes_export_service.dart';

class ExportOutcomesButton extends StatelessWidget {
  final List<dynamic> outcomes;

  const ExportOutcomesButton({
    super.key,
    required this.outcomes,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      icon: const Icon(Icons.download),
      label: const Text("Export Outcomes"),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      ),
      onPressed: () async {
        await OutcomesExportService.exportOutcomes(context, outcomes);
      },
    );
  }
}
