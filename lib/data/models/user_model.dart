import 'dart:math';

class User {
  final String id;
  final String name;
  final String email;
  final String? avatarUrl;

  User({
    required this.id,
    required this.name,
    required this.email,
    this.avatarUrl,
  });

  User copyWith({String? id, String? name, String? email, String? avatarUrl}) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }
}

// Dummy users data
class DummyUsers {
  static final List<User> users = [
    User(
      id: '1',
      name: 'Alice Johnson',
      email: 'alice@example.com',
      avatarUrl: null, // Will use initials
    ),
    User(id: '2', name: 'Bob Smith', email: 'bob@example.com', avatarUrl: null),
    User(
      id: '3',
      name: 'Charlie Brown',
      email: 'charlie@example.com',
      avatarUrl: null,
    ),
    User(
      id: '4',
      name: 'Diana Prince',
      email: 'diana@example.com',
      avatarUrl: null,
    ),
    User(
      id: '5',
      name: 'Edward Norton',
      email: 'edward@example.com',
      avatarUrl: null,
    ),
  ];

  static User? getUserById(String id) {
    return users.where((user) => user.id == id).firstOrNull;
  }

  static String getInitials(String name) {
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    } else if (parts.isNotEmpty) {
      return parts[0].substring(0, min(2, parts[0].length)).toUpperCase();
    }
    return 'U';
  }
}
