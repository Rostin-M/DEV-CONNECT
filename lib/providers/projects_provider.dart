import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dev_connect/data/models/project_model.dart';
import 'package:dev_connect/services/cloudinary_service.dart';

class ProjectsProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final CloudinaryService _cloudinaryService = CloudinaryService();

  List<ProjectModel> _projects = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  DocumentSnapshot? _lastDocument;
  String? _error;
  final int _limit = 10;

  List<ProjectModel> get projects => _projects;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  bool get hasMore => _hasMore;
  String? get error => _error;

  Future<void> createProject(
    ProjectModel project,
    List<File> screenshotFiles,
  ) async {
    if (screenshotFiles.isEmpty) {
      throw Exception("Se requiere al menos un pantallazo.");
    }

    try {
      final List<Map<String, dynamic>> uploadedScreenshots = [];
      await Future.wait(
        screenshotFiles.asMap().entries.map((entry) async {
          int index = entry.key;
          File file = entry.value;
          final uploadResult = await _cloudinaryService.uploadScreenshot(file);
          final caption = project.screenshots[index]['caption'] ?? '';
          final screenshotId = _firestore.collection('projects').doc().id;
          uploadedScreenshots.add({
            'id': screenshotId,
            'url': uploadResult['url']!,
            'publicId': uploadResult['publicId']!,
            'caption': caption,
            'createdAt': Timestamp.now(),
          });
        }),
      );

      final projectRef = _firestore.collection('projects').doc();
      final finalProject = ProjectModel(
        id: projectRef.id,
        title: project.title,
        description: project.description,
        tags: project.tags,
        githubLink: project.githubLink,
        screenshots: uploadedScreenshots,
        authorId: project.authorId,
        authorName: project.authorName,
        authorAvatar: project.authorAvatar,
        createdAt: Timestamp.now(),
        updatedAt: Timestamp.now(),
        likes: const [],
        commentsCount: 0,
        status: 'public',
      );

      final projectData = finalProject.toMap();
      projectData['createdAt'] = FieldValue.serverTimestamp();
      projectData['updatedAt'] = FieldValue.serverTimestamp();

      await projectRef.set(projectData);
    } catch (e) {
      throw Exception('Fallo al crear el proyecto: ${e.toString()}');
    }
  }

  Query _buildBaseQuery() {
    return _firestore
        .collection('projects')
        .where('status', isEqualTo: 'public')
        .orderBy('createdAt', descending: true)
        .limit(_limit);
  }

  Future<void> fetchInitialProjects() async {
    if (_isLoading) return;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final snapshot = await _buildBaseQuery().get();
      if (snapshot.docs.isNotEmpty) {
        _projects = snapshot.docs
            .map(
              (doc) => ProjectModel.fromMap(
                doc.data() as Map<String, dynamic>,
                doc.id,
              ),
            )
            .toList();
        _lastDocument = snapshot.docs.last;
        _hasMore = _projects.length == _limit;
      } else {
        _projects = [];
        _lastDocument = null;
        _hasMore = false;
      }
    } catch (e) {
      _error = "Error al cargar los proyectos: ${e.toString()}";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchMoreProjects() async {
    if (_isLoadingMore || !_hasMore || _lastDocument == null) return;
    _isLoadingMore = true;
    _error = null;
    notifyListeners();

    try {
      final query = _buildBaseQuery().startAfterDocument(_lastDocument!);
      final snapshot = await query.get();

      if (snapshot.docs.isNotEmpty) {
        final moreProjects = snapshot.docs
            .map(
              (doc) => ProjectModel.fromMap(
                doc.data() as Map<String, dynamic>,
                doc.id,
              ),
            )
            .toList();
        _projects.addAll(moreProjects);
        _lastDocument = snapshot.docs.last;
        _hasMore = moreProjects.length == _limit;
      } else {
        _hasMore = false;
      }
    } catch (e) {
      _error = "Error al cargar más proyectos: ${e.toString()}";
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  Future<void> refreshProjects() async {
    _lastDocument = null;
    _hasMore = true;
    await fetchInitialProjects();
  }

  Future<void> toggleLike(String projectId, String userId) async {
    final index = _projects.indexWhere((p) => p.id == projectId);
    if (index == -1) return;

    final project = _projects[index];
    final bool isLiked = project.likes.contains(userId);

    List<String> updatedLikes = List.from(project.likes);
    if (isLiked) {
      updatedLikes.remove(userId);
    } else {
      updatedLikes.add(userId);
    }

    _projects[index] = project.copyWith(likes: updatedLikes);
    notifyListeners();

    try {
      final projectRef = _firestore.collection('projects').doc(projectId);
      if (isLiked) {
        await projectRef.update({
          'likes': FieldValue.arrayRemove([userId]),
        });
      } else {
        await projectRef.update({
          'likes': FieldValue.arrayUnion([userId]),
        });
      }
    } catch (e) {
      _projects[index] = project;
      notifyListeners();
    }
  }
}
