import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/call_model.dart';

class DoctorService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  List<CallModel> _callHistory = [];
  Map<String, double> _earnings = {};
  bool _isLoading = false;
  
  List<CallModel> get callHistory => _callHistory;
  Map<String, double> get earnings => _earnings;
  bool get isLoading => _isLoading;

  // Load call history
  Future<void> loadCallHistory(String doctorId) async {
    try {
      _isLoading = true;
      notifyListeners();
      
      final snapshot = await _firestore
          .collection('calls')
          .where('doctorId', isEqualTo: doctorId)
          .orderBy('createdAt', descending: true)
          .limit(50)
          .get();
      
      _callHistory = snapshot.docs
          .map((doc) => CallModel.fromMap(doc.data(), doc.id))
          .toList();
      
      _calculateEarnings();
      
    } catch (e) {
      print('Error loading call history: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Calculate earnings
  void _calculateEarnings() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    double todayEarnings = 0;
    double monthEarnings = 0;
    double totalEarnings = 0;
    double pendingEarnings = 0;
    
    for (final call in _callHistory) {
      if (call.status == CallStatus.completed) {
        final callDate = DateTime(
          call.createdAt.year,
          call.createdAt.month,
          call.createdAt.day,
        );
        
        totalEarnings += call.consultationFee;
        
        if (!call.isPaid) {
          pendingEarnings += call.consultationFee;
        }
        
        if (callDate == today) {
          todayEarnings += call.consultationFee;
        }
        
        if (call.createdAt.month == now.month && call.createdAt.year == now.year) {
          monthEarnings += call.consultationFee;
        }
      }
    }
    
    _earnings = {
      'today': todayEarnings,
      'month': monthEarnings,
      'total': totalEarnings,
      'pending': pendingEarnings,
    };
  }

  // Get today's statistics
  Map<String, int> getTodayStats() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    int totalCalls = 0;
    int completedCalls = 0;
    int totalDuration = 0;
    
    for (final call in _callHistory) {
      final callDate = DateTime(
        call.createdAt.year,
        call.createdAt.month,
        call.createdAt.day,
      );
      
      if (callDate == today) {
        totalCalls++;
        totalDuration += call.durationSeconds;
        
        if (call.status == CallStatus.completed) {
          completedCalls++;
        }
      }
    }
    
    return {
      'totalCalls': totalCalls,
      'completedCalls': completedCalls,
      'totalDuration': totalDuration,
    };
  }

  // Listen to incoming calls
  Stream<List<CallModel>> getIncomingCallsStream(String doctorId) {
    return _firestore
        .collection('calls')
        .where('doctorId', isEqualTo: doctorId)
        .where('status', whereIn: ['waiting', 'ringing'])
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => CallModel.fromMap(doc.data(), doc.id))
            .toList());
  }
}