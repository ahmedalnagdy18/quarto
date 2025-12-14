import 'package:flutter/material.dart';
import 'package:quarto/core/colors/app_colors.dart';

class SessionTypeDialog extends StatefulWidget {
  final String roomName;
  final bool isVip;
  final bool isRoom8;

  const SessionTypeDialog({
    super.key,
    required this.roomName,
    required this.isVip,
    required this.isRoom8,
  });

  @override
  State<SessionTypeDialog> createState() => _SessionTypeDialogState();
}

class _SessionTypeDialogState extends State<SessionTypeDialog> {
  String? _selectedPsType; // "ps4" or "ps5"
  bool? _isMulti; // true for multi, false for normal

  // Calculate price based on room type and selections
  double _calculatePrice() {
    if (_selectedPsType == null || _isMulti == null) return 0.0;

    if (widget.isRoom8) {
      // Room 8 special pricing
      if (_selectedPsType == 'ps4') {
        return _isMulti! ? 100.0 : 60.0;
      } else {
        // ps5
        return _isMulti! ? 130.0 : 90.0;
      }
    } else if (widget.isVip) {
      // VIP rooms pricing
      if (_selectedPsType == 'ps4') {
        return _isMulti! ? 110.0 : 80.0;
      } else {
        // ps5
        return _isMulti! ? 140.0 : 120.0;
      }
    } else {
      // Non-VIP rooms pricing
      if (_selectedPsType == 'ps4') {
        return _isMulti! ? 80.0 : 50.0;
      } else {
        // ps5
        return _isMulti! ? 100.0 : 70.0;
      }
    }
  }

  String _getRoomTypeDescription() {
    if (widget.isRoom8) return "Room 8 (Special Pricing)";
    return widget.isVip ? "VIP Room" : "Standard Room";
  }

  @override
  Widget build(BuildContext context) {
    final price = _calculatePrice();
    final isSelectionComplete = _selectedPsType != null && _isMulti != null;

    return AlertDialog(
      title: Text(
        'Start Session - ${widget.roomName}',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      backgroundColor: AppColors.bgDark,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Room type info
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.bgCardLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    widget.isVip ? Icons.star : Icons.meeting_room,
                    color: widget.isVip ? Colors.amber : Colors.blue,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _getRoomTypeDescription(),
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // PS Type Selection
            Text(
              'Select PlayStation Type:',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: _buildSelectionCard(
                    title: 'PS4',
                    subtitle: 'PlayStation 4',
                    isSelected: _selectedPsType == 'ps4',
                    onTap: () => setState(() => _selectedPsType = 'ps4'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSelectionCard(
                    title: 'PS5',
                    subtitle: 'PlayStation 5',
                    isSelected: _selectedPsType == 'ps5',
                    onTap: () => setState(() => _selectedPsType = 'ps5'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Session Type Selection
            Text(
              'Select Session Type:',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: _buildSelectionCard(
                    title: 'Single',
                    subtitle: 'Normal Session',
                    isSelected: _isMulti == false,
                    onTap: () => setState(() => _isMulti = false),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSelectionCard(
                    title: 'Multi',
                    subtitle: 'Multiplayer Session',
                    isSelected: _isMulti == true,
                    onTap: () => setState(() => _isMulti = true),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Price Preview
            if (isSelectionComplete)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.primaryBlue.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Selected:',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          '${_selectedPsType!.toUpperCase()} - ${_isMulti! ? 'Multi' : 'Single'}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Price per hour:',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          '${price.toStringAsFixed(0)} \$',
                          style: TextStyle(
                            color: AppColors.primaryBlue,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
          ],
        ),
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
            backgroundColor:
                isSelectionComplete ? AppColors.primaryBlue : Colors.grey,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          onPressed:
              isSelectionComplete
                  ? () {
                    Navigator.pop(context, {
                      'psType': _selectedPsType,
                      'isMulti': _isMulti,
                      'hourlyRate': price,
                    });
                  }
                  : null,
          child: const Text(
            'Start Session',
            style: TextStyle(color: Colors.white),
          ),
        ),
      ],
    );
  }

  Widget _buildSelectionCard({
    required String title,
    required String subtitle,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color:
              isSelected
                  ? AppColors.primaryBlue.withOpacity(0.2)
                  : AppColors.bgCardLight,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AppColors.primaryBlue : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Text(
              title,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white70,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
