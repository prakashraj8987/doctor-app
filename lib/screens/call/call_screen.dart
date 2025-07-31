import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/call_model.dart';
// import '../../services/call_service.dart'; // Uncomment when CallService is ready
import '../home/home_screen.dart';
import 'dart:async';

class CallScreen extends StatefulWidget {
  final CallModel call;

  const CallScreen({super.key, required this.call});

  @override
  _CallScreenState createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  Timer? _timer;
  int _duration = 0;
  bool _isMuted = false;
  bool _isSpeakerOn = false;
  bool _isCallActive = true;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_isCallActive) {
        setState(() {
          _duration++;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatDuration(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;
    
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    } else {
      return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    }
  }

  // Safe method to get patient name first letter
  String _getPatientInitial() {
    if (widget.call.patientName.isEmpty) {
      return 'P'; // Default to 'P' for Patient
    }
    return widget.call.patientName.substring(0, 1).toUpperCase();
  }

  // Safe method to get patient name
  String _getPatientName() {
    if (widget.call.patientName.isEmpty) {
      return 'Unknown Patient';
    }
    return widget.call.patientName;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black87,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 40),
              
              // Call status and duration
              Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          'Connected',
                          style: TextStyle(
                            color: Colors.green,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Call duration
                  Text(
                    _formatDuration(_duration),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w300,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 40),
              
              // Patient avatar
              Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.3),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: CircleAvatar(
                  radius: 80,
                  backgroundColor: Theme.of(context).primaryColor,
                  child: Text(
                    _getPatientInitial(),
                    style: const TextStyle(
                      fontSize: 60,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Patient name
              Text(
                _getPatientName(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 8),
              
              // Call type and fee
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    widget.call.type == CallType.video ? Icons.videocam : Icons.call,
                    color: Colors.white70,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    widget.call.type == CallType.video ? 'Video Call' : 'Voice Call',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 16,
                    ),
  ),
                  if (widget.call.consultationFee > 0) ...[
                    const SizedBox(width: 12),
                    const Text(
                      '•',
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '₹${widget.call.consultationFee.toStringAsFixed(0)}',
                      style: TextStyle(
                        color: Colors.green.shade300,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
              
              const Spacer(),
              
              // Control buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Mute button
                  _buildControlButton(
                    icon: _isMuted ? Icons.mic_off : Icons.mic,
                    label: 'Mute',
                    isActive: _isMuted,
                    activeColor: Colors.red,
                    onTap: () => _toggleMute(),
                  ),
                  
                  // End call button
                  _buildControlButton(
                    icon: Icons.call_end,
                    label: 'End Call',
                    isActive: false,
                    activeColor: Colors.red,
                    backgroundColor: Colors.red,
                    size: 70,
                    onTap: () => _endCall(),
                  ),
                  
                  // Speaker button
                  _buildControlButton(
                    icon: _isSpeakerOn ? Icons.volume_up : Icons.volume_down,
                    label: 'Speaker',
                    isActive: _isSpeakerOn,
                    activeColor: Colors.blue,
                    onTap: () => _toggleSpeaker(),
                  ),
                ],
              ),
              
              const SizedBox(height: 20),
              
              // Additional controls
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildSmallControlButton(
                    icon: Icons.chat,
                    label: 'Chat',
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Chat feature coming soon')),
                      );
                    },
                  ),
                  _buildSmallControlButton(
                    icon: Icons.note_add,
                    label: 'Notes',
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Notes feature coming soon')),
                      );
                    },
                  ),
                  _buildSmallControlButton(
                    icon: Icons.more_horiz,
                    label: 'More',
                    onTap: () {
                      _showMoreOptions();
                    },
                  ),
                ],
              ),
              
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required bool isActive,
    required Color activeColor,
    Color? backgroundColor,
    double size = 60,
    required VoidCallback onTap,
  }) {
    final buttonColor = backgroundColor ?? 
        (isActive ? activeColor.withOpacity(0.8) : Colors.white.withOpacity(0.2));
    
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: buttonColor,
              shape: BoxShape.circle,
              boxShadow: backgroundColor == Colors.red ? [
                BoxShadow(
                  color: Colors.red.withOpacity(0.4),
                  blurRadius: 15,
                  spreadRadius: 2,
                ),
              ] : null,
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: size == 70 ? 32 : 28,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSmallControlButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 45,
            height: 45,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: Colors.white70,
              size: 20,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white60,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  // Toggle mute functionality
  void _toggleMute() {
    setState(() {
      _isMuted = !_isMuted;
    });
    
    // TODO: Uncomment when CallService is ready
    // final callService = context.read<CallService>();
    // callService.toggleMute();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isMuted ? '🔇 Microphone muted' : '🎤 Microphone unmuted'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  // Toggle speaker functionality
  void _toggleSpeaker() {
    setState(() {
      _isSpeakerOn = !_isSpeakerOn;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isSpeakerOn ? '🔊 Speaker on' : '🔉 Speaker off'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  // End call functionality
  Future<void> _endCall() async {
    try {
      print('📞 Ending call: ${widget.call.id}');
      
      // Stop the timer
      setState(() {
        _isCallActive = false;
      });
      
      // TODO: Uncomment when CallService is ready
      // final callService = context.read<CallService>();
      // await callService.endCall();
      
      // Show call ended message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('📞 Call ended - Duration: ${_formatDuration(_duration)}'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Navigate back to home
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
          (route) => false,
        );
      }
      
    } catch (e) {
      print('❌ Error ending call: $e');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error ending call: $e'),
            backgroundColor: Colors.red,
          ),
        );
        
        // Still navigate back even if error
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
          (route) => false,
        );
      }
    }
  }

  // Show more options
  void _showMoreOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[600],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            const SizedBox(height: 20),
            
            const Text(
              'Call Options',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 20),
            
            ListTile(
              leading: const Icon(Icons.record_voice_over, color: Colors.white70),
              title: const Text('Record Call', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Call recording feature coming soon')),
                );
              },
            ),
            
            ListTile(
              leading: const Icon(Icons.file_present, color: Colors.white70),
              title: const Text('Share Files', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('File sharing feature coming soon')),
                );
              },
            ),
            
            ListTile(
              leading: const Icon(Icons.medical_services, color: Colors.white70),
              title: const Text('Create Prescription', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Prescription feature coming soon')),
                );
              },
            ),
            
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}