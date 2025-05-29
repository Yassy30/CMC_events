class Follow {
  final String followerId;
  final String followedId;
  final DateTime createdAt;

  Follow({
    required this.followerId,
    required this.followedId,
    required this.createdAt,
  });

  factory Follow.fromMap(Map<String, dynamic> data) {
    return Follow(
      followerId: data['follower_id'],
      followedId: data['followed_id'],
      createdAt: DateTime.parse(data['created_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'follower_id': followerId,
      'followed_id': followedId,
      'created_at': createdAt.toIso8601String(),
    };
  }
}