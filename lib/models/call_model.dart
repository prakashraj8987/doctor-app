enum CallStatus {
  waiting,
  ringing,
  ongoing,
  completed,
  rejected,
  cancelled,
  noAnswer
}

enum CallType {
  voice,
  video
}

class CallModel {
  final String id;
  final String patientId;
  final String patientName;
  final String patientPhone;
  final String doctorId;
  final CallStatus status;
  final CallType type;
  final DateTime createdAt;
  final DateTime? startedAt;
  final DateTime? endedAt;
  final int durationSeconds;
  final String? agoraChannelId;
  final String? agoraToken;
  final double consultationFee;
  final bool isPaid;
  final String? notes;

  CallModel({
    required this.id,
    required this.patientId,
    required this.patientName,
    required this.patientPhone,
    required this.doctorId,
    required this.status,
    this.type = CallType.voice,
    required this.createdAt,
    this.startedAt,
    this.endedAt,
    this.durationSeconds = 0,
    this.agoraChannelId,
    this.agoraToken,
    required this.consultationFee,
    this.isPaid = false,
    this.notes,
  });

  factory CallModel.fromMap(Map<String, dynamic> map, String id) {
    return CallModel(
      id: id,
      patientId: map['patientId'] ?? '',
      patientName: map['patientName'] ?? '',
      patientPhone: map['patientPhone'] ?? '',
      doctorId: map['doctorId'] ?? '',
      status: CallStatus.values.firstWhere(
        (e) => e.toString().split('.').last == (map['status'] ?? 'waiting'),
        orElse: () => CallStatus.waiting,
      ),
      type: CallType.values.firstWhere(
        (e) => e.toString().split('.').last == (map['type'] ?? 'voice'),
        orElse: () => CallType.voice,
      ),
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] ?? 0),
      startedAt: map['startedAt'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(map['startedAt'])
          : null,
      endedAt: map['endedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['endedAt'])
          : null,
      durationSeconds: map['durationSeconds'] ?? 0,
      agoraChannelId: map['agoraChannelId'],
      agoraToken: map['agoraToken'],
      consultationFee: (map['consultationFee'] ?? 0).toDouble(),
      isPaid: map['isPaid'] ?? false,
      notes: map['notes'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'patientId': patientId,
      'patientName': patientName,
      'patientPhone': patientPhone,
      'doctorId': doctorId,
      'status': status.toString().split('.').last,
      'type': type.toString().split('.').last,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'startedAt': startedAt?.millisecondsSinceEpoch,
      'endedAt': endedAt?.millisecondsSinceEpoch,
      'durationSeconds': durationSeconds,
      'agoraChannelId': agoraChannelId,
      'agoraToken': agoraToken,
      'consultationFee': consultationFee,
      'isPaid': isPaid,
      'notes': notes,
    };
  }

  String get durationFormatted {
    final hours = durationSeconds ~/ 3600;
    final minutes = (durationSeconds % 3600) ~/ 60;
    final seconds = durationSeconds % 60;
    
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    } else {
      return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
  }

  double? get earnings => isPaid ? consultationFee : null;
}