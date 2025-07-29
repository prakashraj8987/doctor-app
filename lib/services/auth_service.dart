import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/doctor.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  User? _user;
  Doctor? _doctor;
  bool _isLoading = false;
  String _errorMessage = '';

  User? get user => _user;
  Doctor? get doctor => _doctor;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;
  bool get isAuthenticated => _user != null && _doctor != null;

  AuthService() {
    _auth.authStateChanges().listen(_onAuthStateChanged);
  }

  Future<void> _onAuthStateChanged(User? user) async {
    _user = user;
    if (user != null) {
      await _loadDoctorProfile();
    } else {
      _doctor = null;
    }
    notifyListeners();
  }

  Future<void> _loadDoctorProfile() async {
    if (_user == null) return;
    
    try {
      final doc = await _firestore.collection('doctors').doc(_user!.uid).get();
      if (doc.exists) {
        _doctor = Doctor.fromMap(doc.data()!, doc.id);
      }
    } catch (e) {
      print('Error loading doctor profile: $e');
    }
  }

  Future<bool> signInWithEmailPassword(String email, String password) async {
    try {
      _setLoading(true);
      _clearError();
      
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      if (credential.user != null) {
        await _loadDoctorProfile();
        if (_doctor == null) {
          _setError('Doctor profile not found. Please contact admin.');
          await signOut();
          return false;
        }
        if (!_doctor!.isActive) {
          _setError('Your account is not active. Please contact admin.');
          await signOut();
          return false;
        }
        return true;
      }
      return false;
    } on FirebaseAuthException catch (e) {
      _setError(_getAuthErrorMessage(e.code));
      return false;
    } catch (e) {
      _setError('An unexpected error occurred. Please try again.');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
      _user = null;
      _doctor = null;
      notifyListeners();
    } catch (e) {
      print('Error signing out: $e');
    }
  }

  Future<bool> updateOnlineStatus(bool isOnline) async {
    try {
      if (_user == null || _doctor == null) return false;
      
      await _firestore.collection('doctors').doc(_user!.uid).update({
        'isOnline': isOnline,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      });
      
      await _loadDoctorProfile();
      return true;
    } catch (e) {
      print('Error updating online status: $e');
      return false;
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
    _errorMessage = '';
    notifyListeners();
  }

  String _getAuthErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No doctor found with this email address.';
      case 'wrong-password':
        return 'Incorrect password.';
      case 'invalid-email':
        return 'Invalid email address.';
      default:
        return 'Authentication failed. Please try again.';
    }
  }
}