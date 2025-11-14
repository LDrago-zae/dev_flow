import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

/// Top-level function for handling background messages
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (kDebugMode) {
    print('Handling background message: ${message.messageId}');
    print('Title: ${message.notification?.title}');
    print('Body: ${message.notification?.body}');
  }
}

class FCMService {
  static final FCMService _instance = FCMService._internal();
  factory FCMService() => _instance;
  FCMService._internal();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final _supabase = Supabase.instance.client;

  String? _currentToken;

  /// Get current FCM token
  String? get currentToken => _currentToken;

  /// Initialize FCM service
  Future<void> initialize() async {
    try {
      // Request permission for iOS
      NotificationSettings settings = await _fcm.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        announcement: false,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
      );

      if (kDebugMode) {
        print('FCM Permission Status: ${settings.authorizationStatus}');
      }

      if (settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional) {
        // Initialize local notifications
        await _initializeLocalNotifications();

        // Get FCM token
        _currentToken = await _fcm.getToken();
        if (_currentToken != null) {
          if (kDebugMode) {
            print('FCM Token: $_currentToken');
          }
          await _saveFCMToken(_currentToken!);
        }

        // Listen for token refresh
        _fcm.onTokenRefresh.listen((newToken) {
          _currentToken = newToken;
          _saveFCMToken(newToken);
        });

        // Handle foreground messages
        FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

        // Handle notification tap when app is in background
        FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

        // Check if app was opened from a terminated state
        final initialMessage = await _fcm.getInitialMessage();
        if (initialMessage != null) {
          _handleNotificationTap(initialMessage);
        }

        if (kDebugMode) {
          print('✅ FCM Service initialized successfully');
        }
      } else {
        if (kDebugMode) {
          print('❌ FCM Permission denied');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error initializing FCM: $e');
      }
    }
  }

  /// Initialize local notifications for showing foreground notifications
  Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Create notification channel for Android
    const androidChannel = AndroidNotificationChannel(
      'high_importance_channel',
      'High Importance Notifications',
      description: 'This channel is used for important notifications.',
      importance: Importance.high,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(androidChannel);
  }

  /// Save FCM token to Supabase
  Future<void> _saveFCMToken(String token) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        if (kDebugMode) {
          print('Cannot save FCM token: User not authenticated');
        }
        return;
      }

      await _supabase.from('user_fcm_tokens').upsert({
        'user_id': userId,
        'fcm_token': token,
        'updated_at': DateTime.now().toIso8601String(),
      });

      if (kDebugMode) {
        print('✅ FCM token saved to Supabase');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error saving FCM token: $e');
      }
    }
  }

  /// Handle foreground messages (when app is open)
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    if (kDebugMode) {
      print('📬 Foreground message received');
      print('Title: ${message.notification?.title}');
      print('Body: ${message.notification?.body}');
      print('Data: ${message.data}');
    }

    // Show local notification
    if (message.notification != null) {
      await _showLocalNotification(message);
    }
  }

  /// Show local notification
  Future<void> _showLocalNotification(RemoteMessage message) async {
    const androidDetails = AndroidNotificationDetails(
      'high_importance_channel',
      'High Importance Notifications',
      channelDescription: 'This channel is used for important notifications.',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      message.hashCode,
      message.notification?.title,
      message.notification?.body,
      notificationDetails,
      payload: message.data.toString(),
    );
  }

  /// Handle notification tap (when app is in background/terminated)
  void _handleNotificationTap(RemoteMessage message) {
    if (kDebugMode) {
      print('🔔 Notification tapped');
      print('Data: ${message.data}');
    }

    // Handle navigation based on notification data
    final data = message.data;

    if (data.containsKey('type')) {
      switch (data['type']) {
        case 'task':
          // Navigate to task detail
          final taskId = data['taskId'];
          if (kDebugMode) {
            print('Navigate to task: $taskId');
          }
          // TODO: Implement navigation
          break;
        case 'project':
          // Navigate to project detail
          final projectId = data['projectId'];
          if (kDebugMode) {
            print('Navigate to project: $projectId');
          }
          // TODO: Implement navigation
          break;
        default:
          if (kDebugMode) {
            print('Unknown notification type: ${data['type']}');
          }
      }
    }
  }

  /// Handle local notification tap
  void _onNotificationTapped(NotificationResponse response) {
    if (kDebugMode) {
      print('🔔 Local notification tapped');
      print('Payload: ${response.payload}');
    }
    // Handle navigation based on payload
  }

  /// Delete FCM token from device and Supabase
  Future<void> deleteToken() async {
    try {
      final userId = _supabase.auth.currentUser?.id;

      // Delete token from Firebase
      await _fcm.deleteToken();
      _currentToken = null;

      // Delete token from Supabase
      if (userId != null) {
        await _supabase.from('user_fcm_tokens').delete().eq('user_id', userId);
      }

      if (kDebugMode) {
        print('✅ FCM token deleted');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error deleting FCM token: $e');
      }
    }
  }

  /// Send notification via Supabase Edge Function
  Future<bool> sendNotification({
    required String userId,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      final response = await _supabase.functions.invoke(
        'send-notification',
        body: {
          'userId': userId,
          'title': title,
          'body': body,
          'data': data ?? {},
        },
      );

      if (kDebugMode) {
        print('✅ Notification sent: ${response.data}');
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error sending notification: $e');
      }
      return false;
    }
  }

  /// Subscribe to a topic
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _fcm.subscribeToTopic(topic);
      if (kDebugMode) {
        print('✅ Subscribed to topic: $topic');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error subscribing to topic: $e');
      }
    }
  }

  /// Unsubscribe from a topic
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _fcm.unsubscribeFromTopic(topic);
      if (kDebugMode) {
        print('✅ Unsubscribed from topic: $topic');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error unsubscribing from topic: $e');
      }
    }
  }
}
