import 'package:animations/animations.dart';
import 'package:flutter/material.dart';

class Themes {
  static final ThemeData light = ThemeData(
    primaryColor: Colors.grey[100],
    accentColor: Colors.grey[700],
    scaffoldBackgroundColor: Colors.grey[200],
    fontFamily: 'Axiforma',
    pageTransitionsTheme: PageTransitionsTheme(builders: {
      TargetPlatform.android: SharedAxisPageTransitionsBuilder(
        transitionType: SharedAxisTransitionType.scaled,
      ),
      TargetPlatform.iOS: SharedAxisPageTransitionsBuilder(
        transitionType: SharedAxisTransitionType.scaled,
      ),
    }),
  );
}
