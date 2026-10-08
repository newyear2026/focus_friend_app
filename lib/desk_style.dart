import 'package:flutter/material.dart';

const deskPaper = Color(0xFFFFFEFA);
const deskInk = Color(0xFF07143C);
const deskBlue = Color(0xFF4752CE);
const deskGreen = Color(0xFF3D956D);
const deskMuted = Color(0xFF7B80B7);

ThemeData deskTheme(BuildContext context) => Theme.of(context).copyWith(
  scaffoldBackgroundColor: deskPaper,
  textTheme: Theme.of(context).textTheme
      .copyWith(
        bodyMedium: Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(height: 1.25),
      )
      .apply(
        fontFamily: 'Pretendard',
        bodyColor: deskInk,
        displayColor: deskInk,
      ),
  iconTheme: const IconThemeData(color: deskInk),
  colorScheme: ColorScheme.fromSeed(
    seedColor: deskGreen,
    primary: deskGreen,
    surface: deskPaper,
    onSurface: deskInk,
  ),
);
