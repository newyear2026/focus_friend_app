import 'package:flutter/material.dart';

const deskPaper = Color(0xFF292630);
const deskInk = Color(0xFFFFEBC5);
const deskInkShadow = Color(0xFF171B32);
const deskCream = Color(0xFF403943);
const deskBlue = Color(0xFFE5CAB0);
const deskGreen = Color(0xFFFFC16F);
const deskMuted = Color(0xFFC5B8BA);
const deskAccent = Color(0xFFFFC16F);
const deskDivider = Color(0xFF554A54);

ThemeData deskTheme(BuildContext context) => buildDeskTheme(Theme.of(context));

ThemeData buildDeskTheme(ThemeData base) => base.copyWith(
  scaffoldBackgroundColor: deskPaper,
  brightness: Brightness.dark,
  appBarTheme: const AppBarTheme(
    backgroundColor: deskPaper,
    foregroundColor: deskInk,
    surfaceTintColor: Colors.transparent,
  ),
  dividerTheme: const DividerThemeData(color: deskDivider),
  dialogTheme: const DialogThemeData(backgroundColor: deskPaper),
  textTheme: base.textTheme
      .copyWith(bodyMedium: base.textTheme.bodyMedium?.copyWith(height: 1.25))
      .apply(
        fontFamily: 'Pretendard',
        bodyColor: deskInk,
        displayColor: deskInk,
      ),
  iconTheme: const IconThemeData(color: deskInk),
  colorScheme: ColorScheme.fromSeed(
    brightness: Brightness.dark,
    seedColor: deskAccent,
    primary: deskAccent,
    onPrimary: deskInkShadow,
    surface: deskPaper,
    onSurface: deskInk,
  ),
);
