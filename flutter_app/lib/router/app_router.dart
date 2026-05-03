import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/ai_chat/presentation/screens/chat_screen.dart';
import '../features/ai_chat/presentation/screens/chat_threads_screen.dart';
import '../features/auth/presentation/screens/auth_screen.dart';
import '../features/chart/presentation/screens/chart_screen.dart';
import '../features/compatibility/presentation/screens/add_person_screen.dart';
import '../features/compatibility/presentation/screens/compatibility_report_screen.dart';
import '../features/compatibility/presentation/screens/compatibility_screen.dart';
import '../features/daily_reading/presentation/screens/daily_reading_screen.dart';
import '../features/home/presentation/screens/home_screen.dart';
import '../features/journal/presentation/screens/journal_entry_screen.dart';
import '../features/journal/presentation/screens/journal_screen.dart';
import '../features/onboarding/presentation/screens/onboarding_flow.dart';
import '../features/paywall/presentation/screens/paywall_screen.dart';
import '../features/profile/presentation/screens/profile_screen.dart';
import '../features/rituals/presentation/screens/rituals_screen.dart';
import '../features/settings/presentation/screens/settings_screen.dart';
import '../features/life_timeline/presentation/screens/life_timeline_screen.dart';
import '../features/community/presentation/screens/category_detail_screen.dart';
import '../features/community/presentation/screens/create_space_screen.dart';
import '../features/community/presentation/screens/edit_space_screen.dart';
import '../features/community/presentation/screens/hashtag_feed_screen.dart';
import '../features/community/presentation/screens/members_screen.dart';
import '../features/community/presentation/screens/notifications_screen.dart';
import '../features/community/presentation/screens/post_detail_screen.dart';
import '../features/community/presentation/screens/space_detail_screen.dart';
import '../features/community/presentation/screens/spaces_list_screen.dart';
import '../features/timeline/presentation/screens/timeline_screen.dart';
import '../features/vedic_chart/presentation/screens/vedic_chart_screen.dart';
import '../features/yearly_forecast/presentation/screens/yearly_forecast_screen.dart';
import '../shared/providers/user_provider.dart';

/// Notifies GoRouter when Firebase auth state changes.
class _AuthChangeNotifier extends ChangeNotifier {
  _AuthChangeNotifier() {
    FirebaseAuth.instance.authStateChanges().listen((_) => notifyListeners());
  }
}

final _authChangeNotifier = _AuthChangeNotifier();

