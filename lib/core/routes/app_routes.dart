import 'package:flutter/material.dart';
import '../../features/auth/presentation/screens/auth_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/setup_flow/presentation/screens/setup_flow_screen.dart';
import '../../features/splash/presentation/screens/splash_screen.dart';
import '../../features/notifications/presentation/screens/notifications_screen.dart';
import '../../features/cycle/presentation/screens/cycle_screen.dart';
import 'route_names.dart';

class AppRoutes {
  AppRoutes._();

  static Map<String, WidgetBuilder> get routes {
    return {
      RouteNames.splash: (context) => const SplashScreen(),
      RouteNames.auth: (context) => const AuthScreen(),
      RouteNames.setupFlow: (context) => const SetupFlowScreen(),
      RouteNames.home: (context) => const HomeScreen(),
      RouteNames.cycle: (context) => const CycleScreen(),
      RouteNames.workout: (context) => const SizedBox.shrink(),      // TODO: Bind Workout screen
      RouteNames.progress: (context) => const SizedBox.shrink(),     // TODO: Bind Progress screen
      RouteNames.profile: (context) => const SizedBox.shrink(),      // TODO: Bind Profile screen
      RouteNames.notifications: (context) => const NotificationsScreen(),
    };
  }

  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    final builder = routes[settings.name];
    if (builder != null) {
      return MaterialPageRoute(
        builder: builder,
        settings: settings,
      );
    }
    return MaterialPageRoute(
      builder: (context) => Scaffold(
        body: Center(
          child: Text('No route defined for ${settings.name}'),
        ),
      ),
    );
  }
}
