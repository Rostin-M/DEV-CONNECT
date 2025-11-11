import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dev_connect/services/fcm_service.dart';

class AuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FCMService _fcmService = FCMService();

  User? _user;
  User? get user => _user;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  AuthProvider() {
    _listenToAuthChanges();
  }

  StreamSubscription<User?>? _authStateSubscription;

  void _listenToAuthChanges() {
    _authStateSubscription = _auth.authStateChanges().listen((
      User? user,
    ) async {
      _user = user;

      if (user != null) {
        await _fcmService.saveFCMToken(user.uid);
      }

      notifyListeners();
    });
  }

  @override
  void dispose() {
    _authStateSubscription?.cancel();
    super.dispose();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? message) {
    _errorMessage = message;
    notifyListeners();
  }

  Future<bool> signUp(String name, String email, String password) async {
    _setLoading(true);
    _setError(null);
    try {
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);

      _user = userCredential.user;

      if (_user != null) {
        await _user!.updateDisplayName(name);

        await _createFirestoreUser(_user!, name, email);

        _setLoading(false);
        return true;
      }
      _setLoading(false);
      return false;
    } on FirebaseAuthException catch (e) {
      _setError(_translateAuthError(e.code));
      _setLoading(false);
      return false;
    } catch (e) {
      _setError("Ocurrió un error inesperado. Inténtalo de nuevo.");
      _setLoading(false);
      return false;
    }
  }

  Future<void> _createFirestoreUser(
    User user,
    String name,
    String email,
  ) async {
    final userRef = _firestore.collection('users').doc(user.uid);

    final defaultAvatar =
        'https://ui-avatars.com/api/?name=${Uri.encodeComponent(name)}&background=random&size=200&bold=true';

    final userData = {
      'uid': user.uid,
      'displayName': name,
      'email': email,
      'photoURL': defaultAvatar,
      'bio': "",
      'skills': [],
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'followersCount': 0,
      'fcmToken': null,
    };

    await userRef.set(userData);
  }

  Future<bool> signIn(String email, String password) async {
    _setLoading(true);
    _setError(null);
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      _setLoading(false);
      return true;
    } on FirebaseAuthException catch (e) {
      _setError(_translateAuthError(e.code));
      _setLoading(false);
      return false;
    } catch (e) {
      _setError("Ocurrió un error inesperado. Inténtalo de nuevo.");
      _setLoading(false);
      return false;
    }
  }

  Future<bool> isEmailRegistered(String email) async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .where('email', isEqualTo: email.trim().toLowerCase())
          .limit(1)
          .get();

      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      debugPrint('Error al verificar email: $e');
      return false;
    }
  }

  Future<bool> sendPasswordReset(String email) async {
    _setLoading(true);
    _setError(null);

    try {
      final emailLowerCase = email.trim().toLowerCase();
      final isRegistered = await isEmailRegistered(emailLowerCase);

      if (!isRegistered) {
        _setError(
          'Este correo electrónico no está registrado. Por favor, verifica e intenta nuevamente.',
        );
        _setLoading(false);
        return false;
      }

      await _auth.sendPasswordResetEmail(email: emailLowerCase);
      _setLoading(false);
      return true;
    } on FirebaseAuthException catch (e) {
      _setError(_translateAuthError(e.code));
      _setLoading(false);
      return false;
    } catch (e) {
      _setError("Ocurrió un error inesperado. Por favor, intenta nuevamente.");
      _setLoading(false);
      return false;
    }
  }

  Future<void> signOut() async {
    if (_user != null) {
      await _fcmService.deleteFCMToken(_user!.uid);
    }

    await _auth.signOut();
    _user = null;
    notifyListeners();
  }

  Future<bool> updateDisplayName(String newDisplayName) async {
    if (_user == null) return false;

    _setLoading(true);
    _setError(null);

    try {
      await _user!.updateDisplayName(newDisplayName);

      await _firestore.collection('users').doc(_user!.uid).update({
        'displayName': newDisplayName,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await _updateUserDataInProjects(_user!.uid, {
        'authorName': newDisplayName,
      });

      await _updateUserDataInChats(_user!.uid, {'displayName': newDisplayName});

      await _user!.reload();
      _user = _auth.currentUser;

      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Error al actualizar el nombre: $e');
      _setLoading(false);
      return false;
    }
  }

  Future<bool> updatePhotoUrl(String newPhotoUrl) async {
    if (_user == null) return false;

    _setLoading(true);
    _setError(null);

    try {
      await _user!.updatePhotoURL(newPhotoUrl);

      await _firestore.collection('users').doc(_user!.uid).update({
        'photoURL': newPhotoUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await _updateUserDataInProjects(_user!.uid, {
        'authorAvatar': newPhotoUrl,
      });

      await _updateUserDataInChats(_user!.uid, {'photoURL': newPhotoUrl});

      await _user!.reload();
      _user = _auth.currentUser;

      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Error al actualizar la foto: $e');
      _setLoading(false);
      return false;
    }
  }

  Future<bool> updateUserProfile(Map<String, dynamic> data) async {
    if (_user == null) return false;

    _setLoading(true);
    _setError(null);

    try {
      data['updatedAt'] = FieldValue.serverTimestamp();

      if (data.containsKey('photoUrl')) {
        data['photoURL'] = data['photoUrl'];
        data.remove('photoUrl');
      }

      await _firestore.collection('users').doc(_user!.uid).update(data);

      if (data.containsKey('displayName')) {
        await _user!.updateDisplayName(data['displayName']);
        await _updateUserDataInProjects(_user!.uid, {
          'authorName': data['displayName'],
        });
        await _updateUserDataInChats(_user!.uid, {
          'displayName': data['displayName'],
        });
      }

      if (data.containsKey('photoURL')) {
        await _user!.updatePhotoURL(data['photoURL']);
        await _updateUserDataInProjects(_user!.uid, {
          'authorAvatar': data['photoURL'],
        });
        await _updateUserDataInChats(_user!.uid, {
          'photoURL': data['photoURL'],
        });
      }

      await _user!.reload();
      _user = _auth.currentUser;

      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Error al actualizar el perfil: $e');
      _setLoading(false);
      return false;
    }
  }

  Future<void> _updateUserDataInProjects(
    String userId,
    Map<String, dynamic> updates,
  ) async {
    try {
      final projectsSnapshot = await _firestore
          .collection('projects')
          .where('authorId', isEqualTo: userId)
          .get();

      final batch = _firestore.batch();
      for (var doc in projectsSnapshot.docs) {
        batch.update(doc.reference, updates);
      }
      await batch.commit();
    } catch (e) {
      debugPrint('Error actualizando proyectos: $e');
    }
  }

  Future<void> _updateUserDataInChats(
    String userId,
    Map<String, dynamic> updates,
  ) async {
    try {
      final chatsSnapshot = await _firestore
          .collection('chats')
          .where('participants', arrayContains: userId)
          .get();

      final batch = _firestore.batch();
      for (var doc in chatsSnapshot.docs) {
        batch.update(doc.reference, {
          'participantsData.$userId.${updates.keys.first}':
              updates.values.first,
        });
      }
      await batch.commit();
    } catch (e) {
      debugPrint('Error actualizando chats: $e');
    }
  }

  String _translateAuthError(String code) {
    switch (code) {
      case 'invalid-email':
        return 'El formato del correo electrónico no es válido.';
      case 'user-not-found':
        return 'No se encontró un usuario con ese correo electrónico.';
      case 'wrong-password':
        return 'La contraseña es incorrecta.';
      case 'email-already-in-use':
        return 'El correo electrónico ya está en uso por otra cuenta.';
      case 'weak-password':
        return 'La contraseña es demasiado débil.';
      case 'user-disabled':
        return 'Este usuario ha sido deshabilitado.';
      case 'too-many-requests':
        return 'Demasiados intentos. Por favor, intenta más tarde.';
      case 'operation-not-allowed':
        return 'Esta operación no está permitida.';
      case 'network-request-failed':
        return 'Error de red. Verifica tu conexión a internet.';
      default:
        return 'Error de autenticación: $code';
    }
  }
}
