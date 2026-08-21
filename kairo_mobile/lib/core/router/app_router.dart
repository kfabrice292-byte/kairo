import 'package:go_router/go_router.dart';
import '../../screens/auth/splash_screen.dart';
import '../../screens/auth/onboarding_screen.dart';
import '../../screens/auth/login_screen.dart';
import '../../screens/auth/register_screen.dart';
import '../../screens/auth/profile_setup_screen.dart';
import '../../screens/main_scaffold.dart';
import '../../screens/notifications_screen.dart';
import '../../screens/search_screen.dart';
import '../../screens/chat/chat_list_screen.dart';
import '../../screens/chat/chat_detail_screen.dart';
import 'package:flutter/material.dart';


CustomTransitionPage _buildFadeTransition(Widget child) {
  return CustomTransitionPage(
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(opacity: animation, child: child);
    },
  );
}

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

final GoRouter appRouter = GoRouter(
  navigatorKey: rootNavigatorKey,
  initialLocation: '/splash',
  redirect: (context, state) {
    return null;
  },
  errorPageBuilder: (context, state) => _buildFadeTransition(const MainScaffold()),
  routes: [
    GoRoute(path: '/splash', pageBuilder: (context, state) => _buildFadeTransition(const SplashScreen())),
    GoRoute(
      path: '/onboarding', pageBuilder: (context, state) => _buildFadeTransition(const OnboardingScreen()),
    ),
    GoRoute(path: '/login', pageBuilder: (context, state) => _buildFadeTransition(const LoginScreen())),
    GoRoute(
      path: '/register', pageBuilder: (context, state) => _buildFadeTransition(const RegisterScreen()),
    ),
    GoRoute(
      path: '/profile-setup', pageBuilder: (context, state) => _buildFadeTransition(const ProfileSetupScreen()),
    ),
    GoRoute(path: '/main', pageBuilder: (context, state) => _buildFadeTransition(const MainScaffold())),
    GoRoute(path: '/search', pageBuilder: (context, state) => _buildFadeTransition(const SearchScreen())),
    GoRoute(
      path: '/notifications', pageBuilder: (context, state) => _buildFadeTransition(const NotificationsScreen()),
    ),
    GoRoute(
      path: '/chat_list', pageBuilder: (context, state) => _buildFadeTransition(const ChatListScreen()),
    ),
    GoRoute(
      path: '/chat_detail',
      pageBuilder: (context, state) {
        final extra = state.extra as Map<String, dynamic>;
        return _buildFadeTransition(
          ChatDetailScreen(
            chatId: extra['chatId'] as String,
            otherUserId: extra['otherUserId'] as String,
            otherUserName: extra['otherUserName'] as String,
            otherUserAvatar: extra['otherUserAvatar'] as String,
          ),
        );
      },
    ),
  ],
);
