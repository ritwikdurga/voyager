import 'package:flutter/material.dart';

// these are all test colors and i have to change it later
const lightColorScheme = ColorScheme.light(
  brightness: Brightness.light,
  primary: Color(0xFF1ED760),
  onPrimary: Color(0xFF000000),
  primaryContainer: Colors.blueAccent,
  secondary: Color(0xFFFFFFFF),
  onSecondary: Color(0xFF000000),
  surface: Color(0xFFFFFFFF),
  onSurface: Color(0xFF000000),
  background: Color(0xFFFFFFFF),
  onBackground: Color(0xFF000000),
  error: Color(0xFFD32F2F),
  onError: Color(0xFF000000),
  secondaryContainer: Color(0xFFD32F2F),
);

const darkColorScheme = ColorScheme.dark(
  primary: Color(0xFF4CAF50),
  secondary: Color(0xFFff5722),
  surface: Color(0xFF121212),
  background: Colors.black,
  error: Color(0xFFcf6679),
  onPrimary: Color(0xFF000000),
  onSecondary: Color(0xFF000000),
  onSurface: Color(0xFFffffff),
  onBackground: Color(0xFFffffff),
  onError: Color(0xFF000000),
);
