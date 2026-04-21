import 'package:flutter/material.dart';

final appTheme = ThemeData(
  colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
  useMaterial3: true,
  appBarTheme: const AppBarTheme(centerTitle: false),
  inputDecorationTheme: const InputDecorationTheme(
    border: OutlineInputBorder(),
  ),
  cardTheme: const CardThemeData(
    margin: EdgeInsets.symmetric(vertical: 6, horizontal: 0),
  ),
);
