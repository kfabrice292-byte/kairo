import 'package:go_router/go_router.dart';
import '../../screens/auth/splash_screen.dart';
import '../../screens/auth/onboarding_screen.dart';
import '../../screens/auth/login_screen.dart';
import '../../screens/auth/register_screen.dart';
import '../../screens/main_scaffold.dart';
import '../../screens/notifications_screen.dart';
import '../../screens/search_screen.dart';
import '../../screens/chat/chat_list_screen.dart';
import '../../screens/chat/chat_detail_screen.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/splash',
  routes: [
    GoRoute(
      path: '/splash',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => const OnboardingScreen(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/register',
      builder: (context, state) => const RegisterScreen(),
    ),
    GoRoute(
      path: '/main',
      builder: (context, state) => const MainScaffold(),
    ),
    GoRoute(
      path: '/search',
      builder: (context, state) => const SearchScreen(),
    ),
    GoRoute(
      path: '/notifications',
      builder: (context, state) => const NotificationsScreen(),
    ),
    GoRoute(
      path: '/chat_list',
      builder: (context, state) => const ChatListScreen(),
    ),
    GoRoute(
      path: '/chat_detail',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>;
        return ChatDetailScreen(
          chatId: extra['chatId'] as String,
          otherUserId: extra['otherUserId'] as String,
          otherUserName: extra['otherUserName'] as String,
          otherUserAvatar: extra['otherUserAvatar'] as String,
        );
      },
    ),
  ],
);
