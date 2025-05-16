import 'package:OhMyGERD/data/services/auth_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await NotificationService.instance.setupFlutterNotification();
  await NotificationService.instance.showNotification(message);
}

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();
  final _messaging = FirebaseMessaging.instance;
  final _localNotification = FlutterLocalNotificationsPlugin();

  bool _isFlutterLocalNotificationInitialized = false;

  Future<void> initialize() async {
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    await requestNotificationPermission();
    await _setupMessageHandlers();
    final token = await _messaging.getToken();
    print("ini token $token");
  }

  Future<void> requestNotificationPermission() async {
    final authService = AuthService();
    final messaging = FirebaseMessaging.instance;
    final settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
      announcement: false,
      carPlay: false,
      criticalAlert: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      final fcmToken = await messaging.getToken();

      final user = FirebaseAuth.instance.currentUser;
      if (fcmToken != null && user != null) {
        final isLatest = await authService.verifyLatestFCMToken(user, fcmToken);
        print(isLatest);
        if (isLatest != true) {
          final response = await authService.sendFCMToken(user, fcmToken);
          print(response);
        }
      }
      print('Notifikasi diizinkan');
    } else if (settings.authorizationStatus ==
        AuthorizationStatus.provisional) {
      print('Notifikasi provisional diizinkan');
    } else {
      print('Notifikasi ditolak');
    }

    // (Optional) request explicitly via permission_handler
    final status = await Permission.notification.request();
    print('Permission status: $status');
  }

  Future<void> setupFlutterNotification() async {
    if (_isFlutterLocalNotificationInitialized) {
      return;
    }
    const channel = AndroidNotificationChannel(
      "high_importance_channel",
      "high Importance Notification",
      description: "This channel is used for important notification",
      importance: Importance.high,
    );
    await _localNotification
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);
    const intializationSettingsAndroid = AndroidInitializationSettings(
      "@mipmap/ic_launcher",
    );
    // final intializationSettingsDarwin = DarwinInitializationSettings(
    //   onDidReceiveLocalNotification :(id,title,body,paylod)async{

    //   },
    // );
    final initializationSetting = InitializationSettings(
      android: intializationSettingsAndroid,
    );
    await _localNotification.initialize(
      initializationSetting,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        final payload = response.payload;
        // disini arahin ke page tertentu
        print("User membuka notifikasi dengan payload: $payload");
      },
    );
    _isFlutterLocalNotificationInitialized = true;
  }

  Future<void> showNotification(RemoteMessage message) async {
    RemoteNotification? notification = message.notification;
    print("notification : ${notification}");
    AndroidNotification? android = message.notification?.android;
    if (notification != null && android != null) {
      await _localNotification.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            "high_importance_channel",
            "high importance notifications",
            channelDescription:
                "This channel is used for important notifications",
            importance: Importance.high,
            priority: Priority.high,
            icon: "@mipmap/ic_launcher",
          ),
        ),
        payload: message.data.toString(),
      );
    }
  }

  Future<void> _setupMessageHandlers() async {
    FirebaseMessaging.onMessage.listen((message) {
      showNotification(message);
    });
    FirebaseMessaging.onMessageOpenedApp.listen(_handleBackgroundMessage);
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleBackgroundMessage(initialMessage);
    }
  }

  void _handleBackgroundMessage(RemoteMessage message) {
    if (message.data['type'] == 'chat') {}
  }
}
