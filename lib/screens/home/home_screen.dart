import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/doctor_service.dart';
import '../../services/notification_service.dart';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('FactoDoctor'),
        actions: [
          Consumer<AuthService>(
            builder: (context, authService, _) {
              return Switch(
                value: authService.doctor?.isOnline ?? false,
                onChanged: (value) {
                  authService.updateOnlineStatus(value);
                },
              );
            },
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              final authService = Provider.of<AuthService>(context, listen: false);
              await authService.updateOnlineStatus(false);
              await authService.signOut();
              if (mounted) {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const LoginScreen()), // Added const
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
          
          final doctor = authService.doctor!; // Store reference for cleaner code
          
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Welcome Card - FIXED the substring issue
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundColor: Theme.of(context).primaryColor,
                          child: Text(
                            _getNameInitial(doctor.name), // SAFE method
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Welcome, ${_getDoctorName(doctor.name)}', // SAFE method
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                doctor.specialization.isEmpty ? 'General Medicine' : doctor.specialization,
                                style: TextStyle(
                                  color: Colors.grey[600],
                                ),
                              ),
                              // Show hospital if available (new field)
                              if (doctor.hospital.isNotEmpty) ...[
                                Text(
                                  doctor.hospital,
                                  style: TextStyle(
                                    color: Colors.grey[500],
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                              const SizedBox(height: 4),
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
                                    ),
                                  ),
                                  // Show rating if available (new field)
                                  if (doctor.rating > 0) ...[
                                    const SizedBox(width: 16),
                                    Icon(
                                      Icons.star,
                                      size: 12,
                                      color: Colors.orange,
                                    ),
                                    const SizedBox(width: 2),
                                    Text(
                                      doctor.rating.toStringAsFixed(1),
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
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
                
                const SizedBox(height: 20),
                
                // Today's Stats
                const Text(
                  'Today\'s Statistics',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                
                const SizedBox(height: 12),
                
                Consumer<DoctorService>(
                  builder: (context, doctorService, _) {
                    final stats = doctorService.getTodayStats();
                    final earnings = doctorService.earnings;
                    
                    return Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _StatCard(
                                title: 'Calls Today',
                                value: '${stats['totalCalls'] ?? 0}',
                                icon: Icons.phone,
                                color: Colors.blue,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _StatCard(
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
                              child: _StatCard(
                                title: 'Today Earnings',
                                value: '₹${earnings['today']?.toStringAsFixed(0) ?? '0'}',
                                icon: Icons.currency_rupee,
                                color: Colors.orange,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _StatCard(
                                title: 'Total Duration',
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
                
                const SizedBox(height: 20),
                
                // Incoming Calls Listener
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
                
                // Recent Calls
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
                    
                    final recentCalls = doctorService.callHistory.take(5).toList();
                    
                    if (recentCalls.isEmpty) {
                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
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
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }
                    
                    return Column(
                      children: recentCalls.map((call) => 
                        Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: _getStatusColor(call.status),
                              child: Icon(
                                _getStatusIcon(call.status),
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                            title: Text(call.patientName.isEmpty ? 'Unknown Patient' : call.patientName), // SAFE access
                            subtitle: Text(
                              '${call.status.toString().split('.').last.toUpperCase()} • ${_formatDateTime(call.createdAt)}',
                            ),
                            trailing: Text(
                              '₹${call.consultationFee.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                      ).toList(),
                    );
                  },
                ),
              ],
            ),
          );
        },
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

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}