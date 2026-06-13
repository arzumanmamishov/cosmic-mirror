import 'package:cosmic_mirror/features/ai_chat/presentation/screens/chat_screen.dart';
import 'package:cosmic_mirror/features/ai_chat/presentation/screens/chat_threads_screen.dart';
import 'package:cosmic_mirror/features/auth/presentation/screens/auth_screen.dart';
import 'package:cosmic_mirror/features/chart/presentation/screens/chart_screen.dart';
import 'package:cosmic_mirror/features/community/presentation/screens/category_detail_screen.dart';
import 'package:cosmic_mirror/features/community/presentation/screens/community_profile_screen.dart';
import 'package:cosmic_mirror/features/community/presentation/screens/create_space_screen.dart';
import 'package:cosmic_mirror/features/community/presentation/screens/edit_space_screen.dart';
import 'package:cosmic_mirror/features/community/presentation/screens/hashtag_feed_screen.dart';
import 'package:cosmic_mirror/features/community/presentation/screens/join_requests_screen.dart';
import 'package:cosmic_mirror/features/community/presentation/screens/members_screen.dart';
import 'package:cosmic_mirror/features/community/presentation/screens/notifications_screen.dart';
import 'package:cosmic_mirror/features/community/presentation/screens/post_detail_screen.dart';
import 'package:cosmic_mirror/features/community/presentation/screens/space_detail_screen.dart';
import 'package:cosmic_mirror/features/community/presentation/screens/spaces_list_screen.dart';
import 'package:cosmic_mirror/features/compatibility/presentation/screens/add_person_screen.dart';
import 'package:cosmic_mirror/features/compatibility/presentation/screens/compatibility_report_screen.dart';
import 'package:cosmic_mirror/features/compatibility/presentation/screens/compatibility_screen.dart';
import 'package:cosmic_mirror/features/daily_reading/presentation/screens/daily_reading_screen.dart';
import 'package:cosmic_mirror/features/destiny_matrix/presentation/screens/destiny_matrix_screen.dart';
import 'package:cosmic_mirror/features/home/presentation/screens/home_screen.dart';
import 'package:cosmic_mirror/features/human_design/presentation/screens/human_design_screen.dart';
import 'package:cosmic_mirror/features/journal/presentation/screens/journal_entry_screen.dart';
import 'package:cosmic_mirror/features/journal/presentation/screens/journal_screen.dart';
import 'package:cosmic_mirror/features/life_timeline/presentation/screens/life_timeline_screen.dart';
import 'package:cosmic_mirror/features/numerology/presentation/screens/numerology_compat_screen.dart';
import 'package:cosmic_mirror/features/numerology/presentation/screens/numerology_name_calculator_screen.dart';
import 'package:cosmic_mirror/features/numerology/presentation/screens/numerology_screen.dart';
import 'package:cosmic_mirror/features/onboarding/presentation/screens/onboarding_flow.dart';
import 'package:cosmic_mirror/features/onboarding/presentation/screens/welcome_screen.dart';
import 'package:cosmic_mirror/features/paywall/presentation/screens/paywall_screen.dart';
import 'package:cosmic_mirror/features/profile/presentation/screens/edit_birth_data_screen.dart';
import 'package:cosmic_mirror/features/profile/presentation/screens/profile_screen.dart';
import 'package:cosmic_mirror/features/psychomatrix/presentation/screens/psychomatrix_screen.dart';
import 'package:cosmic_mirror/features/rituals/presentation/screens/rituals_screen.dart';
import 'package:cosmic_mirror/features/settings/presentation/screens/settings_screen.dart';
import 'package:cosmic_mirror/features/timeline/presentation/screens/timeline_screen.dart';
import 'package:cosmic_mirror/features/vedic_chart/presentation/screens/vedic_chart_screen.dart';
import 'package:cosmic_mirror/features/yearly_forecast/presentation/screens/yearly_forecast_screen.dart';
import 'package:cosmic_mirror/shared/providers/user_provider.dart';
import 'package:cosmic_mirror/shared/widgets/error_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Pulses GoRouter's refreshListenable on Firebase auth changes AND
/// any time our own currentUserProvider state changes — without
/// rebuilding the GoRouter itself. (Watching state directly inside the
/// `appRouterProvider` would recreate the router on every avatar/name
/// update and wipe the navigation stack back to /home.)
class _RouterRefreshNotifier extends ChangeNotifier {
  _RouterRefreshNotifier() {
    FirebaseAuth.instance.authStateChanges().listen((_) => notifyListeners());
  }

