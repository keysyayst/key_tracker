class ProfileModel {
  final String id;
  final String? displayName;
  final String? avatarUrl;
  final String? timezone;

  ProfileModel({
    required this.id,
    this.displayName,
    this.avatarUrl,
    this.timezone,
  });

  factory ProfileModel.fromMap(Map<String, dynamic> m) {
    return ProfileModel(
      id: m['id'] as String,
      displayName: m['display_name'] as String?,
      avatarUrl: m['avatar_url'] as String?,
      timezone: m['timezone'] as String?,
    );
  }

  Map<String, dynamic> toUpsertMap() {
    return {
      'id': id,
      'display_name': displayName,
      'avatar_url': avatarUrl,
      'timezone': timezone,
      'updated_at': DateTime.now().toIso8601String(),
    };
  }
}
