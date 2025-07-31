const functions = require('firebase-functions');
const admin = require('firebase-admin');
const { RtcTokenBuilder, RtcRole } = require('agora-access-token');

// Initialize Firebase (connects to your FactoDoctor database)
admin.initializeApp();

// 🔥 REPLACE WITH YOUR AGORA CREDENTIALS FROM STEP 1
const APP_ID = '06252062d2e34665b5b1151f36cdbdd6';                    // Put your App ID here
const APP_CERTIFICATE = '98ac19fb2c2042b6adf5af77378e81c9';  // Put your App Certificate here

// Function 1: Generate secure video call tokens
exports.generateAgoraToken = functions.https.onCall((data, context) => {
  // Check if user is logged in
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'You must be logged in');
  }

  const { channelName, uid } = data;
  
  // Check if channel name was provided
  if (!channelName) {
    throw new functions.https.HttpsError('invalid-argument', 'Channel name is required');
  }

  try {
    // Generate the video call token
    const userUid = uid || 0;
    const role = RtcRole.PUBLISHER;
    const expirationTimeInSeconds = 3600; // Token lasts 1 hour
    const currentTimestamp = Math.floor(Date.now() / 1000);
    const privilegeExpiredTs = currentTimestamp + expirationTimeInSeconds;

    // ✅ FIXED: Use buildTokenWithUid instead of buildTokenWithAccount
    const token = RtcTokenBuilder.buildTokenWithUid(
      APP_ID,
      APP_CERTIFICATE,
      channelName,
      userUid,
      role,
      privilegeExpiredTs
    );

    console.log(`Token created for user: ${context.auth.uid}`);

    // Return the token to your app
    return {
      success: true,
      token: token,
      channelName: channelName,
      uid: userUid,
      appId: APP_ID
    };

  } catch (error) {
    console.error('Error creating token:', error);
    throw new functions.https.HttpsError('internal', 'Failed to create token');
  }
});

// Function 2: Send notification for incoming video calls
exports.sendVideoCallNotification = functions.https.onCall(async (data, context) => {
  // Check if user is logged in
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'You must be logged in');
  }

  const { targetUserId, callerName, channelId, agoraToken, uid } = data;

  try {
    // Get the patient's notification token from database
    const userDoc = await admin.firestore()
      .collection('users')
      .doc(targetUserId)
      .get();

    if (!userDoc.exists) {
      throw new functions.https.HttpsError('not-found', 'User not found');
    }

    const fcmToken = userDoc.data().fcmToken;
    if (!fcmToken) {
      throw new functions.https.HttpsError('not-found', 'User has no notification token');
    }

    // Create the notification message
    const message = {
      token: fcmToken,
      data: {
        type: 'video_call',
        caller_name: callerName,
        caller_id: context.auth.uid,
        channel_id: channelId,
        agora_token: agoraToken,
        uid: uid.toString(),
      },
      notification: {
        title: 'Incoming Video Call - FactoDoctor',
        body: `${callerName} is calling you`,
      },
    };

    // Send the notification
    await admin.messaging().send(message);
        
    console.log(`Notification sent to ${targetUserId}`);
    return { success: true };

  } catch (error) {
    console.error('Error sending notification:', error);
    throw new functions.https.HttpsError('internal', 'Failed to send notification');
  }
});