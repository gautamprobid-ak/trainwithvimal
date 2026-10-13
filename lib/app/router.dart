import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/widgets/widgets.dart';
import '../data/state/session.dart';
import '../features/admin/activity/activity_screen.dart';
import '../features/admin/approvals/approvals_screen.dart';
import '../features/admin/automations/automation_builder_screen.dart';
import '../features/admin/automations/automation_new_screen.dart';
import '../features/admin/automations/automations_screen.dart';
import '../features/admin/calendar/admin_calendar_screen.dart';
import '../features/admin/clients/admin_client_profile_screen.dart';
import '../features/admin/clients/admin_clients_screen.dart';
import '../features/admin/dashboard/admin_dashboard_screen.dart';
import '../features/admin/emails/emails_screen.dart';
import '../features/admin/forms/form_builder_screen.dart';
import '../features/admin/forms/forms_screen.dart';
import '../features/admin/more/admin_more_screen.dart';
import '../features/admin/settings/settings_screen.dart';
import '../features/admin/trainers/trainer_profile_screen.dart';
import '../features/admin/trainers/trainers_screen.dart';
import '../features/auth/health_setup_screen.dart';
import '../features/auth/intro_screen.dart';
import '../features/auth/join_link_screen.dart';
import '../features/auth/login_screen.dart';
import '../features/auth/permissions_screen.dart';
import '../features/auth/reset_password_screen.dart';
import '../features/auth/verify_email_screen.dart';
import '../features/auth/welcome_screen.dart';
import '../features/build/content/content_library_screen.dart';
import '../features/build/exercises/exercise_add_screen.dart';
import '../features/build/exercises/exercise_detail_screen.dart';
import '../features/build/exercises/exercise_library_screen.dart';
import '../features/build/habits/habits_library_screen.dart';
import '../features/build/nutrition/meal_plan_builder_screen.dart';
import '../features/build/nutrition/nutrition_screen.dart';
import '../features/build/programs/program_builder_screen.dart';
import '../features/build/programs/programs_screen.dart';
import '../features/client/about/client_about_screen.dart';
import '../features/client/checkins/client_checkins_screen.dart';
import '../features/client/food/food_log_screen.dart';
import '../features/client/food/meal_plan_screen.dart';
import '../features/client/food/nutrition_overview_screen.dart';
import '../features/client/habits/client_habits_screen.dart';
import '../features/client/home/client_home_screen.dart';
import '../features/client/library/client_library_screen.dart';
import '../features/client/more/client_more_screen.dart';
import '../features/client/progress/client_progress_screen.dart';
import '../features/client/train/client_train_screen.dart';
import '../features/client/workout/workout_logger_screen.dart';
import '../features/trainer/calendar/trainer_calendar_screen.dart';
import '../features/trainer/checkins/trainer_checkins_screen.dart';
import '../features/trainer/clients/trainer_client_profile_screen.dart';
import '../features/trainer/clients/trainer_clients_screen.dart';
import '../features/trainer/dashboard/trainer_dashboard_screen.dart';
import '../features/trainer/me/trainer_me_screen.dart';
import '../features/trainer/more/trainer_more_screen.dart';

/// All app routes.
///
/// Flow (same as the design's links):
///   /welcome → /login (or /join from an invite link) → /verify-email →
///   /setup/health → /permissions → /intro → the role's home.
///
/// Each role has a 5-tab shell. Sub pages live inside their tab's branch so
/// the bottom bar stays and the parent tab stays highlighted.
///   Client  /c : Home · Train · Food · Progress · More
///   Trainer /t : Home · Clients · Check-ins · Calendar · More
///   Admin   /a : Home · Clients · Approvals · Calendar · More
abstract final class Routes {
  static const welcome = '/welcome';
  static const login = '/login';
  static const resetPassword = '/reset-password';
  static const verifyEmail = '/verify-email';
  static const join = '/join';
  static const permissions = '/permissions';
  static const intro = '/intro';
  static const healthSetup = '/setup/health';

  // Client
  static const cHome = '/c/home';
  static const cTrain = '/c/train';
  static const cWorkout = '/c/train/workout';
  static const cFood = '/c/food';
  static const cFoodLog = '/c/food/log';
  static const cNutrition = '/c/food/nutrition';
  static const cProgress = '/c/progress';
  static const cMore = '/c/more';
  static const cHabits = '/c/more/habits';
  static const cCheckins = '/c/more/checkins';
  static const cLibrary = '/c/more/library';
  static const cAbout = '/c/more/about';

  // Trainer
  static const tHome = '/t/home';
  static const tClients = '/t/clients';
  static String tClient(String id) => '/t/clients/$id';
  static const tCheckins = '/t/checkins';
  static const tCalendar = '/t/calendar';
  static const tMore = '/t/more';
  static const tMe = '/t/more/me';

