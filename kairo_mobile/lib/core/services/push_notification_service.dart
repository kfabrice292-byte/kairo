import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../router/app_router.dart';

// Top level function for background messages
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint("Handling a background message: ${message.messageId}");
}

class PushNotificationService {
  static final FirebaseMessaging _firebaseMessaging =
      FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    // Demander les permissions
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    debugPrint('User granted permission: ${settings.authorizationStatus}');

    // Obtenir le token FCM et l'enregistrer dans Firestore
    String? token = await _firebaseMessaging.getToken();
    debugPrint("FCM Token: $token");
    if (token != null) {
      await _saveTokenToDatabase(token);
    }

    // Écouter le rafraîchissement du token
    _firebaseMessaging.onTokenRefresh.listen(_saveTokenToDatabase);

    // Configurer Local Notifications (pour le Foreground)
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings();
    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotificationsPlugin.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        _handleNotificationClick(response.payload);
      },
    );

    // Configuration des channels Android
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'high_importance_channel', // id
      'High Importance Notifications', // title
      description:
          'This channel is used for important notifications.', // description
      importance: Importance.max,
    );

    await _localNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);

    // Gérer les messages quand l'app est au premier plan (Foreground)
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Got a message whilst in the foreground!');
      debugPrint('Message data: ${message.data}');

      if (message.notification != null) {
        debugPrint(
          'Message also contained a notification: ${message.notification}',
        );
        _showLocalNotification(message, channel);
      }
    });

    // Gérer les messages quand l'app est en arrière-plan (Background)
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Gérer l'ouverture de l'app via une notification
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint("Message clicked! (Opened App)");
      _handleMessageData(message.data);
    });

    // Check si l'app a été lancée depuis une notification (Terminated)
    RemoteMessage? initialMessage = await FirebaseMessaging.instance
        .getInitialMessage();
    if (initialMessage != null) {
      debugPrint("App launched by a notification!");
      // Nous ne pouvons pas naviguer tout de suite car le contexte n'est pas prêt,
      // il faudra utiliser un système global (ex: router) ou différer
      Future.delayed(const Duration(seconds: 1), () {
        _handleMessageData(initialMessage.data);
      });
    }
  }

  static Future<void> updateToken() async {
    String? token = await _firebaseMessaging.getToken();
    if (token != null) {
      await _saveTokenToDatabase(token);
    }
  }

  static Future<void> _saveTokenToDatabase(String token) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({'fcmToken': token})
          .catchError((e) => debugPrint("Error saving FCM Token: $e"));
    }
  }

  static void _showLocalNotification(
    RemoteMessage message,
    AndroidNotificationChannel channel,
  ) {
    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;

    if (notification != null && android != null) {
      _localNotificationsPlugin.show(
        id: notification.hashCode,
        title: notification.title,
        body: notification.body,
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            channel.id,
            channel.name,
            channelDescription: channel.description,
            icon: android.smallIcon ?? '@mipmap/ic_launcher',
          ),
          iOS: const DarwinNotificationDetails(),
        ),
        payload: message.data.toString(), // On peut passer un payload formaté
      );
    }
  }

  static void _handleNotificationClick(String? payload) {
    if (payload != null) {
      debugPrint("Notification clicked with payload: $payload");
      // Fallback simple: on va sur les notifications s'il y a un clic générique
      if (rootNavigatorKey.currentContext != null) {
        appRouter.go('/notifications');
      }
    }
  }

  static void _handleMessageData(Map<String, dynamic> data) {
    if (data.isNotEmpty && rootNavigatorKey.currentContext != null) {
      debugPrint("Handling data: $data");
      final type = data['type'];
      final relatedId = data['relatedId'];

      switch (type) {
        case 'chat':
          appRouter.go('/chat_list');
          break;
        case 'network':
          appRouter.go('/main');
          break;
        case 'post':
          appRouter.go('/main');
          break;
        case 'opportunity':
          // Redirige vers la page des opportunités (index 2 du MainScaffold)
          appRouter.go('/main', extra: {'tab': 2}); 
          break;
        default:
          appRouter.go('/notifications');
      }
    }
  }
}
