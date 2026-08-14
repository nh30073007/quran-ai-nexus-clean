class User {
  final String? id;
  final String username;
  final String email;
  final String? token;
  final bool isAdmin;

  User({
    this.id,
    required this.username,
    required this.email,
    this.token,
    this.isAdmin = false,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id']?.toString(),
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      token: json['token'],
      isAdmin: json['is_admin'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'token': token,
      'is_admin': isAdmin,
    };
  }

  User copyWith({
    String? id,
    String? username,
    String? email,
    String? token,
    bool? isAdmin,
  }) {
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      token: token ?? this.token,
      isAdmin: isAdmin ?? this.isAdmin,
    );
  }
}