  // Admin
  static const aHome = '/a/home';
  static const aClients = '/a/clients';
  static String aClient(String id) => '/a/clients/$id';
  static const aApprovals = '/a/approvals';
  static const aCalendar = '/a/calendar';
  static const aMore = '/a/more';
  static const aTrainers = '/a/more/trainers';
  static String aTrainer(String id) => '/a/more/trainers/$id';
  static const aActivity = '/a/more/activity';
  static const aForms = '/a/more/forms';
  static const aFormBuilder = '/a/more/forms/builder';
  static const aAutomations = '/a/more/automations';
  static const aAutomationNew = '/a/more/automations/new';
  static const aAutomationBuilder = '/a/more/automations/builder';
  static const aEmails = '/a/more/emails';
  static const aSettings = '/a/more/settings';

  // Build pages shared by admin and trainer. Use with context.rolePath():
  //   context.push(context.rolePath(Routes.programs))
  static const programs = '/more/programs';
  static const programBuilder = '/more/programs/builder';
  static const exercises = '/more/exercises';
  static const exerciseNew = '/more/exercises/new';
  static String exercise(String id) => '/more/exercises/$id';
  static const nutrition = '/more/nutrition';
  static const mealPlanBuilder = '/more/nutrition/meal-plan';
  static const habits = '/more/habits';
  static const content = '/more/content';

  /// Client profile for the current role (admin or trainer).
  static String clientProfile(BuildContext context, String id) => context.isTrainerApp ? tClient(id) : aClient(id);
}

final _rootKey = GlobalKey<NavigatorState>();

/// Lets the router re-run its redirect when the session changes.
class _SessionListenable extends ChangeNotifier {
  _SessionListenable(Ref ref) {
    ref.listen(sessionProvider, (_, _) => notifyListeners());
  }
}

GoRoute _page(String path, Widget Function(GoRouterState s) build, {List<RouteBase> routes = const []}) =>
    GoRoute(path: path, pageBuilder: (c, s) => NoTransitionPage(key: s.pageKey, child: build(s)), routes: routes);

GoRoute _sub(String path, Widget Function(GoRouterState s) build, {List<RouteBase> routes = const []}) =>
    GoRoute(path: path, builder: (c, s) => build(s), routes: routes);

GoRoute _bare(String path, Widget child) =>
    GoRoute(path: path, parentNavigatorKey: _rootKey, builder: (c, s) => BarePage(child: child));

