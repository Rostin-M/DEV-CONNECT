import 'package:cloud_firestore/cloud_firestore.dart';

class ProjectModel {
  final String id;
  final String title;
  final String description;
  final List<String> tags;
  final String githubLink;
  final List<Map<String, dynamic>> screenshots;
  final String authorId;
  final String authorName;
  final String authorAvatar;
  final Timestamp createdAt;
  final Timestamp updatedAt;
  final List<String> likes;
  final int commentsCount;
  final String status;

  ProjectModel({
    required this.id,
    required this.title,
    required this.description,
    required this.tags,
    required this.githubLink,
    required this.screenshots,
    required this.authorId,
    required this.authorName,
    required this.authorAvatar,
    required this.createdAt,
    required this.updatedAt,
    this.likes = const [],
    this.commentsCount = 0,
    this.status = 'public',
  });

  factory ProjectModel.fromMap(Map<String, dynamic> data, String documentId) {
    return ProjectModel(
      id: documentId,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      tags: List<String>.from(data['tags'] ?? []),
      githubLink: data['githubLink'] ?? '',
      screenshots: List<Map<String, dynamic>>.from(data['screenshots'] ?? []),
      authorId: data['authorId'] ?? '',
      authorName: data['authorName'] ?? '',
      authorAvatar: data['authorAvatar'] ?? '',
      createdAt: data['createdAt'] ?? Timestamp.now(),
      updatedAt: data['updatedAt'] ?? Timestamp.now(),
      likes: List<String>.from(data['likes'] ?? []),
      commentsCount: data['commentsCount'] ?? 0,
      status: data['status'] ?? 'draft',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'tags': tags,
      'githubLink': githubLink,
      'screenshots': screenshots,
      'authorId': authorId,
      'authorName': authorName,
      'authorAvatar': authorAvatar,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'likes': likes,
      'commentsCount': commentsCount,
      'status': status,
    };
  }

  ProjectModel copyWith({String? id, String? title, List<String>? likes}) {
    return ProjectModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description,
      tags: tags,
      githubLink: githubLink,
      screenshots: screenshots,
      authorId: authorId,
      authorName: authorName,
      authorAvatar: authorAvatar,
      createdAt: createdAt,
      updatedAt: updatedAt,
      likes: likes ?? this.likes,
      commentsCount: commentsCount,
      status: status,
    );
  }
}
