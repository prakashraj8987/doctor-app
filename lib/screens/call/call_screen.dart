import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/call_model.dart';
import '../../services/call_service.dart';
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

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _duration++;
      });
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
              
              // Call duration
              Text(
                _formatDuration(_duration),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w300,
                ),
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
                    widget.call.patientName.substring(0, 1).toUpperCase(),
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
                widget.call.patientName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 8),
              
              // Status
              Text(
                'In Call',
                style: TextStyle(
                  color: Colors.green.shade300,
                  fontSize: 16,
                ),
              ),
              
              const Spacer(),
              
              // Control buttons
              Consumer<CallService>(
                builder: (context, callService, _) {
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Mute button
                      GestureDetector(
                        onTap: callService.toggleMute,
                        child: Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: callService.isMuted 
                                ? Colors.red.withOpacity(0.8) 
                                : Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            callService.isMuted ? Icons.mic_off : Icons.mic,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                      ),
                      
                      // End call button
                      GestureDetector(
                        onTap: () async {
                          await callService.endCall();
                          if (mounted) {
                            Navigator.of(context).pushAndRemoveUntil(
                              MaterialPageRoute(builder: (_) => HomeScreen()),
                              (route) => false,
                            );
                          }
                        },
                        child: Container(
                          width: 70,
                          height: 70,
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.call_end,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                      ),
                      
                      // Speaker button
                      GestureDetector(
                        onTap: () {
                          // Toggle speaker functionality
                        },
                        child: Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.volume_up,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
              
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}