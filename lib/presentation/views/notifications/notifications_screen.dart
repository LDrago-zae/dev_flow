import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:dev_flow/core/constants/app_colors.dart';
import 'package:dev_flow/core/utils/app_text_styles.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:go_router/go_router.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      final data = await _supabase
          .from('notifications')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(50);

      setState(() {
        _notifications = List<Map<String, dynamic>>.from(data);
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading notifications: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _markAsRead(String notificationId, int index) async {
    try {
      await _supabase
          .from('notifications')
          .update({
            'state': 'read',
            'read_at': DateTime.now().toIso8601String(),
          })
          .eq('id', notificationId);

      setState(() {
        _notifications[index]['state'] = 'read';
        _notifications[index]['read_at'] = DateTime.now().toIso8601String();
      });
    } catch (e) {
      print('Error marking as read: $e');
    }
  }

  Future<void> _markAllAsRead() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      await _supabase
          .from('notifications')
          .update({
            'state': 'read',
            'read_at': DateTime.now().toIso8601String(),
          })
          .eq('user_id', userId)
          .neq('state', 'read');

      setState(() {
        for (var notification in _notifications) {
          notification['state'] = 'read';
          notification['read_at'] = DateTime.now().toIso8601String();
        }
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All notifications marked as read'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Error marking all as read: $e');
    }
  }

  Future<void> _deleteNotification(String notificationId, int index) async {
    try {
      await _supabase.from('notifications').delete().eq('id', notificationId);

      setState(() {
        _notifications.removeAt(index);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Notification deleted'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Error deleting notification: $e');
    }
  }

  void _handleNotificationTap(Map<String, dynamic> notification, int index) {
    // Mark as read
    if (notification['state'] != 'read') {
      _markAsRead(notification['id'], index);
    }

    // Navigate based on notification type
    final data = notification['data'] as Map<String, dynamic>?;
    if (data != null) {
      if (data['projectId'] != null) {
        context.push('/project/${data['projectId']}');
      } else if (data['taskId'] != null) {
        // Navigate to task details if you have such screen
        // context.push('/task/${data['taskId']}');
      }
    }
  }

  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'task_assigned':
        return Icons.assignment_ind;
      case 'project_assigned':
        return Icons.folder_special;
      case 'task_completed':
        return Icons.check_circle;
      case 'task_updated':
        return Icons.update;
      case 'project_updated':
        return Icons.edit_note;
      default:
        return Icons.notifications;
    }
  }

  Color _getNotificationColor(String type) {
    switch (type) {
      case 'task_assigned':
        return Colors.blue;
      case 'project_assigned':
        return DarkThemeColors.primary100;
      case 'task_completed':
        return Colors.green;
      case 'task_updated':
        return Colors.orange;
      case 'project_updated':
        return Colors.purple;
      default:
        return DarkThemeColors.textSecondary;
    }
  }

  Widget _buildChannelBadge(String channel) {
    IconData icon;
    Color color;

    switch (channel) {
      case 'push':
        icon = Icons.phone_android;
        color = Colors.blue;
        break;
      case 'email':
        icon = Icons.email;
        color = Colors.red;
        break;
      case 'whatsapp':
        icon = Icons.chat_bubble;
        color = const Color(0xFF25D366);
        break;
      default:
        icon = Icons.notifications;
        color = DarkThemeColors.textSecondary;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 2),
          Text(
            channel.toUpperCase(),
            style: TextStyle(
              color: color,
              fontSize: 8,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = _notifications
        .where((n) => n['state'] != 'read')
        .length;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
        ),
        title: Text(
          'Notifications',
          style: AppTextStyles.headlineSmall.copyWith(
            fontWeight: FontWeight.w600,
            color: DarkThemeColors.light,
          ),
        ),
        actions: [
          if (unreadCount > 0)
            TextButton.icon(
              onPressed: _markAllAsRead,
              icon: const Icon(Icons.done_all, size: 18),
              label: const Text('Mark all read'),
              style: TextButton.styleFrom(
                foregroundColor: DarkThemeColors.primary100,
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: DarkThemeColors.primary100,
              ),
            )
          : _notifications.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_none,
                    size: 80,
                    color: DarkThemeColors.textSecondary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No notifications yet',
                    style: AppTextStyles.headlineSmall.copyWith(
                      color: DarkThemeColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'You\'ll see notifications here when\nsomeone assigns you a task or project',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: DarkThemeColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadNotifications,
              color: DarkThemeColors.primary100,
              backgroundColor: DarkThemeColors.surface,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _notifications.length,
                itemBuilder: (context, index) {
                  final notification = _notifications[index];
                  final isUnread = notification['state'] != 'read';
                  final type = notification['type'] as String;
                  final channels = List<String>.from(
                    notification['channels'] ?? [],
                  );
                  final createdAt = DateTime.parse(notification['created_at']);

                  return Dismissible(
                    key: Key(notification['id']),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.delete, color: Colors.white),
                    ),
                    onDismissed: (direction) {
                      _deleteNotification(notification['id'], index);
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: isUnread
                            ? DarkThemeColors.surface
                            : Colors.black,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isUnread
                              ? DarkThemeColors.primary100.withOpacity(0.3)
                              : DarkThemeColors.border,
                        ),
                      ),
                      child: InkWell(
                        onTap: () =>
                            _handleNotificationTap(notification, index),
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Icon
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: _getNotificationColor(
                                    type,
                                  ).withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  _getNotificationIcon(type),
                                  color: _getNotificationColor(type),
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 12),

                              // Content
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            notification['title'],
                                            style: AppTextStyles.bodyLarge
                                                .copyWith(
                                                  color: Colors.white,
                                                  fontWeight: isUnread
                                                      ? FontWeight.bold
                                                      : FontWeight.w600,
                                                ),
                                          ),
                                        ),
                                        if (isUnread)
                                          Container(
                                            width: 8,
                                            height: 8,
                                            decoration: const BoxDecoration(
                                              color: DarkThemeColors.primary100,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      notification['body'],
                                      style: AppTextStyles.bodyMedium.copyWith(
                                        color: DarkThemeColors.textSecondary,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.access_time,
                                          size: 12,
                                          color: DarkThemeColors.textSecondary,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          timeago.format(createdAt),
                                          style: TextStyle(
                                            color:
                                                DarkThemeColors.textSecondary,
                                            fontSize: 11,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        ...channels.map(
                                          (channel) => Padding(
                                            padding: const EdgeInsets.only(
                                              right: 4,
                                            ),
                                            child: _buildChannelBadge(channel),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}
