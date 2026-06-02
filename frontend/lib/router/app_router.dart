import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/providers/auth_controller.dart';
import 'package:frontend/models/auth_models.dart';
import 'package:frontend/screens/auth_screen.dart';
import 'package:frontend/screens/splash_screen.dart';
import 'package:frontend/screens/onboarding_screen.dart';
import 'package:frontend/screens/dashboard_screen.dart';
import 'package:frontend/screens/create_pool_screen.dart';
import 'package:frontend/screens/edit_pool_screen.dart';
import 'package:frontend/screens/join_pool_screen.dart';
import 'package:frontend/screens/pool_details_screen.dart';
import 'package:frontend/screens/members_screen.dart';
import 'package:frontend/screens/approve_join_screen.dart';
import 'package:frontend/screens/approve_payment_screen.dart';
import 'package:frontend/screens/money_in_screen.dart';
import 'package:frontend/screens/money_out_screen.dart';
import 'package:frontend/screens/log_expense_screen.dart';
import 'package:frontend/screens/log_collection_screen.dart';
import 'package:frontend/screens/wip_screen.dart';
import 'package:frontend/screens/payment_submission_screen.dart';
import 'package:frontend/models/pool_model.dart';
import 'package:frontend/screens/activity_screen.dart';
import 'package:frontend/screens/profile_screen.dart';
import 'package:frontend/widgets/main_shell.dart';

final routerProvider = Provider<GoRouter>((ref) {
  // Use a ValueNotifier so GoRouter can refresh its redirect logic
  // without being fully recreated on every auth state change.
  final authNotifier = ValueNotifier<AuthState>(ref.read(authControllerProvider));

  ref.listen<AuthState>(authControllerProvider, (_, next) {
    authNotifier.value = next;
  });

  ref.onDispose(() => authNotifier.dispose());

  return GoRouter(
    initialLocation: '/',
    refreshListenable: authNotifier,
    redirect: (context, state) {
      final authState = authNotifier.value;
      final isSplash = state.matchedLocation == '/';
      final isAuth = state.matchedLocation == '/auth';

      switch (authState.status) {
        case AuthStatus.initial:
          return isSplash ? null : '/';
        case AuthStatus.loading:
          return null;
        case AuthStatus.unauthenticated:
          return isAuth ? null : '/auth';
        case AuthStatus.onboarding:
          return state.matchedLocation == '/onboarding' ? null : '/onboarding';
        case AuthStatus.authenticated:
          if (isSplash || isAuth || state.matchedLocation == '/onboarding') {
            return '/dashboard';
          }
          return null;
      }
    },
    routes: [
      GoRoute(path: '/', builder: (context, state) => const SplashScreen()),
      GoRoute(
        path: '/onboarding',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const OnboardingScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      ),
      GoRoute(
        path: '/auth',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const AuthScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      ),
      GoRoute(
        path: '/create-pool',
        builder: (context, state) => const CreatePoolScreen(),
      ),
      GoRoute(
        path: '/edit-pool',
        builder: (context, state) {
          final pool = state.extra;
          if (pool is! Pool) {
            return const DashboardScreen();
          }
          return EditPoolScreen(pool: pool);
        },
      ),
      GoRoute(
        path: '/join-pool',
        builder: (context, state) => const JoinPoolScreen(),
      ),
      GoRoute(
        path: '/pool-details',
        builder: (context, state) {
          final pool = state.extra;
          if (pool is! Pool) {
            // Safely redirect to dashboard if pool data is missing
            return const DashboardScreen();
          }
          return PoolDetailsScreen(initialPool: pool);
        },
      ),
      GoRoute(
        path: '/pool-members',
        builder: (context, state) {
          final pool = state.extra;
          if (pool is! Pool) {
            return const DashboardScreen();
          }
          return PoolMembersScreen(pool: pool);
        },
      ),
      GoRoute(
        path: '/approve-join',
        builder: (context, state) {
          final pool = state.extra;
          if (pool is! Pool) {
            return const DashboardScreen();
          }
          return ApproveJoinScreen(pool: pool);
        },
      ),
      GoRoute(
        path: '/approve-payment',
        builder: (context, state) {
          final pool = state.extra;
          if (pool is! Pool) {
            return const DashboardScreen();
          }
          return ApprovePaymentScreen(pool: pool);
        },
      ),
      GoRoute(
        path: '/money-in',
        builder: (context, state) {
          final pool = state.extra;
          if (pool is! Pool) {
            return const DashboardScreen();
          }
          return MoneyInScreen(pool: pool);
        },
      ),
      GoRoute(
        path: '/money-out',
        builder: (context, state) {
          final pool = state.extra;
          if (pool is! Pool) {
            return const DashboardScreen();
          }
          return MoneyOutScreen(pool: pool);
        },
      ),
      GoRoute(
        path: '/log-expense',
        builder: (context, state) {
          final pool = state.extra;
          if (pool is! Pool) {
            return const DashboardScreen();
          }
          return LogExpenseScreen(pool: pool);
        },
      ),
      GoRoute(
        path: '/log-collection',
        builder: (context, state) {
          final pool = state.extra;
          if (pool is! Pool) {
            return const DashboardScreen();
          }
          return LogCollectionScreen(pool: pool);
        },
      ),
      GoRoute(
        path: '/wip',
        builder: (context, state) {
          final title = state.extra as String? ?? 'Work in Progress';
          return WipScreen(title: title);
        },
      ),
      GoRoute(
        path: '/payment-submission',
        builder: (context, state) {
          final extra = state.extra;
          if (extra is! Map<String, dynamic>) {
            return const DashboardScreen();
          }
          final pool = extra['pool'];
          final amountDue = extra['amountDue'];
          if (pool is! Pool || amountDue is! double) {
            return const DashboardScreen();
          }
          return PaymentSubmissionScreen(pool: pool, amountDue: amountDue);
        },
      ),
      ShellRoute(
        builder: (context, state, child) {
          return MainShell(child: child);
        },
        routes: [
          GoRoute(
            path: '/dashboard',
            pageBuilder: (context, state) => CustomTransitionPage(
              key: state.pageKey,
              child: const DashboardScreen(),
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) {
                    return FadeTransition(opacity: animation, child: child);
                  },
            ),
          ),
          GoRoute(
            path: '/activity',
            pageBuilder: (context, state) => CustomTransitionPage(
              key: state.pageKey,
              child: const ActivityScreen(),
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) {
                    return FadeTransition(opacity: animation, child: child);
                  },
            ),
          ),
          GoRoute(
            path: '/profile',
            pageBuilder: (context, state) => CustomTransitionPage(
              key: state.pageKey,
              child: const ProfileScreen(),
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) {
                    return FadeTransition(opacity: animation, child: child);
                  },
            ),
          ),
        ],
      ),
    ],
  );
});

