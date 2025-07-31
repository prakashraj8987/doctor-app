import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService extends ChangeNotifier {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  String? _fcmToken;
  bool _isInitialized = false;
  
  // Navigation callback for incoming calls
  Function(String callId, String patientName, String patientPhone)? _onIncomingCall;

  // Getters
  String? get fcmToken => _fcmToken;
  bool get isInitialized => _isInitialized;

  Future<void> initialize() async {
    try {
      print('🚀 Initializing NotificationService...');

      // Request permissions
      NotificationSettings settings = await _fcm.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      print('📱 Permission status: ${settings.authorizationStatus}');

      // Initialize local notifications with tap handler
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosSettings = DarwinInitializationSettings();
      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _localNotifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      // Get FCM token with enhanced visibility
      _fcmToken = await _fcm.getToken();
      
      // Make token SUPER visible in console
      _printTokenBigBox();

      // Setup message handlers
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
      FirebaseMessaging.onMessageOpenedApp.listen(_handleBackgroundMessage);
      
      // Handle app launch from terminated state
      FirebaseMessaging.instance.getInitialMessage().then((RemoteMessage? message) {
        if (message != null) {
          print('📱 App launched from notification');
          _handleMessageClick(message);
        }
      });
      
      // Listen for token refresh
      _fcm.onTokenRefresh.listen((String token) {
        _fcmToken = token;
        print('🔄 FCM Token refreshed');
        _printTokenBigBox();
        notifyListeners();
      });

      _isInitialized = true;
      notifyListeners();
      
      print('✅ NotificationService initialized successfully!');

    } catch (e) {
      print('❌ NotificationService initialization failed: $e');
    }
  }

  // Set callback for incoming call navigation
  void setIncomingCallCallback(Function(String callId, String patientName, String patientPhone) callback) {
    _onIncomingCall = callback;
    print('✅ Incoming call callback set');
  }

  // Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    print('🔔 Notification tapped: ${response.payload}');
    
    if (response.payload != null && _onIncomingCall != null) {
      // For demo, extract call ID and use sample data
      // In real app, you'd fetch call details from Firestore using callId
      String callId = response.payload!;
      _onIncomingCall!(callId, 'Test Patient', '+1234567890');
    }
  }

  // Make FCM token VERY visible in console
  void _printTokenBigBox() {
    if (_fcmToken == null) {
      print('❌ No FCM token available');
      return;
    }

    print('');
    print('🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥');
    print('🔥                                                          🔥');
    print('🔥                      FCM TOKEN READY!                    🔥');
    print('🔥                                                          🔥');
    print('🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥');
    print('');
    print('📋 COPY THIS TOKEN FOR TESTING:');
    print('');
    
    // Split token into readable chunks
    String token = _fcmToken!;
    for (int i = 0; i < token.length; i += 60) {
      int end = (i + 60 < token.length) ? i + 60 : token.length;
      print('   ${token.substring(i, end)}');
    }
    
    print('');
    print('📱 Token length: ${_fcmToken!.length} characters');
    print('🧪 Use this token in Firebase Console → Cloud Messaging');
    print('');
    print('🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥');
    print('');
  }

  // Method to manually print token (for debugging)
  void printToken() {
    _printTokenBigBox();
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    print('📨 Received foreground message: ${message.messageId}');
    print('📨 Title: ${message.notification?.title}');
    print('📨 Body: ${message.notification?.body}');
    print('📨 Data: ${message.data}');
    
    await _showLocalNotification(message);
  }

  Future<void> _handleBackgroundMessage(RemoteMessage message) async {
    print('📨 Received background message: ${message.messageId}');
    print('📨 User tapped notification from background');
    _handleMessageClick(message);
  }

  void _handleMessageClick(RemoteMessage message) {
    print('🔔 Handling message click');
    
    String callId = message.data['callId'] ?? 'unknown_call';
    String patientName = message.data['patientName'] ?? 'Unknown Patient';
    String patientPhone = message.data['patientPhone'] ?? '+0000000000';
    
    print('📞 Call details: $callId, $patientName, $patientPhone');
    
    if (_onIncomingCall != null) {
      _onIncomingCall!(callId, patientName, patientPhone);
    } else {
      print('⚠️ No incoming call callback set');
    }
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    try {
      String callId = message.data['callId'] ?? 'unknown_call';
      String patientName = message.data['patientName'] ?? message.notification?.body ?? 'Unknown Patient';

      const androidDetails = AndroidNotificationDetails(
        'calls_channel',
        'Call Notifications',
        channelDescription: 'Notifications for incoming calls',
        importance: Importance.high,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
        fullScreenIntent: true,
        category: AndroidNotificationCategory.call,
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _localNotifications.show(
        message.hashCode,
        message.notification?.title ?? 'Incoming Call',
        message.notification?.body ?? '$patientName is calling',
        details,
        payload: callId, // This will be passed to _onNotificationTapped
      );

      print('✅ Local notification displayed successfully');

    } catch (e) {
      print('❌ Error showing notification: $e');
    }
  }

  // Method to simulate incoming call for testing
  Future<void> simulateIncomingCall() async {
    print('🧪 Simulating incoming call...');
    
    const androidDetails = AndroidNotificationDetails(
      'calls_channel',
      'Call Notifications',
      channelDescription: 'Notifications for incoming calls',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      fullScreenIntent: true,
      category: AndroidNotificationCategory.call,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      'Incoming Call',
      'Test Patient is calling',
      details,
      payload: 'test_call_123',
    );
  }
}