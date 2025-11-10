import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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
    _authStateSubscription = _auth.authStateChanges().listen((User? user) {
      _user = user;
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

    final userData = {
      'uid': user.uid,
      'displayName': name,
      'email': email,
      'photoUrl': null,
      'bio': "",
      'skills': [],
      'createdAt': FieldValue.serverTimestamp(),
      'followersCount': 0,
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

  Future<bool> sendPasswordReset(String email) async {
    _setLoading(true);
    _setError(null);
    try {
      await _auth.sendPasswordResetEmail(email: email);
      _setLoading(false);
      return true;
    } on FirebaseAuthException catch (e) {
      _setError(_translateAuthError(e.code));
      _setLoading(false);
      return false;
    } catch (e) {
      _setError("Ocurrió un error inesperado.");
      _setLoading(false);
      return false;
    }
  }

  Future<void> signOut() async {
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
        'photoUrl': newPhotoUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      });

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

      await _firestore.collection('users').doc(_user!.uid).update(data);

      if (data.containsKey('displayName')) {
        await _user!.updateDisplayName(data['displayName']);
      }
      if (data.containsKey('photoUrl')) {
        await _user!.updatePhotoURL(data['photoUrl']);
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
      default:
        return 'Error de autenticación: $code';
    }
  }
}
