import 'package:flutter/material.dart';

class NavigationService {
  NavigationService._();

  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  static NavigatorState? get state => navigatorKey.currentState;

  static BuildContext? get context => navigatorKey.currentContext;

  static Future<T?>? pushNamed<T>(String routeName, {Object? arguments}) {
    return state?.pushNamed<T>(routeName, arguments: arguments);
  }

  static Future<T?>? pushReplacementNamed<T, TO>(String routeName, {Object? arguments, TO? result}) {
    return state?.pushReplacementNamed<T, TO>(routeName, arguments: arguments, result: result);
  }

  static Future<T?>? pushNamedAndRemoveUntil<T>(
    String newRouteName, {
    Object? arguments,
  }) {
    return state?.pushNamedAndRemoveUntil<T>(
      newRouteName,
      (route) => false,
      arguments: arguments,
    );
  }

  static void pop<T>([T? result]) {
    state?.pop<T>(result);
  }
}
