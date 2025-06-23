class UserProfile {
  final String id;
  final String email;
  final String username;
  final String? profilePicture;
  final String? bio;
  final String role;
  final DateTime createdAt;

  UserProfile({
    required this.id,
    required this.email,
    required this.username,
    this.profilePicture,
    this.bio,
    required this.role,
    required this.createdAt,
  });

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      id: map['id'],
      email: map['email'],
      username: map['username'],
      profilePicture: map['profile_picture'],
      bio: map['bio'],
      role: map['role'] ?? 'stagiaire',
      createdAt: DateTime.parse(map['created_at']),
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
      'created_at': createdAt.toIso8601String(),
    };
  }

  // Create a copy of this UserProfile with optional changed fields
  UserProfile copyWith({
    String? username,
    String? profilePicture,
    String? bio,
  }) {
    return UserProfile(
      id: this.id,
      email: this.email,
      username: username ?? this.username,
      profilePicture: profilePicture ?? this.profilePicture,
      bio: bio ?? this.bio,
      role: this.role,
      createdAt: this.createdAt,
    );
  }
}