class AttendanceLogModel {
  final String id;
  final String runInstanceId;
  final String workerId;
  final String workerName;
  final String attendanceType;
  final DateTime attendanceTime;
  final DateTime? scheduledDepartureTime;
  final DateTime? attendanceWindowOpen;
  final DateTime? attendanceDeadline;
  final bool isLate;
  final bool isNonCompliant;
  final String? selfieUrl;
  final double? latitude;
  final double? longitude;
  final String? deviceId;
  final String? mobileNumber;
  final String identityAuditStatus;

  AttendanceLogModel({
    required this.id,
    required this.runInstanceId,
    required this.janitorId,
    required this.janitorName,
    required this.attendanceType,
    required this.attendanceTime,
    this.scheduledDepartureTime,
    this.attendanceWindowOpen,
    this.attendanceDeadline,
    this.isLate = false,
    this.isNonCompliant = false,
    this.selfieUrl,
    this.latitude,
    this.longitude,
    this.deviceId,
    this.mobileNumber,
    this.identityAuditStatus = 'pending',
  });

  factory AttendanceLogModel.fromJson(Map<String, dynamic> json) {
    return AttendanceLogModel(
      id: json['id'] as String? ?? '',
      runInstanceId: json['runInstanceId'] as String? ?? '',
      janitorId: json['janitorId'] as String? ?? '',
      janitorName: json['janitorName'] as String? ?? '',
      attendanceType: json['attendanceType'] as String? ?? '',
      attendanceTime: json['attendanceTime'] != null
          ? DateTime.parse(json['attendanceTime'] as String)
          : DateTime.now(),
      scheduledDepartureTime: json['scheduledDepartureTime'] != null
          ? DateTime.tryParse(json['scheduledDepartureTime'] as String)
          : null,
      attendanceWindowOpen: json['attendanceWindowOpen'] != null
          ? DateTime.tryParse(json['attendanceWindowOpen'] as String)
          : null,
      attendanceDeadline: json['attendanceDeadline'] != null
          ? DateTime.tryParse(json['attendanceDeadline'] as String)
          : null,
      isLate: json['isLate'] as bool? ?? false,
      isNonCompliant: json['isNonCompliant'] as bool? ?? false,
      selfieUrl: json['selfieUrl'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      deviceId: json['deviceId'] as String?,
      mobileNumber: json['mobileNumber'] as String?,
      identityAuditStatus:
          json['identityAuditStatus'] as String? ?? 'pending',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'runInstanceId': runInstanceId,
      'workerId': workerId,
      'workerName': workerName,
      'attendanceType': attendanceType,
      'attendanceTime': attendanceTime.toIso8601String(),
      if (scheduledDepartureTime != null)
        'scheduledDepartureTime': scheduledDepartureTime!.toIso8601String(),
      if (attendanceWindowOpen != null)
        'attendanceWindowOpen': attendanceWindowOpen!.toIso8601String(),
      if (attendanceDeadline != null)
        'attendanceDeadline': attendanceDeadline!.toIso8601String(),
      'isLate': isLate,
      'isNonCompliant': isNonCompliant,
      if (selfieUrl != null) 'selfieUrl': selfieUrl,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (deviceId != null) 'deviceId': deviceId,
      if (mobileNumber != null) 'mobileNumber': mobileNumber,
      'identityAuditStatus': identityAuditStatus,
    };
  }

  AttendanceLogModel copyWith({
    String? id,
    String? runInstanceId,
    String? workerId,
    String? workerName,
    String? attendanceType,
    DateTime? attendanceTime,
    DateTime? scheduledDepartureTime,
    DateTime? attendanceWindowOpen,
    DateTime? attendanceDeadline,
    bool? isLate,
    bool? isNonCompliant,
    String? selfieUrl,
    double? latitude,
    double? longitude,
    String? deviceId,
    String? mobileNumber,
    String? identityAuditStatus,
  }) {
    return AttendanceLogModel(
      id: id ?? this.id,
      runInstanceId: runInstanceId ?? this.runInstanceId,
      janitorId: workerId ?? this.janitorId,
      janitorName: workerName ?? this.janitorName,
      attendanceType: attendanceType ?? this.attendanceType,
      attendanceTime: attendanceTime ?? this.attendanceTime,
      scheduledDepartureTime:
          scheduledDepartureTime ?? this.scheduledDepartureTime,
      attendanceWindowOpen:
          attendanceWindowOpen ?? this.attendanceWindowOpen,
      attendanceDeadline: attendanceDeadline ?? this.attendanceDeadline,
      isLate: isLate ?? this.isLate,
      isNonCompliant: isNonCompliant ?? this.isNonCompliant,
      selfieUrl: selfieUrl ?? this.selfieUrl,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      deviceId: deviceId ?? this.deviceId,
      mobileNumber: mobileNumber ?? this.mobileNumber,
      identityAuditStatus: identityAuditStatus ?? this.identityAuditStatus,
    );
  }
}
