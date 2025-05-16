import 'package:OhMyGERD/presentation/pages/image_process/scan_only/meal_result.dart';
import 'package:OhMyGERD/presentation/pages/image_process/scan_only/meal_scan.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:OhMyGERD/data/models/meal_model.dart';
import 'package:OhMyGERD/presentation/layouts/mealdetail_layout.dart';
import 'package:OhMyGERD/presentation/pages/intro/onboarding_controller.dart';
import 'package:OhMyGERD/presentation/pages/auth/biodatapage.dart';
import 'package:OhMyGERD/presentation/pages/auth/connectionspage.dart';
import 'package:OhMyGERD/presentation/pages/auth/loginpage.dart';
import 'package:OhMyGERD/presentation/pages/auth/preferencepage.dart';
import 'package:OhMyGERD/presentation/pages/auth/registerpage.dart';
import 'package:OhMyGERD/presentation/pages/intro/splashscreen.dart';
import 'package:OhMyGERD/presentation/pages/main/calendarpage.dart';
import 'package:OhMyGERD/presentation/pages/main/chatbotpage.dart';
import 'package:OhMyGERD/presentation/pages/main/homepage.dart';
import 'package:OhMyGERD/presentation/pages/image_process/by_time/foodcomponentpage.dart';
import 'package:OhMyGERD/presentation/pages/image_process/by_time/foodresultpage.dart';
import 'package:OhMyGERD/presentation/pages/main/profilepage.dart';
import 'package:OhMyGERD/presentation/layouts/navigation_wrapper.dart';
import 'package:OhMyGERD/presentation/pages/others/achievementpage.dart';
import 'package:OhMyGERD/presentation/pages/settings/connectionssettingspage.dart';
import 'package:OhMyGERD/presentation/pages/others/notificationpage.dart';
import 'package:OhMyGERD/presentation/pages/settings/preferencesettingspage.dart';
import 'package:OhMyGERD/presentation/pages/settings/profilesettingspage.dart';
import 'package:OhMyGERD/presentation/pages/settings/settingspage.dart';
import 'app_routes.dart';

// Tambahin navigator key
final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

class AppPages {
  static final GoRouter router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: AppRoutes.splashscreen,
    routes: [
      GoRoute(
        path: AppRoutes.splashscreen,
        builder: (context, state) => SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (BuildContext context, GoRouterState state) {
          return const OnboardingController();
        },
      ),

      GoRoute(path: AppRoutes.login, builder: (context, state) => LoginPage()),
      GoRoute(
        path: AppRoutes.register,
        builder: (context, state) => RegistrationPage(),
      ),
      GoRoute(
        path: AppRoutes.biodata,
        builder: (context, state) => BiodataPage(),
      ),
      GoRoute(
        path: AppRoutes.preference,
        builder: (context, state) => PreferencePage(),
      ),
      GoRoute(
        path: AppRoutes.connections,
        builder: (context, state) => ConnectionsPage(),
      ),
      GoRoute(
        path: AppRoutes.settings,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => SettingsPage(),
      ),
      GoRoute(
        path: '/settings/profile',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => ProfileSettingsPage(),
      ),
      GoRoute(
        path: '/settings/preference',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => PreferenceSettingsPage(),
      ),
      GoRoute(
        path: '/settings/connections',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => ConnectionsSettingsPage(),
      ),
      GoRoute(
        path: AppRoutes.notification,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => NotificationPage(),
      ),
      GoRoute(
        path: AppRoutes.foodComponent,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => FoodComponentPage(),
      ),
      GoRoute(
        path: AppRoutes.foodResult,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => FoodResultPage(),
      ),
      GoRoute(
        path: AppRoutes.chatbot,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          // Extract the extra data from the state
          final Map<String, dynamic>? extraData =
              state.extra as Map<String, dynamic>?;

          // Pass the extra data to ChatbotPage
          return ChatbotPage(extraData: extraData);
        },
      ),
      GoRoute(
        path: AppRoutes.achievement,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => AchievementPage(),
      ),
      GoRoute(
        path: AppRoutes.mealDetails,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final foodItem = state.extra as MealModel;
          return MealDetailLayout(
            imagePath: foodItem.imagePath,
            mealName: foodItem.mealName,
            ingredients: foodItem.ingredients,
            steps: foodItem.steps,
            tools: foodItem.tools,
          );
        },
      ),
      GoRoute(
        path: AppRoutes.mealScan,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => MealScan(),
      ),
      GoRoute(
        path: AppRoutes.mealResult,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => MealResult(),
      ),
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) => NavigationWrapper(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.home,
            builder: (context, state) => HomePage(),
          ),
          GoRoute(
            path: AppRoutes.calendar,
            builder: (context, state) => CalendarPage(),
          ),

          GoRoute(
            path: AppRoutes.profile,
            builder: (context, state) => ProfilePage(),
          ),
        ],
      ),
    ],
  );
}
