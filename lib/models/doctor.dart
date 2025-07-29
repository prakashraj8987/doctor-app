class Doctor {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String specialization;
  final String hospital;
  final double consultationFee;
  final bool isOnline;
  final bool isActive;
  final String? profileImage;
  final double rating;
  final int totalConsultations;
  final DateTime createdAt;
  final DateTime updatedAt;

  Doctor({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.specialization,
    required this.hospital,
    required this.consultationFee,
    this.isOnline = false,
    this.isActive = true,
    this.profileImage,
    this.rating = 0.0,
    this.totalConsultations = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Doctor.fromMap(Map<String, dynamic> map, String id) {
    return Doctor(
      id: id,
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      specialization: map['specialization'] ?? '',
      hospital: map['hospital'] ?? '',
      consultationFee: (map['consultationFee'] ?? 0).toDouble(),
      isOnline: map['isOnline'] ?? false,
      isActive: map['isActive'] ?? true,
      profileImage: map['profileImage'],
      rating: (map['rating'] ?? 0).toDouble(),
      totalConsultations: map['totalConsultations'] ?? 0,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] ?? 0),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updatedAt'] ?? 0),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
      'specialization': specialization,
      'hospital': hospital,
      'consultationFee': consultationFee,
      'isOnline': isOnline,
      'isActive': isActive,
      'profileImage': profileImage,
      'rating': rating,
      'totalConsultations': totalConsultations,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
    };
  }

  Doctor copyWith({
    String? name,
    String? email,
    String? phone,
    String? specialization,
    String? hospital,
    double? consultationFee,
    bool? isOnline,
    bool? isActive,
    String? profileImage,
    double? rating,
    int? totalConsultations,
    DateTime? updatedAt,
  }) {
    return Doctor(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      specialization: specialization ?? this.specialization,
      hospital: hospital ?? this.hospital,
      consultationFee: consultationFee ?? this.consultationFee,
      isOnline: isOnline ?? this.isOnline,
      isActive: isActive ?? this.isActive,
      profileImage: profileImage ?? this.profileImage,
      rating: rating ?? this.rating,
      totalConsultations: totalConsultations ?? this.totalConsultations,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }
}