class UserModel {
  final String uid;
  final String email;
  final String role;
  final String userType;
  final String fullName;
  final String? mobile;
  final String? designation;
  final String? zone;
  final String? division;
  final String? depot;
  final String? entityId;
  final Map<String, dynamic>? entityDetails;
  final String? status;
  final DateTime? createdAt;
  final DateTime? submittedAt;
  final DateTime? approvedAt;

  UserModel({
    required this.uid,
    required this.email,
    required this.role,
    required this.userType,
    required this.fullName,
    this.mobile,
    this.designation,
    this.zone,
    this.division,
    this.depot,
    this.entityId,
    this.entityDetails,
    this.status,
    this.createdAt,
    this.submittedAt,
    this.approvedAt,
  });

  factory UserModel.fromApiResponse(Map<String, dynamic> json) {
    final user = json['user'] is Map<String, dynamic> ? json['user'] : json;

    return UserModel(
      uid: user['uid'] ?? '',
      email: user['email'] ?? '',
      role: user['role'] ?? '',
      userType: user['userType'] ?? '',
      fullName: user['fullName'] ?? user['name'] ?? '',
      mobile: user['mobile']?.toString(),
      designation: user['designation'],
      zone: user['zone'],
      division: user['division'],
      depot: user['depot'],
      entityId: user['entityId'],
      entityDetails: user['entityDetails'] is Map<String, dynamic>
          ? user['entityDetails']
          : null,
      status: user['status'],
      createdAt: _parseTimestamp(user['createdAt']),
      submittedAt: _parseTimestamp(user['submitted_at']),
      approvedAt: _parseTimestamp(user['approved_at']),
    );
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      uid: json['uid'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? '',
      userType: json['userType'] ?? '',
      fullName: json['fullName'] ?? '',
      mobile: json['mobile'],
      designation: json['designation'],
      zone: json['zone'],
      division: json['division'],
      depot: json['depot'],
      entityId: json['entityId'],
      entityDetails: json['entityDetails'] is Map<String, dynamic>
          ? json['entityDetails']
          : null,
      status: json['status'],
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'])
          : null,
      submittedAt: json['submittedAt'] != null
          ? DateTime.tryParse(json['submittedAt'])
          : null,
      approvedAt: json['approvedAt'] != null
          ? DateTime.tryParse(json['approvedAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'email': email,
      'role': role,
      'userType': userType,
      'fullName': fullName,
      'mobile': mobile,
      'designation': designation,
      'zone': zone,
      'division': division,
      'depot': depot,
      'entityId': entityId,
      'entityDetails': entityDetails,
      'status': status,
      'createdAt': createdAt?.toIso8601String(),
      'submittedAt': submittedAt?.toIso8601String(),
      'approvedAt': approvedAt?.toIso8601String(),
    };
  }

  static DateTime? _parseTimestamp(dynamic ts) {
    if (ts == null) return null;
    if (ts is Map && ts.containsKey('_seconds')) {
      return DateTime.fromMillisecondsSinceEpoch(ts['_seconds'] * 1000);
    }
    return null;
  }
}