import 'package:supabase_flutter/supabase_flutter.dart';
import 'fcm_service.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final _supabase = Supabase.instance.client;

  /// Send notification through multiple channels
  Future<bool> sendNotification({
    required String userId,
    required String title,
    required String body,
    required String type,
    Map<String, dynamic>? data,
  }) async {
    try {
      print('==============================================');
      print('📤 SENDING NOTIFICATION');
      print('==============================================');
      print('   User ID: $userId');
      print('   Type: $type');
      print('   Title: $title');
      print('   Body: $body');
      print('   Data: $data');

      // Get user's notification preferences
      final prefs = await _getUserPreferences(userId);
      print('   User Preferences: $prefs');

      final channels = _determineChannels(type, prefs);
      print('   Channels to use: $channels');

      // Create notification record
      print('   Creating notification in database...');
      final notification = await _supabase
          .from('notifications')
          .insert({
            'user_id': userId,
            'title': title,
            'body': body,
            'type': type,
            'data': data,
            'channels': channels,
            'state': 'pending',
          })
          .select()
          .single();

      print('   ✅ Notification created in DB: ${notification['id']}');
      print('   Notification data: $notification');

      // Send through each enabled channel
      bool sentSuccessfully = false;

      if (channels.contains('push')) {
        print('   📱 Sending push notification...');
        final pushResult = await _sendPushNotification(
          userId: userId,
          title: title,
          body: body,
          data: data,
        );
        print('   Push notification result: $pushResult');
        sentSuccessfully = pushResult || sentSuccessfully;
      }

      if (channels.contains('email')) {
        print('   📧 Sending email notification...');
        final emailResult = await _sendEmailNotification(
          userId: userId,
          title: title,
          body: body,
          type: type,
          data: data,
        );
        print('   Email notification result: $emailResult');
        sentSuccessfully = emailResult || sentSuccessfully;
      }

      // Update notification status
      print(
        '   Updating notification status to: ${sentSuccessfully ? "sent" : "failed"}',
      );
      await _supabase
          .from('notifications')
          .update({
            'state': sentSuccessfully ? 'sent' : 'failed',
            'sent_at': DateTime.now().toIso8601String(),
          })
          .eq('id', notification['id']);

      print('   ✅ Notification process complete!');
      print('==============================================');
      return sentSuccessfully;
    } catch (e) {
      print('❌ Error sending notification: $e');
      return false;
    }
  }

  /// Get user notification preferences
  Future<Map<String, dynamic>> _getUserPreferences(String userId) async {
    try {
      final prefs = await _supabase
          .from('notification_preferences')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      return prefs ??
          {
            'email_enabled': true,
            'push_enabled': true,
            'task_assigned': true,
            'project_assigned': true,
            'task_completed': true,
            'task_updated': true,
          };
    } catch (e) {
      print('Error fetching preferences: $e');
      return {
        'email_enabled': true,
        'push_enabled': true,
        'task_assigned': true,
        'project_assigned': true,
      };
    }
  }

  /// Determine which channels to use based on type and preferences
  List<String> _determineChannels(String type, Map<String, dynamic> prefs) {
    final channels = <String>[];

    // Check if this notification type is enabled
    final typeEnabled = prefs[type] ?? true;
    if (!typeEnabled) return channels;

    if (prefs['push_enabled'] == true) channels.add('push');
    if (prefs['email_enabled'] == true) channels.add('email');

    return channels;
  }

  /// Send push notification via FCM
  Future<bool> _sendPushNotification({
    required String userId,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      return await FCMService().sendNotification(
        userId: userId,
        title: title,
        body: body,
        data: data ?? {},
      );
    } catch (e) {
      print('Error sending push notification: $e');
      return false;
    }
  }

  /// Send email notification via Supabase Edge Function
  Future<bool> _sendEmailNotification({
    required String userId,
    required String title,
    required String body,
    required String type,
    Map<String, dynamic>? data,
  }) async {
    try {
      print('📧 Calling edge function: send-email-notification');
      print('📧 Payload: userId=$userId, title=$title');

      final response = await _supabase.functions.invoke(
        'send-email-notification',
        body: {
          'user_id': userId,
          'title': title,
          'body': body,
          'type': type,
          'data': data,
        },
      );

      print('📧 Edge function response: ${response.data}');

      if (response.data != null && response.data['success'] == true) {
        print('✅ Email sent successfully');
        return true;
      } else if (response.data != null && response.data['error'] != null) {
        print('❌ Email error: ${response.data['error']}');
        return false;
      }

      return false;
    } catch (e) {
      print('❌ Error calling email edge function: $e');
      return false;
    }
  }

  /// Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      await _supabase
          .from('notifications')
          .update({
            'state': 'read',
            'read_at': DateTime.now().toIso8601String(),
          })
          .eq('id', notificationId);
    } catch (e) {
      print('Error marking notification as read: $e');
    }
  }

  /// Get unread notification count
  Future<int> getUnreadCount() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return 0;

      final response = await _supabase
          .from('notifications')
          .select()
          .eq('user_id', userId)
          .neq('state', 'read');

      return (response as List).length;
    } catch (e) {
      print('Error getting unread count: $e');
      return 0;
    }
  }

  /// Stream unread notification count
  Stream<int> watchUnreadCount() async* {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      yield 0;
      return;
    }

    yield* _supabase
        .from('notifications')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .map((data) => data.where((n) => n['state'] != 'read').length);
  }

  /// Update notification preferences
  Future<void> updatePreferences(Map<String, dynamic> preferences) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      await _supabase.from('notification_preferences').upsert({
        'user_id': userId,
        ...preferences,
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Error updating preferences: $e');
    }
  }
}
