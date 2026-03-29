import 'package:flutter/material.dart';

const kPurple = Color(0xFF8B5CF6);
const kPink = Color(0xFFEC4899);
const kBlue = Color(0xFF3B82F6);
const kGreen = Color(0xFF10B981);
const kYellow = Color(0xFFFBBF24);
const kOrange = Color(0xFFF97316);

final appTheme = ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(seedColor: kPurple, brightness: Brightness.light),
  fontFamily: 'Roboto',
  appBarTheme: const AppBarTheme(
    backgroundColor: kPurple,
    foregroundColor: Colors.white,
    elevation: 0,
    centerTitle: true,
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: kPurple,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
    ),
  ),
  cardTheme: CardThemeData(
    elevation: 3,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 0),
  ),
  inputDecorationTheme: InputDecorationTheme(
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    filled: true,
    fillColor: Colors.grey.shade50,
  ),
);

// Gradient from purple to pink (matches web)
const kGradient = LinearGradient(
  colors: [kPurple, kPink],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

BoxDecoration gradientDecoration({double borderRadius = 20}) => BoxDecoration(
      gradient: kGradient,
      borderRadius: BorderRadius.circular(borderRadius),
      boxShadow: [BoxShadow(color: kPurple.withValues(alpha:0.3), blurRadius: 12, offset: const Offset(0, 4))],
    );