/// Library / build pages, mounted under the More tab of both admin and trainer.
List<RouteBase> _buildRoutes() => [
      _sub('programs', (s) => const ProgramsScreen(), routes: [
        _sub('builder', (s) => const ProgramBuilderScreen()),
      ]),
      _sub('exercises', (s) => const ExerciseLibraryScreen(), routes: [
        _sub('new', (s) => const ExerciseAddScreen()),
        _sub(':exerciseId', (s) => ExerciseDetailScreen(exerciseId: s.pathParameters['exerciseId']!)),
      ]),
      _sub('nutrition', (s) => const NutritionLibraryScreen(), routes: [
        _sub('meal-plan', (s) => const MealPlanBuilderScreen()),
      ]),
      _sub('habits', (s) => const HabitsLibraryScreen()),
      _sub('content', (s) => const ContentLibraryScreen()),
    ];

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: _rootKey,
    initialLocation: Routes.welcome,
    refreshListenable: _SessionListenable(ref),
    redirect: (context, state) {
      final session = ref.read(sessionProvider);
      final path = state.uri.path;
      final inApp = path.startsWith('/c/') || path.startsWith('/t/') || path.startsWith('/a/');
      if (session == null) return inApp ? Routes.welcome : null;
      // Signed in: keep each role inside its own app.
      final base = switch (session.role) { Role.client => '/c/', Role.trainer => '/t/', Role.admin => '/a/' };
      if (inApp && !path.startsWith(base)) return homeFor(session.role);
      if (path == Routes.welcome || path == Routes.login) return homeFor(session.role);
      return null;
    },
    routes: [
      _bare(Routes.welcome, const WelcomeScreen()),
      _bare(Routes.login, const LoginScreen()),
      _bare(Routes.resetPassword, const ResetPasswordScreen()),
      _bare(Routes.verifyEmail, const VerifyEmailScreen()),
      _bare(Routes.join, const JoinLinkScreen()),
      _bare(Routes.permissions, const PermissionsScreen()),
      _bare(Routes.intro, const IntroScreen()),
      _bare(Routes.healthSetup, const HealthSetupScreen()),

      // ---------------- Client ----------------
      StatefulShellRoute.indexedStack(
        builder: (c, s, shell) => RoleShell(shell: shell, tabs: const [
          ShellTab('Home', Icons.home_outlined, Icons.home_rounded),
          ShellTab('Train', Icons.fitness_center_outlined, Icons.fitness_center_rounded),
          ShellTab('Food', Icons.restaurant_outlined, Icons.restaurant_rounded),
          ShellTab('Progress', Icons.insights_outlined, Icons.insights_rounded),
          ShellTab('More', Icons.grid_view_outlined, Icons.grid_view_rounded),
        ]),
        branches: [
          StatefulShellBranch(routes: [_page(Routes.cHome, (s) => const ClientHomeScreen())]),
          StatefulShellBranch(routes: [
            _page(Routes.cTrain, (s) => const ClientTrainScreen(), routes: [
              _sub('workout', (s) => const WorkoutLoggerScreen()),
            ]),
          ]),
          StatefulShellBranch(routes: [
            _page(Routes.cFood, (s) => const MealPlanScreen(), routes: [
              _sub('log', (s) => const FoodLogScreen()),
              _sub('nutrition', (s) => const NutritionOverviewScreen()),
            ]),
          ]),
          StatefulShellBranch(routes: [_page(Routes.cProgress, (s) => const ClientProgressScreen())]),
          StatefulShellBranch(routes: [
            _page(Routes.cMore, (s) => const ClientMoreScreen(), routes: [
              _sub('habits', (s) => const ClientHabitsScreen()),
              _sub('checkins', (s) => const ClientCheckinsScreen()),
              _sub('library', (s) => const ClientLibraryScreen()),
              _sub('about', (s) => const ClientAboutScreen()),
            ]),
          ]),
        ],
      ),

      // ---------------- Trainer ----------------
      StatefulShellRoute.indexedStack(
        builder: (c, s, shell) => RoleShell(shell: shell, tabs: [
          const ShellTab('Home', Icons.home_outlined, Icons.home_rounded),
          const ShellTab('Clients', Icons.people_outline_rounded, Icons.people_rounded),
          ShellTab('Check-ins', Icons.fact_check_outlined, Icons.fact_check_rounded, badge: () => 3),
          const ShellTab('Calendar', Icons.calendar_today_outlined, Icons.calendar_today_rounded),
          const ShellTab('More', Icons.grid_view_outlined, Icons.grid_view_rounded),
        ]),
        branches: [
          StatefulShellBranch(routes: [_page(Routes.tHome, (s) => const TrainerDashboardScreen())]),
          StatefulShellBranch(routes: [
            _page(Routes.tClients, (s) => const TrainerClientsScreen(), routes: [
              _sub(':clientId', (s) => TrainerClientProfileScreen(clientId: s.pathParameters['clientId']!)),
            ]),
          ]),
          StatefulShellBranch(routes: [_page(Routes.tCheckins, (s) => const TrainerCheckinsScreen())]),
          StatefulShellBranch(routes: [_page(Routes.tCalendar, (s) => const TrainerCalendarScreen())]),
          StatefulShellBranch(routes: [
            _page(Routes.tMore, (s) => const TrainerMoreScreen(), routes: [
              _sub('me', (s) => const TrainerMeScreen()),
              ..._buildRoutes(),
            ]),
          ]),
        ],
      ),

      // ---------------- Admin ----------------
      StatefulShellRoute.indexedStack(
        builder: (c, s, shell) => RoleShell(shell: shell, tabs: [
          const ShellTab('Home', Icons.home_outlined, Icons.home_rounded),
          const ShellTab('Clients', Icons.people_outline_rounded, Icons.people_rounded),
          ShellTab('Approvals', Icons.how_to_reg_outlined, Icons.how_to_reg_rounded, badge: () => 3),
          const ShellTab('Calendar', Icons.calendar_today_outlined, Icons.calendar_today_rounded),
          const ShellTab('More', Icons.grid_view_outlined, Icons.grid_view_rounded),
        ]),
        branches: [
          StatefulShellBranch(routes: [_page(Routes.aHome, (s) => const AdminDashboardScreen())]),
          StatefulShellBranch(routes: [
            _page(Routes.aClients, (s) => const AdminClientsScreen(), routes: [
              _sub(':clientId', (s) => AdminClientProfileScreen(clientId: s.pathParameters['clientId']!)),
            ]),
          ]),
          StatefulShellBranch(routes: [_page(Routes.aApprovals, (s) => const ApprovalsScreen())]),
          StatefulShellBranch(routes: [_page(Routes.aCalendar, (s) => const AdminCalendarScreen())]),
          StatefulShellBranch(routes: [
            _page(Routes.aMore, (s) => const AdminMoreScreen(), routes: [
              _sub('trainers', (s) => const TrainersScreen(), routes: [
                _sub(':trainerId', (s) => TrainerProfileScreen(trainerId: s.pathParameters['trainerId']!)),
              ]),
              _sub('activity', (s) => const ActivityScreen()),
              _sub('forms', (s) => const FormsScreen(), routes: [
                _sub('builder', (s) => const FormBuilderScreen()),
              ]),
              _sub('automations', (s) => const AutomationsScreen(), routes: [
                _sub('new', (s) => const AutomationNewScreen()),
                _sub('builder', (s) => const AutomationBuilderScreen()),
              ]),
              _sub('emails', (s) => const EmailsScreen()),
              _sub('settings', (s) => const SettingsScreen()),
              ..._buildRoutes(),
            ]),
          ]),
        ],
      ),
    ],
  );
});
