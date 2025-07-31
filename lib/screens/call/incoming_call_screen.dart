import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/call_model.dart';
// import '../../services/call_service.dart'; // Uncomment when CallService is ready
import 'call_screen.dart';

class IncomingCallScreen extends StatefulWidget {
  final CallModel call;

  const IncomingCallScreen({super.key, required this.call});

  @override
  _IncomingCallScreenState createState() => _IncomingCallScreenState();
}

class _IncomingCallScreenState extends State<IncomingCallScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
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

  // Get call type display
  String _getCallTypeDisplay() {
    switch (widget.call.type) {
      case CallType.video:
        return 'Video Consultation';
      case CallType.voice:
        return 'Voice Call';
      default:
        return 'Voice Call';
    }
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
              const SizedBox(height: 60),
              
              // Incoming call text
              const Text(
                'Incoming Call',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w300,
                ),
              ),
              
              const SizedBox(height: 40),
              
              // Patient avatar with animation
              AnimatedBuilder(
                animation: _scaleAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _scaleAnimation.value,
                    child: Container(
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
                  );
                },
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
              
              // Patient phone
              Text(
                widget.call.patientPhone.isEmpty ? '+0000000000' : widget.call.patientPhone,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 16,
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Call info
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      widget.call.type == CallType.video ? Icons.videocam : Icons.call,
                      color: Colors.white,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _getCallTypeDisplay(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Show consultation fee if available
              if (widget.call.consultationFee > 0) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    '₹${widget.call.consultationFee.toStringAsFixed(0)}',
                    style: TextStyle(
                      color: Colors.green.shade300,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
              
              const Spacer(),
              
              // Action buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Reject button
                  GestureDetector(
                    onTap: () => _rejectCall(),
                    child: Container(
                      width: 70,
                      height: 70,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.red,
                            blurRadius: 15,
                            spreadRadius: 2,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.call_end,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                  ),
                  
                  // Accept button
                  GestureDetector(
                    onTap: () => _acceptCall(),
                    child: Container(
                      width: 70,
                      height: 70,
                      decoration: const BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.green,
                            blurRadius: 15,
                            spreadRadius: 2,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.call,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 40),
              
              // Quick actions
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildQuickAction(
                    icon: Icons.message,
                    label: 'Message',
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Quick message feature coming soon')),
                      );
                    },
                  ),
                  _buildQuickAction(
                    icon: Icons.schedule,
                    label: 'Schedule',
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Schedule feature coming soon')),
                      );
                    },
                  ),
                ],
              ),
              
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickAction({
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
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white60,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  // Accept call handler
  Future<void> _acceptCall() async {
    print('📞 Accepting call: ${widget.call.id}');
    
    try {
      // TODO: Uncomment when CallService is ready
      // final callService = Provider.of<CallService>(context, listen: false);
      // await callService.acceptCall(widget.call.id);
      
      // Temporary success handling
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Call accepted! Connecting...'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Navigate to call screen
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => CallScreen(call: widget.call),
          ),
        );
      }
      
    } catch (e) {
      print('❌ Error accepting call: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Failed to accept call: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Reject call handler  
  Future<void> _rejectCall() async {
    print('❌ Rejecting call: ${widget.call.id}');
    
    try {
      // TODO: Uncomment when CallService is ready
      // final callService = Provider.of<CallService>(context, listen: false);
      // await callService.rejectCall(widget.call.id);
      
      // Temporary handling
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Call declined'),
            backgroundColor: Colors.red,
          ),
        );
        
        Navigator.of(context).pop();
      }
      
    } catch (e) {
      print('❌ Error rejecting call: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Failed to decline call: $e'),
            backgroundColor: Colors.red,
          ),
        );
        
        // Still go back even if error
        Navigator.of(context).pop();
      }
    }
  }
}