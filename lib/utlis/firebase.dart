// import 'package:firebase_messaging/firebase_messaging.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// import 'package:timezone/timezone.dart' as tz;
// class FirebaseUtils {
//
//   @pragma('vm:entry-point')
//   Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
//     debugPrint("Notification Data : ${message.notification?.title}");
//     if (message.notification != null) {
//
//     }
//     return;
//   }
//
//   FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
//   FlutterLocalNotificationsPlugin();
//   // Function to schedule a notification
// // Function to show notification immediately
//   void showNotificationImmediately() async {
//     // 1. Notification details waise hi rahenge
//     const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
//       'immediate_channel_id',
//       'Immediate Notifications',
//       channelDescription: 'Channel for immediate notifications',
//       importance: Importance.max,
//       priority: Priority.high,
//       playSound: true,
//       sound: RawResourceAndroidNotificationSound('sound1'),
//     );
//     const NotificationDetails platformDetails = NotificationDetails(android: androidDetails);
//
//     // 2. '.show()' method ka istemal karein
//     await flutterLocalNotificationsPlugin.show(
//       0, // Notification ID
//       'Immediate Notification', // Title
//       'Yeh notification turant dikha!', // Body
//       platformDetails,
//     );
//   }
//   late AndroidNotificationChannel channel;
//
//   void showFlutterNotification(RemoteMessage message) async {
//     RemoteNotification? notification = message.notification;
//     String? notificationTitle = notification?.title ?? message.data["title"];
//     String? notificationBody = notification?.body ?? message.data["body"];
//
//     if (notificationTitle != null || notificationBody != null) {
//       const String customSound = 'sound1';
//       flutterLocalNotificationsPlugin.show(
//         notification.hashCode,
//         notificationTitle,
//         notificationBody,
//         const NotificationDetails(
//           android: AndroidNotificationDetails(
//             'high_importance_channel',
//             'High Importance Notifications',
//             channelDescription: 'This channel is used for important notifications.',
//             icon: 'ic_launcher',
//             importance: Importance.max,
//             priority: Priority.high,
//             playSound: true,
//             sound: RawResourceAndroidNotificationSound(customSound),
//           ),
//         ),
//       );
//     }
//   }
//
//   void firebaseInit(){
//     debugPrint("Notification Data : initialize");
//     FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
//
//     FirebaseMessaging.onMessage.listen((RemoteMessage message) {
//       debugPrint("Notification Message : $message");
//       showFlutterNotification(message);
//     });
//
//     FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
//       debugPrint("App opened via notification: $message");
//     });
//   }
//
// }




import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app_badger/flutter_app_badger.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../bloc/notification_bloc/notification_count_cubit.dart';
import '../main.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// @pragma('vm:entry-point')
// Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
//
//   await Firebase.initializeApp();
//   debugPrint("Background message received: ${message.messageId}");
//
// }


// firebase.dart

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {

  await Firebase.initializeApp();
  debugPrint("Background message received: ${message.messageId}");
  debugPrint("========================================");
  debugPrint("=== BACKGROUND NOTIFICATION RECEIVED ===");
  debugPrint("========================================");
  debugPrint("Notification Block: ${message.notification?.toMap().toString()}");
  debugPrint("Data Block: ${message.data.toString()}");
  debugPrint("========================================");

  final prefs = await SharedPreferences.getInstance();
  int oldCount = prefs.getInt('notification_count') ?? 0;
  int newCount = oldCount + 1;
  await prefs.setInt('notification_count', newCount);
  FlutterAppBadger.updateBadgeCount(newCount);
  debugPrint("Badge count updated to $newCount in background.");
  // <<< BADGE LOGIC END >>>


  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();


  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'high_importance_channel',
    'High Importance Notifications',
    description: 'This channel is used for important notifications.',
    importance: Importance.max,
    playSound: true,
    sound: RawResourceAndroidNotificationSound('sound1'),
  );

  RemoteNotification? notification = message.notification;
  if (notification != null) {
    flutterLocalNotificationsPlugin.show(
      notification.hashCode,
      notification.title,
      notification.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          channel.id,
          channel.name,
          channelDescription: channel.description,
          icon: 'ic_launcher',
          playSound: true,
          sound: channel.sound,
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
    );
  }
}
class FirebaseUtils {
  // Flutter local notifications ka instance
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();


  Future<void> _initializeLocalNotifications() async {
    // Android ke liye initialization settings
    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
    InitializationSettings(android: initializationSettingsAndroid);

    await flutterLocalNotificationsPlugin.initialize(initializationSettings);

    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'high_importance_channel', // 1. Channel ki ek unique ID
      'High Importance Notifications',
      description: 'This channel is used for important notifications.',
      importance: Importance.max,
      playSound: true,
      sound: RawResourceAndroidNotificationSound('sound1'),
    );

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  void showFlutterNotification(RemoteMessage message) {
    RemoteNotification? notification = message.notification;

    if (notification != null) {
      flutterLocalNotificationsPlugin.show(
        notification.hashCode,
        notification.title,
        notification.body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'high_importance_channel',
            'High Importance Notifications',
            channelDescription: 'This channel is used for important notifications.',
            icon: 'ic_launcher',
            playSound: true,
            sound: RawResourceAndroidNotificationSound('sound1'),
          ),
        ),
      );
    }
  }


  void firebaseInit({VoidCallback? onNotificationReceived}) async {
    debugPrint("Firebase Notifications Initializing...");

    await _initializeLocalNotifications();

    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint("Foreground message received: ${message.messageId}");

      // Badge count in foreground
      navigatorKey.currentContext?.read<NotificationCountCubit>().increment();

      showFlutterNotification(message);
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint("App opened via notification: ${message.messageId}");
    });
  }
}