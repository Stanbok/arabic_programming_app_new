import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firebase_service.dart';
import '../models/user_model.dart';

class AuthProvider with ChangeNotifier {
  User? _user;
  bool _isLoading = false;
  String? _errorMessage;

  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _user != null;

  AuthProvider() {
    _initializeAuth();
  }

  void _initializeAuth() {
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      _user = user;
      notifyListeners();
    });
  }

  Future<bool> signIn(String email, String password) async {
    try {
      _setLoading(true);
      _clearError();
      
      final credential = await FirebaseService.signInWithEmailAndPassword(email, password);
      if (credential != null) {
        _user = credential.user;
        
        // Update last login time
        if (_user != null) {
          await FirebaseService.updateUserData(_user!.uid, {
            'lastLoginAt': FieldValue.serverTimestamp(),
          });
        }
        
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> register(String name, String email, String password) async {
    try {
      _setLoading(true);
      _clearError();
      
      final credential = await FirebaseService.createUserWithEmailAndPassword(email, password);
      if (credential != null) {
        _user = credential.user;
        
        // Create user document in Firestore
        final userModel = UserModel(
          id: _user!.uid,
          name: name,
          email: email,
          createdAt: DateTime.now(),
          lastLoginAt: DateTime.now(),
        );
        
        await FirebaseService.createUserDocument(userModel);
        
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> resetPassword(String email) async {
    try {
      _setLoading(true);
      _clearError();
      
      await FirebaseService.sendPasswordResetEmail(email);
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> signOut() async {
    try {
      await FirebaseService.signOut();
      _user = null;
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
