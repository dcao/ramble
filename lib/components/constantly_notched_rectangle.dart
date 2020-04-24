import 'package:flutter/material.dart';

class ConstantlyNotchedRectangle extends CircularNotchedRectangle {
  const ConstantlyNotchedRectangle();

  @override
  Path getOuterPath(Rect host, Rect guest) {
    return super.getOuterPath(
        host,
        Rect.fromCircle(
          radius: guest.width / 2.0,
          center: Offset(guest.center.dx, 0),
        ));
  }
}
