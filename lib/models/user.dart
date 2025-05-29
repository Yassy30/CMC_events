class User {
  final String id;
  final String email;
  final String username;
  final String role;
  final String? profilePicture;
  final String? bio;

  User({
    required this.id,
    required this.email,
    required this.username,
    required this.role,
    this.profilePicture,
    this.bio,
  });

  factory User.fromMap(Map<String, dynamic> data) {
    return User(
      id: data['id'],
      email: data['email'],
      username: data['username'],
      role: data['role'],
      profilePicture: data['profile_picture'],
      bio: data['bio'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'username': username,
      'role': role,
      'profile_picture': profilePicture,
      'bio': bio,
    };
  }
}