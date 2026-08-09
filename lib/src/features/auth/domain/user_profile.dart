class UserProfile {
  const UserProfile({
    required this.id,
    required this.locale,
    this.displayName,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      displayName: json['display_name'] as String?,
      locale: json['locale'] as String? ?? 'de',
    );
  }

  final String id;
  final String? displayName;
  final String locale;

  bool get hasCompletedOnboarding => displayName?.trim().isNotEmpty ?? false;
}
