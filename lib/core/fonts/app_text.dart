import 'package:flutter/material.dart';

class AppTexts {
  AppTexts._();

  // Heading
  static TextStyle largeHeading = TextStyle(
    fontWeight: FontWeight.bold,
    color: Colors.white,
    fontSize: 32,
  );

  static TextStyle meduimHeading = TextStyle(
    color: Colors.white,
    fontWeight: FontWeight.bold,
    fontSize: 24,
  );

  static TextStyle smallHeading = TextStyle(
    color: Colors.white,
    fontWeight: FontWeight.bold,
    fontSize: 16,
  );

  // body

  static TextStyle regularBody = TextStyle(
    fontSize: 16,
    color: Colors.white,
    fontWeight: FontWeight.normal,
  );

  static TextStyle meduimBody = TextStyle(
    fontSize: 14,
    color: Colors.white,
    fontWeight: FontWeight.w500,
  );

  static TextStyle smallBody = TextStyle(
    fontSize: 12,
    color: Colors.white,
  );
}
