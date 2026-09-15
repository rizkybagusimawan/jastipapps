class UserProfile {
  final String id;
  final String email;
  final String fullName;
  final String? phoneNumber;
  final String role;

  UserProfile({
    required this.id,
    required this.email,
    required this.fullName,
    this.phoneNumber,
    required this.role,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'],
      email: json['email'],
      fullName: json['fullName'],
      phoneNumber: json['phoneNumber'],
      role: json['role'] ?? 'user',
    );
  }

  bool get isAdmin => role == 'admin';
}
