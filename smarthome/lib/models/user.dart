class User {
  final String username;
  final String email;
  final String phone;

  const User({
    required this.username,
    required this.email,
    required this.phone,
  });

  factory User.fromJson(Map<String, dynamic> json) => User(
        username: json['username'] as String,
        email: json['email'] as String? ?? '',
        phone: json['phone'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {
        'username': username,
        'email': email,
        'phone': phone,
      };

  User copyWith({String? username, String? email, String? phone}) => User(
        username: username ?? this.username,
        email: email ?? this.email,
        phone: phone ?? this.phone,
      );
}
