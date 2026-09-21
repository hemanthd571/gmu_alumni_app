import 'dart:io';
import 'package:go_router/go_router.dart';
import '../screens/feedback_selection_screen.dart';
import '../screens/feedback_event_list_screen.dart';
import '../screens/splash_screen.dart';
import '../screens/login_screen.dart';
import '../screens/register_screen.dart';
import '../screens/home_screen.dart';
import '../screens/core_team_screen.dart';
import '../screens/noticeboard_screen.dart';
import '../screens/news_screen.dart';
import '../screens/galleries_screen.dart';
import '../screens/events_screen.dart';
import '../screens/jobs_screen.dart';
import '../screens/proud_alumni_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/posts_screen.dart';
import '../screens/create_post_screen.dart';
import '../screens/conversations_screen.dart';
import '../screens/chat_screen.dart';
import '../screens/create_job_screen.dart';
import '../screens/edit_profile_screen.dart';
import '../screens/edit_password_screen.dart';
import '../screens/announcements_screen.dart';
import '../screens/user_discovery_screen.dart';
import '../screens/alumni_map_screen.dart';
import '../screens/director/director_dashboard.dart';
import '../screens/director/director_alumni_directory_screen.dart';
import '../screens/director/director_spocs_screen.dart';
import '../screens/director/approve_posts_screen.dart';
import '../screens/director/director_noticeboard_screen.dart';
import '../screens/director/director_news_screen.dart';
import '../screens/director/director_feedback_screen.dart';
import '../screens/spoc_dashboard.dart';
import '../screens/single_post_screen.dart';
import '../screens/feedback_screen.dart';
import '../screens/audio_recording_screen.dart';

import '../screens/director/events_management_screen.dart';
import '../screens/director/create_event_screen.dart';
import '../screens/director/event_details_screen.dart';
import '../screens/scan_event_qr_screen.dart';
import '../models/event_model.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const SplashScreen(),
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
        path: '/director-dashboard',
        builder: (context, state) => const DirectorDashboard(),
      ),
      GoRoute(
        path: '/director-alumni-directory',
        builder: (context, state) => const DirectorAlumniDirectoryScreen(),
      ),
      GoRoute(
        path: '/director-spocs',
        builder: (context, state) => const DirectorSpocsScreen(),
      ),
      GoRoute(
        path: '/director-approve-posts',
        builder: (context, state) => const ApprovePostsScreen(),
      ),
      GoRoute(
        path: '/director-noticeboard',
        builder: (context, state) => const DirectorNoticeboardScreen(),
      ),
      GoRoute(
        path: '/director-news',
        builder: (context, state) => const DirectorNewsScreen(),
      ),
      GoRoute(
        path: '/director-feedback',
        builder: (context, state) => const DirectorFeedbackScreen(),
      ),
      GoRoute(
        path: '/director-events',
        builder: (context, state) => const EventsManagementScreen(),
      ),
      GoRoute(
        path: '/director-create-event',
        builder: (context, state) => const CreateEventScreen(),
      ),
      GoRoute(
        path: '/director-event-details',
        builder: (context, state) {
          final extra = state.extra as EventModel;
          return EventDetailsScreen(event: extra);
        },
      ),
      GoRoute(
        path: '/spoc-dashboard',
        builder: (context, state) => const SpocDashboardScreen(),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/core-team',
        builder: (context, state) => const CoreTeamScreen(),
      ),
      GoRoute(
        path: '/noticeboard',
        builder: (context, state) => const NoticeboardScreen(),
      ),
      GoRoute(
        path: '/news',
        builder: (context, state) => const NewsScreen(),
      ),
      GoRoute(
        path: '/galleries',
        builder: (context, state) => const GalleriesScreen(),
      ),
      GoRoute(
        path: '/events',
        builder: (context, state) => const EventsScreen(),
      ),
      GoRoute(
        path: '/jobs',
        builder: (context, state) => const JobsScreen(),
      ),
      GoRoute(
        path: '/create-job',
        builder: (context, state) => const CreateJobScreen(),
      ),
      GoRoute(
        path: '/proud-alumni',
        builder: (context, state) => const ProudAlumniScreen(),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/edit-profile',
        builder: (context, state) => const EditProfileScreen(),
      ),
      GoRoute(
        path: '/edit-password',
        builder: (context, state) => const EditPasswordScreen(),
      ),
      GoRoute(
        path: '/posts',
        builder: (context, state) => const PostsScreen(),
      ),
      GoRoute(
        path: '/create_post',
        builder: (context, state) => const CreatePostScreen(),
      ),
      GoRoute(
        path: '/conversations',
        builder: (context, state) => const ConversationsScreen(),
      ),
      GoRoute(
        path: '/chat',
        builder: (context, state) {
          final extra = state.extra;
          if (extra is Map<String, dynamic>) {
            return ChatScreen(
              otherUserId: extra['userId'] as int,
              otherUserName: extra['userName'] as String?,
              otherUserProfile: extra['userProfile'] as String?,
            );
          } else {
            // Fallback for old calls that just pass userId
            return ChatScreen(otherUserId: extra as int);
          }
        },
      ),
      GoRoute(
        path: '/announcements',
        builder: (context, state) => const AnnouncementsScreen(),
      ),
      GoRoute(
        path: '/discover',
        builder: (context, state) => const UserDiscoveryScreen(),
      ),
      GoRoute(
        path: '/alumni-map',
        builder: (context, state) => const AlumniMapScreen(),
      ),
      GoRoute(
        path: '/post/:id',
        builder: (context, state) {
          final id = int.parse(state.pathParameters['id']!);
          return SinglePostScreen(postId: id);
        },
      ),
      GoRoute(
        path: '/scan-qr',
        builder: (context, state) => const ScanEventQrScreen(),
      ),
      GoRoute(
        path: '/feedback',
        builder: (context, state) => const FeedbackEventListScreen(),
      ),
      GoRoute(
        path: '/feedback-options',
        builder: (context, state) {
          final eventId = state.extra as int?;
          return FeedbackSelectionScreen(eventId: eventId);
        },
      ),
      GoRoute(
        path: '/record-audio',
        builder: (context, state) {
          final eventId = state.extra as int?;
          return AudioRecordingScreen(eventId: eventId);
        },
      ),
      GoRoute(
        path: '/feedback-questions',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {'mode': 'text', 'file': null};
          return FeedbackScreen(
            mode: extra['mode'] as String,
            mediaFile: extra['file'] as File?,
            eventId: extra['event_id'] as int?,
          );
        },
      ),
    ],
  );
}
