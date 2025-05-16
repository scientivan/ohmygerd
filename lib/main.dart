import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:OhMyGERD/data/services/notification_service.dart';
import 'package:OhMyGERD/presentation/providers/meal_activity_provider.dart';
import 'package:OhMyGERD/presentation/providers/notification_provider.dart';
import 'package:OhMyGERD/presentation/providers/water_activity_provider.dart';
import 'package:OhMyGERD/presentation/routes/app_pages.dart';
import 'package:firebase_core/firebase_core.dart';
// import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:OhMyGERD/core/fonts.dart';
import 'package:provider/provider.dart'; // Import flutter_dotenv
import 'package:OhMyGERD/data/models/meal_model.dart';
import 'package:OhMyGERD/data/services/location_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // nek bawah ini error, di comment dlu aja KIM, KIM AHN JYOENG LARI MARATHON
  await dotenv.load(fileName: ".env");
  await Firebase.initializeApp();
  await NotificationService.instance.initialize();
  await MealModel.loadMealsFromJson();
  await UserLocation().getCurrentLocation();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ChangeNotifierProvider(create: (_) => WaterActivityProvider()),
        ChangeNotifierProvider(create: (_) => MealActivityProvider()),
      ],
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(390, 844),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp.router(
          routerConfig: AppPages.router,
          theme: ThemeData(fontFamily: AppFonts.outfit),
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}
