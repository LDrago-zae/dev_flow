import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:dev_flow/data/models/user_model.dart' as app_models;

class UserRepository {
  final _supabase = Supabase.instance.client;

  /// Get all users from profiles table
  Future<List<app_models.User>> getUsers() async {
    try {
      final response = await _supabase
          .from('profiles')
          .select('id, name, email, avatar_url')
          .order('name');

      return (response as List)
          .map(
            (json) => app_models.User(
              id: json['id'] as String,
              name: json['name'] as String? ?? 'Unknown User',
              email: json['email'] as String? ?? '',
              avatarUrl: json['avatar_url'] as String?,
            ),
          )
          .toList();
    } catch (e) {
      print('Error fetching users: $e');
      return [];
    }
  }

  /// Get a single user by ID
  Future<app_models.User?> getUserById(String id) async {
    try {
      final response = await _supabase
          .from('profiles')
          .select('id, name, email, avatar_url')
          .eq('id', id)
          .single();

      return app_models.User(
        id: response['id'] as String,
        name: response['name'] as String? ?? 'Unknown User',
        email: response['email'] as String? ?? '',
        avatarUrl: response['avatar_url'] as String?,
      );
    } catch (e) {
      print('Error fetching user: $e');
      return null;
    }
  }

  /// Stream of users for real-time updates
  Stream<List<app_models.User>> watchUsers() {
    return _supabase
        .from('profiles')
        .stream(primaryKey: ['id'])
        .order('name')
        .map(
          (data) => data
              .map(
                (json) => app_models.User(
                  id: json['id'] as String,
                  name: json['name'] as String? ?? 'Unknown User',
                  email: json['email'] as String? ?? '',
                  avatarUrl: json['avatar_url'] as String?,
                ),
              )
              .toList(),
        );
  }
}
