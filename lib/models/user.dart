class User {
  final String id;
  final String email;
  final String name;
  final String? profileId;
  final String? token;
  final List<String>? profilePictures;
  
  User({
    required this.id,
    required this.email,
    required this.name,
    this.profileId,
    this.token,
    this.profilePictures,
  });
  
  factory User.fromJson(Map<String, dynamic> json, {String? token}) {
    return User(
      id: json['id'],
      email: json['email'],
      name: json['name'] ?? '',
      profileId: json['profile_id'],
      token: token,
      profilePictures: json['profile_pictures'] != null 
          ? List<String>.from(json['profile_pictures'])
          : null,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'profile_id': profileId,
      'profile_pictures': profilePictures,
    };
  }
}