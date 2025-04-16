// models/user_model.dart (updated)
class User {
  final String id;
  final String name;
  final String email;
  final String password; // In a real app, this should be hashed
  final DateTime createdAt;
  final bool isGuest;
  final String? profileImagePath; // Added profile image path

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.password,
    required this.createdAt,
    this.isGuest = false,
    this.profileImagePath,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'password': password,
      'created_at': createdAt.millisecondsSinceEpoch,
      'profile_image_path': profileImagePath,
      'is_guest': isGuest ? 1 : 0,
    };
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      password: json['password'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['created_at']),
      isGuest: json['is_guest'] == 1,
      profileImagePath: json['profile_image_path'],
    );
  }

  // Copy with method to create a new instance with updated fields
  User copyWith({
    String? id,
    String? name,
    String? email,
    String? password,
    DateTime? createdAt,
    String? profileImagePath,
    bool? isGuest,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      password: password ?? this.password,
      createdAt: createdAt ?? this.createdAt,
      isGuest: isGuest ?? this.isGuest,
      profileImagePath: profileImagePath ?? this.profileImagePath,
    );
  }

  // Get initial for avatar
  String get initial {
    if (name.isEmpty) return '?';
    return name[0].toUpperCase();
  }
}
