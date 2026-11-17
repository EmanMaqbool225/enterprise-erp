import 'package:go_router/go_router.dart';
import '../../features/auth/splash_screen.dart';
import '../../features/auth/login_screen.dart';
import '../../features/auth/lock_screen.dart';
import '../../features/dashboard/dashboard_screen.dart';
import '../../features/inventory/rooms_screen.dart';
import '../../features/sales/sales_screen.dart';
import '../../features/sales/pos_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/splash',
  routes: [
    GoRoute(
      path: '/splash',
      name: 'splash',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/login',
      name: 'login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/lock',
      name: 'lock',
      builder: (context, state) => const LockScreen(),
    ),
    GoRoute(
      path: '/dashboard',
      name: 'dashboard',
      builder: (context, state) => const DashboardScreen(),
    ),
    GoRoute(
      path: '/',
      redirect: (context, state) => '/dashboard',
    ),
    GoRoute(
      path: '/rooms',
      name: 'rooms',
      builder: (context, state) => const RoomsScreen(),
    ),
    GoRoute(
      path: '/sales',
      name: 'sales',
      builder: (context, state) => const SalesScreen(),
    ),
    GoRoute(
      path: '/pos',
      name: 'pos',
      builder: (context, state) => const PosScreen(),
    ),
  ],
);