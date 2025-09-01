import 'package:flutter/material.dart';

extension ScreenSize on BuildContext {
  get height => MediaQuery.of(this).size.height;

  get width => MediaQuery.of(this).size.width;
}
