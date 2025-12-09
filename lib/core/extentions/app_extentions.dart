// Prevent spaces at the start of the text
import 'package:flutter/services.dart';

class PreventStartingSpaceInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    String newText = newValue.text;

    // Prevent starting with a space by trimming only the beginning
    if (newText.startsWith(' ')) {
      newText = newText.trimLeft();
    }

    // Replace multiple spaces with a single space throughout the text.
    newText = newText.replaceAll(RegExp(r'\s{2,}'), ' ');
    return TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
  }
}

TextInputFormatter noSpaceFormatter() {
  return TextInputFormatter.withFunction(
    (oldValue, newValue) {
      if (newValue.text.startsWith(' ')) {
        final newText = newValue.text.trimLeft();
        return newValue.copyWith(
          text: newText,
          selection: TextSelection.fromPosition(
            TextPosition(offset: newText.length),
          ),
        );
      }
      return newValue;
    },
  );
} //  noSpaceFormatter(),   to call it
