import 'package:flutter/material.dart';

class Navigation {
  static final GlobalKey<NavigatorState> globalKey =
  GlobalKey<NavigatorState>();

  /// Push a new route
  static Future<T?> push<T>(Widget page) {
    return globalKey.currentState!.push(
      MaterialPageRoute(builder: (_) => page),
    );
  }

  /// Push a new route and remove the current one
  static Future<T?> pushReplacement<T, TO>(Widget page, {TO? result}) {
    return globalKey.currentState!.pushReplacement(
      MaterialPageRoute(builder: (_) => page),
      result: result,
    );
  }

  /// Push a new route and remove all previous routes
  static Future<T?> pushAndRemoveUntil<T>(Widget page) {
    return globalKey.currentState!.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => page),
          (Route<dynamic> route) => false,
    );
  }

  /// Pop current route
  static void pop<T extends Object?>([T? result]) {
    if (globalKey.currentState!.canPop()) {
      globalKey.currentState!.pop(result);
    }
  }

  /// Pop until the first route
  static void popUntilFirst() {
    globalKey.currentState!.popUntil((route) => route.isFirst);
  }

  /// Check if can pop
  static bool canPop() {
    return globalKey.currentState!.canPop();
  }
}
