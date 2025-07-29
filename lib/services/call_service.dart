import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import '../models/call_model.dart';

class CallService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  RtcEngine? _engine;
  
  CallModel? _currentCall;
  bool _isInCall = false;
  int _callDuration = 0;
  bool _isMuted = false;
  bool _isCameraOff = false;
  
  CallModel? get currentCall => _currentCall;
  bool get isInCall => _isInCall;
  int get callDuration => _callDuration;
  bool get isMuted => _isMuted;
  bool get isCameraOff => _isCameraOff;

  // Initialize Agora Engine
  Future<void> initializeAgora() async {
    _engine = createAgoraRtcEngine();
    await _engine!.initialize(const RtcEngineContext(
      appId: 'YOUR_AGORA_APP_ID', // Replace with your Agora App ID
    ));
    
    _engine!.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
          print('Joined channel: ${connection.channelId}');
        },
        onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
          print('User joined: $remoteUid');
        },
        onUserOffline: (RtcConnection connection, int remoteUid, UserOfflineReasonType reason) {
          print('User offline: $remoteUid');
        },
      ),
    );
  }

  // Accept incoming call
  Future<void> acceptCall(String callId) async {
    try {
      await _firestore.collection('calls').doc(callId).update({
        'status': 'ongoing',
        'startedAt': DateTime.now().millisecondsSinceEpoch,
      });
      
      final call = await getCall(callId);
      if (call != null && call.agoraChannelId != null) {
        await _joinChannel(call.agoraChannelId!);
        _currentCall = call;
        _isInCall = true;
        notifyListeners();
      }
    } catch (e) {
      print('Error accepting call: $e');
    }
  }

  // Reject call
  Future<void> rejectCall(String callId) async {
    try {
      await _firestore.collection('calls').doc(callId).update({
        'status': 'rejected',
        'endedAt': DateTime.now().millisecondsSinceEpoch,
      });
    } catch (e) {
      print('Error rejecting call: $e');
    }
  }

  // End call
  Future<void> endCall() async {
    if (_currentCall == null) return;
    
    try {
      await _firestore.collection('calls').doc(_currentCall!.id).update({
        'status': 'completed',
        'endedAt': DateTime.now().millisecondsSinceEpoch,
        'durationSeconds': _callDuration,
      });
      
      await _leaveChannel();
      _currentCall = null;
      _isInCall = false;
      _callDuration = 0;
      notifyListeners();
    } catch (e) {
      print('Error ending call: $e');
    }
  }

  // Get call details
  Future<CallModel?> getCall(String callId) async {
    try {
      final doc = await _firestore.collection('calls').doc(callId).get();
      if (doc.exists) {
        return CallModel.fromMap(doc.data()!, doc.id);
      }
    } catch (e) {
      print('Error getting call: $e');
    }
    return null;
  }

  // Toggle mute
  void toggleMute() {
    _isMuted = !_isMuted;
    _engine?.muteLocalAudioStream(_isMuted);
    notifyListeners();
  }

  // Toggle camera
  void toggleCamera() {
    _isCameraOff = !_isCameraOff;
    _engine?.muteLocalVideoStream(_isCameraOff);
    notifyListeners();
  }

  Future<void> _joinChannel(String channelId) async {
    await _engine?.joinChannel(
      token: '',
      channelId: channelId,
      uid: 0,
      options: const ChannelMediaOptions(),
    );
  }

  Future<void> _leaveChannel() async {
    await _engine?.leaveChannel();
  }

  @override
  void dispose() {
    _engine?.release();
    super.dispose();
  }
}