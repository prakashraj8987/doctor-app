import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AgoraService {
  // Ensure Firebase user is authenticated (anonymous if needed)
  static Future<User> _ensureFirebaseUser() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print('⚠️ No Firebase user found. Signing in anonymously...');
      UserCredential credential = await FirebaseAuth.instance.signInAnonymously();
      user = credential.user;
      print('✅ Signed in anonymously as: ${user?.uid}');
    } else {
      print('✅ Firebase user already authenticated: ${user.uid}');
    }
    return user!;
  }

  // Generate video call token using your Firebase Function
  static Future<Map<String, dynamic>> generateToken({
    required String channelName,
    required int uid,
  }) async {
    try {
      print('🔄 Generating Agora token for channel: $channelName');

      // ✅ Ensure user is authenticated
      await _ensureFirebaseUser();

      final callable = FirebaseFunctions.instanceFor(region: 'us-central1')
          .httpsCallable('generateAgoraToken');

      final result = await callable.call({
        'channelName': channelName,
        'uid': uid,
      });

      print('✅ Agora token generated successfully');
      return Map<String, dynamic>.from(result.data);

    } catch (e) {
      print('❌ Error generating token: $e');
      throw Exception('Failed to generate token: $e');
    }
  }

  // Send video call notification using your Firebase Function
  static Future<void> sendVideoCallNotification({
    required String targetUserId,
    required String callerName,
    required String channelId,
    required String agoraToken,
    required int uid,
  }) async {
    try {
      print('📤 Sending video call notification to: $targetUserId');

      // ✅ Ensure user is authenticated
      await _ensureFirebaseUser();

      final callable = FirebaseFunctions.instanceFor(region: 'us-central1')
          .httpsCallable('sendVideoCallNotification');

      await callable.call({
        'targetUserId': targetUserId,
        'callerName': callerName,
        'channelId': channelId,
        'agoraToken': agoraToken,
        'uid': uid,
      });

      print('✅ Video call notification sent successfully');

    } catch (e) {
      print('❌ Error sending notification: $e');
      throw Exception('Failed to send notification: $e');
    }
  }
}
