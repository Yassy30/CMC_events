class User {
  final String id;
  final String email;
  final String username;
  final String? profilePicture;
  final String? bio;
  final String role;
  final DateTime? createdAt;

  User({
    required this.id,
    required this.email,
    required this.username,
    this.profilePicture,
    this.bio,
    this.role = 'stagiaire',
    this.createdAt,
  });

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'],
      email: map['email'],
      username: map['username'],
      profilePicture: map['profile_picture'],
      bio: map['bio'],
      role: map['role'] ?? 'stagiaire',
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'])
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'username': username,
      'profile_picture': profilePicture,
      'bio': bio,
      'role': role,
      'created_at': createdAt?.toIso8601String(),
    };
  }
}