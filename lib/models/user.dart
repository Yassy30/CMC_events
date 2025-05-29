class User {
  final String id;
  final String username;
  final String email;
  final String? profileImageUrl;
  final List<String> following;
  final List<String> followers;
  final List<String> savedEvents;
  final List<String> attendedEvents;

  User({
    required this.id,
    required this.username,
    required this.email,
    this.profileImageUrl,
    this.following = const [],
    this.followers = const [],
    this.savedEvents = const [],
    this.attendedEvents = const [],
  });
}