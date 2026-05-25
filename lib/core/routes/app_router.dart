import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/dashboard/screens/dashboard_screen.dart';
import '../../features/reservation/screens/room_list_screen.dart';
import '../../features/reservation/screens/add_reservation_screen.dart';
import '../../features/reservation/screens/reservation_history_screen.dart';
import '../../features/motor/screens/motorcycle_list_screen.dart';
import '../../features/motor/screens/add_rental_screen.dart';
import '../../features/motor/screens/rental_history_screen.dart';
import '../../features/laundry/screens/laundry_list_screen.dart';
import '../../features/room_service/screens/room_service_screen.dart';
import '../../features/drinks/screens/drinks_screen.dart';
import '../../features/finance/screens/finance_report_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);
  final authNotifierState = ref.watch(authNotifierProvider);

  return GoRouter(
    initialLocation: '/login',
    redirect: (context, state) {
      final isLoggedIn = authState.value != null || 
          (authNotifierState.value != null);
      final isLoginPage = state.matchedLocation == '/login';

      if (!isLoggedIn && !isLoginPage) return '/login';
      if (isLoggedIn && isLoginPage) return '/dashboard';
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/dashboard',
        name: 'dashboard',
        builder: (context, state) => const DashboardScreen(),
      ),
      // Reservation
      GoRoute(
        path: '/rooms',
        name: 'rooms',
        builder: (context, state) => const RoomListScreen(),
      ),
      GoRoute(
        path: '/reservations/add',
        name: 'add-reservation',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return AddReservationScreen(roomId: extra?['roomId'], roomNumber: extra?['roomNumber']);
        },
      ),
      GoRoute(
        path: '/reservations/history',
        name: 'reservation-history',
        builder: (context, state) => const ReservationHistoryScreen(),
      ),
      // Motor
      GoRoute(
        path: '/motorcycles',
        name: 'motorcycles',
        builder: (context, state) => const MotorcycleListScreen(),
      ),
      GoRoute(
        path: '/motor-rentals/add',
        name: 'add-rental',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return AddRentalScreen(motorcycleId: extra?['motorcycleId'], plateNumber: extra?['plateNumber']);
        },
      ),
      GoRoute(
        path: '/motor-rentals/history',
        name: 'rental-history',
        builder: (context, state) => const RentalHistoryScreen(),
      ),
      // Laundry
      GoRoute(
        path: '/laundry',
        name: 'laundry',
        builder: (context, state) => const LaundryListScreen(),
      ),
      GoRoute(
        path: '/laundry/add',
        name: 'add-laundry',
        builder: (context, state) => const AddLaundryScreen(),
      ),
      // Room Service
      GoRoute(
        path: '/room-service',
        name: 'room-service',
        builder: (context, state) => const RoomServiceScreen(),
      ),
      GoRoute(
        path: '/room-service/add',
        name: 'add-schedule',
        builder: (context, state) => const AddScheduleScreen(),
      ),
      // Drinks
      GoRoute(
        path: '/drinks',
        name: 'drinks',
        builder: (context, state) => const DrinksScreen(),
      ),
      GoRoute(
        path: '/drinks/add',
        name: 'add-drink',
        builder: (context, state) => const AddDrinkScreen(),
      ),
      GoRoute(
        path: '/drinks/transaction',
        name: 'drink-transaction',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return DrinkTransactionScreen(drinkId: extra?['drinkId'], drinkName: extra?['drinkName']);
        },
      ),
      // Finance
      GoRoute(
        path: '/finance',
        name: 'finance',
        builder: (context, state) => const FinanceReportScreen(),
      ),
    ],
  );
});
