import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';  // ← ADDED THIS LINE
import '../../services/auth_service.dart';
import '../../services/doctor_service.dart';
import '../../services/notification_service.dart';
import '../../services/agora_service.dart';  // ← ALREADY THERE
import '../../models/call_model.dart';
import '../call/incoming_call_screen.dart';
import '../auth/login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    _initializeServices();
    
    // Set up notification callback AFTER build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final notificationService = context.read<NotificationService>();
      notificationService.setIncomingCallCallback(_handleNotificationCall);
    });
  }

  Future<void> _initializeServices() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final doctorService = Provider.of<DoctorService>(context, listen: false);
    final notificationService = Provider.of<NotificationService>(context, listen: false);
    
    if (authService.doctor != null) {
      await doctorService.loadCallHistory(authService.doctor!.id);
      await notificationService.initialize();
      
      // Set doctor as online
      await authService.updateOnlineStatus(true);
    }
  }

  // Handle notification-based incoming calls
  void _handleNotificationCall(String callId, String patientName, String patientPhone) {
    print('🔔 Navigating to incoming call screen from notification');
    
    // Create a temporary CallModel from notification data
    final tempCall = CallModel(
      id: callId,
      patientId: 'temp_patient_id',
      patientName: patientName,
      patientPhone: patientPhone,
      doctorId: context.read<AuthService>().doctor?.id ?? 'unknown',
      status: CallStatus.ringing,
      type: CallType.video, // Changed to video
      createdAt: DateTime.now(),
      durationSeconds: 0,
      consultationFee: context.read<AuthService>().doctor?.consultationFee ?? 500.0,
      isPaid: false,
    );
    
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => IncomingCallScreen(call: tempCall),
      ),
    );
  }

  // Safe method to get first letter of name
  String _getNameInitial(String? name) {
    if (name == null || name.isEmpty) {
      return 'D'; // Default to 'D' for Doctor
    }
    return name.substring(0, 1).toUpperCase();
  }

  // Safe method to get doctor name
  String _getDoctorName(String? name) {
    if (name == null || name.isEmpty) {
      return 'Doctor'; // Default name
    }
    return name;
  }

  // ← UPDATED THIS FUNCTION WITH AUTHENTICATION CHECK
  Future<void> _testVideoCall() async {
    try {
      // Check if user is logged in first
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Please log in first to test video calls'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      print('🧪 Testing video call backend for user: ${user.email}');
      
      // Test: Generate Agora token (now with authenticated user)
      final tokenData = await AgoraService.generateToken(
        channelName: 'test-channel-123',
        uid: 12345,
      );
      
      print('✅ Token generated: ${tokenData['token']}');
      print('✅ App ID: ${tokenData['appId']}');
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Video call backend is working perfectly!\nToken: ${tokenData['token']?.substring(0, 20)}...'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 4),
        ),
      );
      
    } catch (e) {
      print('❌ Error testing backend: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Backend test failed: $e'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 4),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'FactoDoctor',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          // Online/Offline Toggle with better styling
          Consumer<AuthService>(
            builder: (context, authService, _) {
              return Container(
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(width: 12),
                    Icon(
                      Icons.circle,
                      size: 8,
                      color: authService.doctor?.isOnline == true 
                          ? Colors.green 
                          : Colors.grey,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      authService.doctor?.isOnline == true ? 'Online' : 'Offline',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Switch(
                      value: authService.doctor?.isOnline ?? false,
                      onChanged: (value) {
                        authService.updateOnlineStatus(value);
                      },
                      activeColor: Colors.green,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    const SizedBox(width: 4),
                  ],
                ),
              );
            },
          ),
          
          // Logout Button
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              final authService = Provider.of<AuthService>(context, listen: false);
              await authService.updateOnlineStatus(false);
              await authService.signOut();
              if (mounted) {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              }
            },
          ),
        ],
      ),
      body: Consumer<AuthService>(
        builder: (context, authService, _) {
          if (authService.doctor == null) {
            return const Center(child: CircularProgressIndicator());
          }
          
          final doctor = authService.doctor!;
          
          return RefreshIndicator(
            onRefresh: () async {
              await _initializeServices();
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Enhanced Welcome Card
                  Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: LinearGradient(
                          colors: [Colors.blue[50]!, Colors.white],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Row(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.blue.withOpacity(0.3),
                                    blurRadius: 10,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: CircleAvatar(
                                radius: 35,
                                backgroundColor: Colors.blue[600],
                                child: Text(
                                  _getNameInitial(doctor.name),
                                  style: const TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Welcome back!',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[600],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _getDoctorName(doctor.name),
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    doctor.specialization.isEmpty ? 'General Medicine' : doctor.specialization,
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  if (doctor.hospital.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.location_on,
                                          size: 14,
                                          color: Colors.grey[500],
                                        ),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            doctor.hospital,
                                            style: TextStyle(
                                              color: Colors.grey[500],
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.circle,
                                        size: 12,
                                        color: doctor.isOnline 
                                            ? Colors.green 
                                            : Colors.grey,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        doctor.isOnline ? 'Online' : 'Offline',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: doctor.isOnline 
                                              ? Colors.green 
                                              : Colors.grey,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      if (doctor.rating > 0) ...[
                                        const SizedBox(width: 16),
                                        ...List.generate(5, (index) {
                                          return Icon(
                                            index < doctor.rating.floor()
                                                ? Icons.star
                                                : (index < doctor.rating
                                                    ? Icons.star_half
                                                    : Icons.star_border),
                                            size: 14,
                                            color: Colors.amber,
                                          );
                                        }),
                                        const SizedBox(width: 4),
                                        Text(
                                          doctor.rating.toStringAsFixed(1),
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.amber,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Today's Stats Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Today\'s Statistics',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('📊 Detailed analytics coming soon')),
                          );
                        },
                        icon: const Icon(Icons.analytics, size: 16),
                        label: const Text('View All'),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Enhanced Statistics Cards
                  Consumer<DoctorService>(
                    builder: (context, doctorService, _) {
                      final stats = doctorService.getTodayStats();
                      final earnings = doctorService.earnings;
                      
                      return Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: _EnhancedStatCard(
                                  title: 'Calls Today',
                                  value: '${stats['totalCalls'] ?? 0}',
                                  icon: Icons.phone,
                                  color: Colors.blue,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _EnhancedStatCard(
                                  title: 'Completed',
                                  value: '${stats['completedCalls'] ?? 0}',
                                  icon: Icons.check_circle,
                                  color: Colors.green,
                                ),
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: 12),
                          
                          Row(
                            children: [
                              Expanded(
                                child: _EnhancedStatCard(
                                  title: 'Today Earnings',
                                  value: '₹${earnings['today']?.toStringAsFixed(0) ?? '0'}',
                                  icon: Icons.currency_rupee,
                                  color: Colors.orange,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _EnhancedStatCard(
                                  title: 'Avg Duration',
                                  value: '${((stats['totalDuration'] ?? 0) / 60).toStringAsFixed(0)} min',
                                  icon: Icons.timer,
                                  color: Colors.purple,
                                ),
                              ),
                            ],
                          ),
                        ],
                      );
                    },
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Quick Actions Section
                  const Text(
                    'Quick Actions',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  
                  const SizedBox(height: 12),
                  
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.blue[50],
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(Icons.history, color: Colors.blue[600], size: 22),
                          ),
                          title: const Text('Call History'),
                          subtitle: const Text('View your consultation history'),
                          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('📞 Call history screen coming soon')),
                            );
                          },
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.green[50],
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(Icons.analytics, color: Colors.green[600], size: 22),
                          ),
                          title: const Text('Earnings Report'),
                          subtitle: const Text('View detailed earnings'),
                          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('💰 Earnings report coming soon')),
                            );
                          },
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.purple[50],
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(Icons.person, color: Colors.purple[600], size: 22),
                          ),
                          title: const Text('Profile Settings'),
                          subtitle: const Text('Update your profile'),
                          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('👤 Profile settings coming soon')),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Hidden Incoming Calls Listener
                  StreamBuilder<List<CallModel>>(
                    stream: Provider.of<DoctorService>(context, listen: false)
                        .getIncomingCallsStream(doctor.id),
                    builder: (context, snapshot) {
                      if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                        final call = snapshot.data!.first;
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => IncomingCallScreen(call: call),
                            ),
                          );
                        });
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                  
                  // Recent Calls Section
                  const Text(
                    'Recent Calls',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  
                  const SizedBox(height: 12),
                  
                  Consumer<DoctorService>(
                    builder: (context, doctorService, _) {
                      if (doctorService.isLoading) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      
                      final recentCalls = doctorService.callHistory.take(3).toList();
                      
                      if (recentCalls.isEmpty) {
                        return Card(
                          elevation: 1,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(40),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.phone_disabled,
                                  size: 48,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No calls yet',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Your recent consultations will appear here',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[500],
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        );
                      }
                      
                      return Column(
                        children: [
                          ...recentCalls.map((call) => 
                            Card(
                              elevation: 1,
                              margin: const EdgeInsets.only(bottom: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: _getStatusColor(call.status),
                                  child: Icon(
                                    _getStatusIcon(call.status),
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                ),
                                title: Text(
                                  call.patientName.isEmpty ? 'Unknown Patient' : call.patientName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                subtitle: Text(
                                  '${call.status.toString().split('.').last.toUpperCase()} • ${_formatDateTime(call.createdAt)} • ${call.durationSeconds > 0 ? "${(call.durationSeconds / 60).toStringAsFixed(0)} min" : "0 min"}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                trailing: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      '₹${call.consultationFee.toStringAsFixed(0)}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Icon(
                                      call.type == CallType.video ? Icons.videocam : Icons.call,
                                      size: 14,
                                      color: Colors.grey[500],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ).toList(),
                          
                          if (doctorService.callHistory.length > 3)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: TextButton(
                                onPressed: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('📞 View all calls coming soon')),
                                  );
                                },
                                child: const Text('View All Calls'),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                  
                  // Bottom spacing
                  const SizedBox(height: 100),
                ],
              ),
            ),
          );
        },
      ),
      
      // ← ALREADY THERE - FLOATING ACTION BUTTON
      floatingActionButton: FloatingActionButton(
        onPressed: _testVideoCall,
        backgroundColor: Colors.blue[600],
        child: Icon(Icons.videocam, color: Colors.white),
        tooltip: 'Test Video Call Backend',
      ),
    );
  }

  Color _getStatusColor(CallStatus status) {
    switch (status) {
      case CallStatus.completed:
        return Colors.green;
      case CallStatus.rejected:
        return Colors.red;
      case CallStatus.ongoing:
        return Colors.blue;
      case CallStatus.cancelled:
        return Colors.orange;
      case CallStatus.noAnswer:
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(CallStatus status) {
    switch (status) {
      case CallStatus.completed:
        return Icons.check;
      case CallStatus.rejected:
        return Icons.close;
      case CallStatus.ongoing:
        return Icons.phone;
      case CallStatus.cancelled:
        return Icons.cancel;
      case CallStatus.noAnswer:
        return Icons.phone_missed;
      default:
        return Icons.phone_disabled;
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}

// Enhanced Stat Card Widget
class _EnhancedStatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _EnhancedStatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [color.withOpacity(0.1), Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: color, size: 24),
                  ),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}