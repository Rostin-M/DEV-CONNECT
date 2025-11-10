import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String displayName;
  final String email;
  final String? photoURL;
  final String bio;
  final List<String> skills;
  final Timestamp createdAt;
  final Timestamp? updatedAt;
  final int followersCount;

  UserModel({
    required this.uid,
    required this.displayName,
    required this.email,
    this.photoURL,
    this.bio = '',
    this.skills = const [],
    required this.createdAt,
    this.updatedAt,
    this.followersCount = 0,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return UserModel(
      uid: doc.id,
      displayName: data['displayName'] ?? '',
      email: data['email'] ?? '',
      photoURL: data['photoURL'] ?? data['photoUrl'],
      bio: data['bio'] ?? '',
      skills: List<String>.from(data['skills'] ?? []),
      createdAt: data['createdAt'] ?? Timestamp.now(),
      updatedAt: data['updatedAt'],
      followersCount: data['followersCount'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'displayName': displayName,
      'email': email,
      'photoURL': photoURL,
      'bio': bio,
      'skills': skills,
      'createdAt': createdAt,
      'updatedAt': updatedAt ?? FieldValue.serverTimestamp(),
      'followersCount': followersCount,
    };
  }

  UserModel copyWith({
    String? displayName,
    String? email,
    String? photoURL,
    String? bio,
    List<String>? skills,
    Timestamp? updatedAt,
    int? followersCount,
  }) {
    return UserModel(
      uid: uid,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      photoURL: photoURL ?? this.photoURL,
      bio: bio ?? this.bio,
      skills: skills ?? this.skills,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      followersCount: followersCount ?? this.followersCount,
    );
  }

  String getPhotoURL() {
    if (photoURL != null && photoURL!.isNotEmpty) {
      return photoURL!;
    }
    return 'https://ui-avatars.com/api/?name=${Uri.encodeComponent(displayName)}&background=random&size=200&bold=true';
  }
}