  void pulse() => notifyListeners();
}

final _routerRefresh = _RouterRefreshNotifier();

final appRouterProvider = Provider<GoRouter>((ref) {
  // Listen (don't watch) so user-state mutations re-fire the redirect
  // without recreating the router. The redirect callback below reads
  // the latest state via ref.read at each evaluation.
  ref.listen<UserState>(currentUserProvider, (_, __) => _routerRefresh.pulse());

  return GoRouter(
    initialLocation: '/',
    debugLogDiagnostics: true,
    refreshListenable: _routerRefresh,
    // Fallback for unknown routes + any router-level error (e.g. a
    // GoException thrown by a misconfigured deep link). Shows the
    // friendly cosmic ErrorPage with a "Go home" button.
    errorBuilder: (context, state) => ErrorPage(error: state.error),
    redirect: (context, state) {
      final userState = ref.read(currentUserProvider);
      final isAuthenticated =
          FirebaseAuth.instance.currentUser != null;
      final isOnAuthRoute = state.matchedLocation == '/auth';
      final isOnOnboarding = state.matchedLocation == '/onboarding';
      // /welcome is the post-onboarding celebratory screen — treat it as
      // part of onboarding so users freshly arriving there aren't bounced
      // back to /onboarding while their hasCompletedOnboarding flag
      // hasn't refreshed yet.
      final isOnWelcome = state.matchedLocation == '/welcome';

      // Treat the user as "session bootstrapped" once an id has been
      // populated by bootstrapSession(). On hot reload Firebase reports
      // authenticated immediately, but the backend session call hasn't
      // returned yet — without this guard we'd flash /onboarding for ~1s
      // before the real `hasCompletedOnboarding` flag arrives.
      final sessionReady = userState.id != null;

      if (!isAuthenticated && !isOnAuthRoute) return '/auth';
      if (isAuthenticated && isOnAuthRoute) {
        if (!sessionReady) return null; // wait for bootstrap to know where to go
        return userState.hasCompletedOnboarding ? '/home' : '/onboarding';
      }
      if (isAuthenticated &&
          sessionReady &&
          !userState.hasCompletedOnboarding &&
          !isOnOnboarding &&
          !isOnWelcome &&
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
        path: '/welcome',
        pageBuilder: (context, state) => _fadeTransition(
          state,
          const WelcomeScreen(),
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
          // /chat/new — fresh chat with no thread id. The thread is
          // only created on the backend after the user sends their
          // first message, so empty conversations never pollute the
          // threads list.
          GoRoute(
            path: 'new',
            pageBuilder: (context, state) => _slideTransition(
              state,
              const ChatScreen(),
            ),
          ),
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
        path: '/numerology',
        pageBuilder: (context, state) => _slideTransition(
          state,
          const NumerologyScreen(),
        ),
        routes: [
          GoRoute(
            path: 'compatibility',
            pageBuilder: (context, state) => _slideTransition(
              state,
              const NumerologyCompatScreen(),
            ),
          ),
          GoRoute(
            path: 'name-calculator',
            pageBuilder: (context, state) => _slideTransition(
              state,
              const NumerologyNameCalculatorScreen(),
            ),
          ),
        ],
      ),
      GoRoute(
        path: '/psychomatrix',
        pageBuilder: (context, state) => _slideTransition(
          state,
          const PsychomatrixScreen(),
        ),
      ),
      GoRoute(
        path: '/destiny-matrix',
        pageBuilder: (context, state) => _slideTransition(
          state,
          const DestinyMatrixScreen(),
        ),
      ),
      GoRoute(
        path: '/human-design',
        pageBuilder: (context, state) => _slideTransition(
          state,
          const HumanDesignScreen(),
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
            // user/:userId — accepts either a UUID or the literal "me".
            path: 'user/:userId',
            pageBuilder: (context, state) => _slideTransition(
              state,
              CommunityProfileScreen(
                userIdOrMe: state.pathParameters['userId']!,
              ),
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
              // Owner-only join-request inbox. Backend returns 403 to
              // non-owners; the screen renders the ErrorView in that case.
              GoRoute(
                path: 'requests',
                pageBuilder: (context, state) => _slideTransition(
                  state,
                  JoinRequestsScreen(
                    spaceId: state.pathParameters['spaceId']!,
                  ),
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
        routes: [
          GoRoute(
            path: 'edit-birth-data',
            pageBuilder: (context, state) => _slideTransition(
              state,
              const EditBirthDataScreen(),
            ),
          ),
        ],
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
        ),),
        child: child,
      );
    },
  );
}