final appRouterProvider = Provider<GoRouter>((ref) {
  final userState = ref.watch(currentUserProvider);

  return GoRouter(
    initialLocation: '/',
    debugLogDiagnostics: true,
    refreshListenable: _authChangeNotifier,
    redirect: (context, state) {
      final isAuthenticated =
          FirebaseAuth.instance.currentUser != null;
      final isOnAuthRoute = state.matchedLocation == '/auth';
      final isOnOnboarding = state.matchedLocation == '/onboarding';

      if (!isAuthenticated && !isOnAuthRoute) return '/auth';
      if (isAuthenticated && isOnAuthRoute) {
        return userState.hasCompletedOnboarding ? '/home' : '/onboarding';
      }
      if (isAuthenticated &&
          !userState.hasCompletedOnboarding &&
          !isOnOnboarding &&
          state.matchedLocation != '/auth') {
        return '/onboarding';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        redirect: (_, __) => '/home',
      ),
      GoRoute(
        path: '/auth',
        pageBuilder: (context, state) => _fadeTransition(
          state,
          const AuthScreen(),
        ),
      ),
      GoRoute(
        path: '/onboarding',
        pageBuilder: (context, state) => _fadeTransition(
          state,
          const OnboardingFlow(),
        ),
      ),
      GoRoute(
        path: '/paywall',
        pageBuilder: (context, state) => _slideTransition(
          state,
          const PaywallScreen(),
        ),
      ),
      GoRoute(
        path: '/home',
        pageBuilder: (context, state) => _fadeTransition(
          state,
          const HomeScreen(),
        ),
      ),
      GoRoute(
        path: '/daily-reading',
        pageBuilder: (context, state) => _slideTransition(
          state,
          const DailyReadingScreen(),
        ),
      ),
      GoRoute(
        path: '/chat',
        pageBuilder: (context, state) => _slideTransition(
          state,
          const ChatThreadsScreen(),
        ),
        routes: [
          GoRoute(
            path: ':threadId',
            pageBuilder: (context, state) {
              final threadId = state.pathParameters['threadId']!;
              return _slideTransition(
                state,
                ChatScreen(threadId: threadId),
              );
            },
          ),
        ],
      ),
      GoRoute(
        path: '/chart',
        pageBuilder: (context, state) => _slideTransition(
          state,
          const ChartScreen(),
        ),
      ),
      GoRoute(
        path: '/vedic-chart',
        pageBuilder: (context, state) => _slideTransition(
          state,
          const VedicChartScreen(),
        ),
      ),
      GoRoute(
        path: '/community',
        pageBuilder: (context, state) => _slideTransition(
          state,
          const SpacesListScreen(),
        ),
        routes: [
          GoRoute(
            path: 'create',
            pageBuilder: (context, state) => _slideTransition(
              state,
              const CreateSpaceScreen(),
            ),
          ),
          GoRoute(
            path: 'notifications',
            pageBuilder: (context, state) => _slideTransition(
              state,
              const NotificationsScreen(),
            ),
          ),
          GoRoute(
            path: 'category/:categoryId',
            pageBuilder: (context, state) => _slideTransition(
              state,
              CategoryDetailScreen(
                categoryId: state.pathParameters['categoryId']!,
              ),
            ),
          ),
          GoRoute(
            path: 'hashtag/:tag',
            pageBuilder: (context, state) => _slideTransition(
              state,
              HashtagFeedScreen(tag: state.pathParameters['tag']!),
            ),
          ),
          GoRoute(
            path: 'post/:postId',
            pageBuilder: (context, state) => _slideTransition(
              state,
              PostDetailScreen(
                spaceId: '',
                postId: state.pathParameters['postId']!,
              ),
            ),
          ),
          GoRoute(
            path: ':spaceId',
            pageBuilder: (context, state) => _slideTransition(
              state,
              SpaceDetailScreen(spaceId: state.pathParameters['spaceId']!),
            ),
            routes: [
              GoRoute(
                path: 'edit',
                pageBuilder: (context, state) => _slideTransition(
                  state,
                  EditSpaceScreen(spaceId: state.pathParameters['spaceId']!),
                ),
              ),
              GoRoute(
                path: 'members',
                pageBuilder: (context, state) => _slideTransition(
                  state,
                  MembersScreen(spaceId: state.pathParameters['spaceId']!),
                ),
              ),
              GoRoute(
                path: 'post/:postId',
                pageBuilder: (context, state) => _slideTransition(
                  state,
                  PostDetailScreen(
                    spaceId: state.pathParameters['spaceId']!,
                    postId: state.pathParameters['postId']!,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/compatibility',
        pageBuilder: (context, state) => _slideTransition(
          state,
          const CompatibilityScreen(),
        ),
        routes: [
          GoRoute(
            path: 'add',
            pageBuilder: (context, state) => _slideTransition(
              state,
              const AddPersonScreen(),
            ),
          ),
          GoRoute(
            path: ':personId',
            pageBuilder: (context, state) {
              final personId = state.pathParameters['personId']!;
              return _slideTransition(
                state,
                CompatibilityReportScreen(personId: personId),
              );
            },
          ),
        ],
      ),
      GoRoute(
        path: '/timeline',
        pageBuilder: (context, state) => _slideTransition(
          state,
          const TimelineScreen(),
        ),
      ),
      GoRoute(
        path: '/life-timeline',
        pageBuilder: (context, state) => _slideTransition(
          state,
          const LifeTimelineScreen(),
        ),
      ),
      GoRoute(
        path: '/yearly-forecast',
        pageBuilder: (context, state) => _slideTransition(
          state,
          const YearlyForecastScreen(),
        ),
      ),
      GoRoute(
        path: '/rituals',
        pageBuilder: (context, state) => _slideTransition(
          state,
          const RitualsScreen(),
        ),
      ),
      GoRoute(
        path: '/journal',
        pageBuilder: (context, state) => _slideTransition(
          state,
          const JournalScreen(),
        ),
        routes: [
          GoRoute(
            path: 'new',
            pageBuilder: (context, state) => _slideTransition(
              state,
              const JournalEntryScreen(),
            ),
          ),
          GoRoute(
            path: ':entryId',
            pageBuilder: (context, state) {
              final entryId = state.pathParameters['entryId']!;
              return _slideTransition(
                state,
                JournalEntryScreen(entryId: entryId),
              );
            },
          ),
        ],
      ),
      GoRoute(
        path: '/profile',
        pageBuilder: (context, state) => _slideTransition(
          state,
          const ProfileScreen(),
        ),
      ),
      GoRoute(
        path: '/settings',
        pageBuilder: (context, state) => _slideTransition(
          state,
          const SettingsScreen(),
        ),
      ),
    ],
  );
});

CustomTransitionPage<void> _fadeTransition(
  GoRouterState state,
  Widget child,
) {
  return CustomTransitionPage(
    key: state.pageKey,
    child: child,
    transitionsBuilder: (_, animation, __, child) {
      return FadeTransition(opacity: animation, child: child);
    },
  );
}

CustomTransitionPage<void> _slideTransition(
  GoRouterState state,
  Widget child,
) {
  return CustomTransitionPage(
    key: state.pageKey,
    child: child,
    transitionsBuilder: (_, animation, __, child) {
      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(1, 0),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        )),
        child: child,
      );
    },
  );
}
